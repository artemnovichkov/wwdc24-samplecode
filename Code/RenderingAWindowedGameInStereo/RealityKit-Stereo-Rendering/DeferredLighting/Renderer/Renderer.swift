/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Renderer class which performs Metal setup and per frame rendering shared between platforms.
*/

import simd
import ModelIO
import MetalKit

// MARK: - Renderer
class Renderer: NSObject {
    
    lazy var shadowRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.depthAttachment.texture = scene.shadowMap
        descriptor.depthAttachment.storeAction = .store
        return descriptor
    }()
    
    // The semaphore used to control GPU-CPU synchronization of frames.
//    private let inFlightSemaphore: DispatchSemaphore
    
    private let commandQueue: MTLCommandQueue
    
    // Called at the start of every frame.
    private let didBeginFrame: () -> Void
    
    // sets the GBuffer textures when there is a re-size.
    let setGBufferTextures: (MTLRenderPassDescriptor) -> Void
    
    // If provided, this will be called at the end of every frame, and should return a drawable that will be presented.
    var getCurrentDrawable: (() -> CAMetalDrawable?)?
    
    // If provided, this will be called whenever the drawable size changes.
    var drawableSizeWillChange: ((MTLDevice, CGSize, MTLStorageMode) -> Void)?
    
    var scene: Scene
    
    var pipelineStates: PipelineStates
    var depthStencilStates: DepthStencilStates
    
    let device: MTLDevice
    
    // MARK: - Init
    init(device: MTLDevice,
         scene: Scene,
         renderDestination: RenderDestination,
         singlePass: Bool,
         commandQueue: MTLCommandQueue,
         didBeginFrame: @escaping () -> Void) {
        
        self.device = device
        
        self.scene = scene
        
        // Create all of the MTLRenderPipelineState that the renderer will use.
        pipelineStates = PipelineStates(device: device, renderDestination: renderDestination,
            singlePass: singlePass)
        
        // Create all of the MTLDepthStencilState that the renderer will use.
        depthStencilStates = DepthStencilStates(device: device)
                
        print("Selected Device: \(device.name)")
        
//        inFlightSemaphore = DispatchSemaphore(value: maxFramesInFlight)
                
//        guard let commandQueue = device.makeCommandQueue() else {
//            fatalError("Failed to make command queue.")
//        }
        self.commandQueue = commandQueue
        
        self.didBeginFrame = didBeginFrame
        
        self.setGBufferTextures = scene.setGBufferTextures

        super.init()
    }
    
    /// Perform operations necessary at the beginning of the frame.  Wait on the in flight semaphore,
    /// and get a command buffer to encode intial commands for this frame.
    func beginFrame() -> MTLCommandBuffer {
        // Wait to ensure only maxFramesInFlight are getting processed by any stage in the Metal
        //   pipeline (App, Metal, Drivers, GPU, etc)
//        inFlightSemaphore.wait()
        
        // Create a new command buffer for each render pass to the current drawable
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("Failed to create a command new command buffer.")
        }
        
        didBeginFrame()
        
        return commandBuffer
    }
    
    /// Perform operations necessary to obtain a command buffer for rendering to the drawable.  By
    /// endoding commands that are not dependant on the drawable in a separate command buffer, Metal
    /// can begin executing encoded commands for the frame (commands from the previous command buffer)
    /// before a drawable for this frame becomes avaliable.
    func beginDrawableCommands() -> MTLCommandBuffer {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("Failed to make command buffer from command queue")
        }
        
        // Add completion hander which signals inFlightSemaphore
        // when Metal and the GPU has fully finished processing the commands encoded for this frame.
        // This indicates when the dynamic buffers, written this frame, will no longer be needed by Metal and the GPU.
//        commandBuffer.addCompletedHandler { [weak self] _ in
//            self?.inFlightSemaphore.signal()
//        }
        
        return commandBuffer
    }
    
    /// Perform cleanup operations including presenting the drawable and committing the command buffer
    /// for the current frame.  Also, when enabled, draw buffer examination elements before all this.
    func endFrame(_ commandBuffer: MTLCommandBuffer) {
        // Schedule a present once the framebuffer is complete using the current drawable
        
        if let drawable = getCurrentDrawable?() {
            commandBuffer.present(drawable)
        }
        
        // Finalize rendering here & push the command buffer to the GPU
        commandBuffer.commit()
    }
    
    func encodePass(into commandBuffer: MTLCommandBuffer,
                    using descriptor: MTLRenderPassDescriptor,
                    label: String,
                    _ encodingBlock: (MTLRenderCommandEncoder) -> Void) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            fatalError("Failed to make render command encoder with: \(descriptor.description)")
        }
        renderEncoder.label = label
        encodingBlock(renderEncoder)
        renderEncoder.endEncoding()
    }
    
    func encodeStage(using renderEncoder: MTLRenderCommandEncoder,
                     label: String,
                     _ encodingBlock: () -> Void) {
        renderEncoder.pushDebugGroup(label)
        encodingBlock()
        renderEncoder.popDebugGroup()
    }
    
    func encodeGBufferStage(using renderEncoder: MTLRenderCommandEncoder) {
        encodeStage(using: renderEncoder, label: "GBuffer Generation Stage") {
            renderEncoder.setRenderPipelineState(pipelineStates.gBufferGeneration)
            renderEncoder.setDepthStencilState(depthStencilStates.gBufferGeneration)
            renderEncoder.setCullMode(.back)
            renderEncoder.setStencilReferenceValue(128)
            renderEncoder.setVertexBuffer(scene.frameData, offset: 0, index: Int(AAPLBufferFrameData.rawValue))
            renderEncoder.setFragmentBuffer(scene.frameData, offset: 0, index: Int(AAPLBufferFrameData.rawValue))
            renderEncoder.setFragmentTexture(scene.shadowMap, index: Int(AAPLTextureIndexShadow.rawValue))
            
            renderEncoder.draw(meshes: scene.meshes)
        }
    }
    
    func encodeDirectionalLightingStage(using renderEncoder: MTLRenderCommandEncoder) {
        encodeStage(using: renderEncoder, label: "Directional Lighting Stage") {
            renderEncoder.setRenderPipelineState(pipelineStates.directionalLighting)
            renderEncoder.setDepthStencilState(depthStencilStates.directionalLighting)
            if !GBufferTextures.attachedInFinalPass {
                scene.setGBufferTextures(renderEncoder: renderEncoder)
            }
            renderEncoder.setCullMode(.back)
            renderEncoder.setStencilReferenceValue(128)
            
            renderEncoder.setVertexBuffer(scene.quadVertexBuffer,
                                          offset: 0,
                                          index: Int(AAPLBufferIndexMeshPositions.rawValue))
            
            renderEncoder.setVertexBuffer(scene.frameData,
                                          offset: 0,
                                          index: Int(AAPLBufferFrameData.rawValue))
            
            renderEncoder.setFragmentBuffer(scene.frameData,
                                            offset: 0,
                                            index: Int(AAPLBufferFrameData.rawValue))
            
            // Draw full screen quad
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
    }
    
    func encodeLightMaskStage(using renderEncoder: MTLRenderCommandEncoder) {
        if let lightMaskPipelineState = pipelineStates.lightMask,
            let lightMaskDepthStencilState = depthStencilStates.lightMask {
            encodeStage(using: renderEncoder, label: "Point Light Mask Stage") {
                
                renderEncoder.setRenderPipelineState(lightMaskPipelineState)
                renderEncoder.setDepthStencilState(lightMaskDepthStencilState)
                
                renderEncoder.setStencilReferenceValue(128)
                renderEncoder.setCullMode(.front)
                
                renderEncoder.setVertexBuffer(scene.frameData,
                                              offset: 0,
                                              index: Int(AAPLBufferFrameData.rawValue))
                
                renderEncoder.setVertexBuffer(scene.pointLights,
                                              offset: 0,
                                              index: Int(AAPLBufferIndexLightsData.rawValue))
                
                renderEncoder.setVertexBuffer(scene.lightPositions,
                                              offset: 0,
                                              index: Int(AAPLBufferIndexLightsPosition.rawValue))
                
                renderEncoder.setFragmentBuffer(scene.frameData,
                                                offset: 0,
                                                index: Int(AAPLBufferFrameData.rawValue))
                
                renderEncoder.draw(meshes: [scene.icosahedron],
                                   instanceCount: scene.numberOfLights,
                                   requiresMaterials: false)
            }
        }
    }
    
    func encodePointLightStage(using renderEncoder: MTLRenderCommandEncoder) {
        encodeStage(using: renderEncoder, label: "Point Light Stage") {
            
            renderEncoder.setRenderPipelineState(pipelineStates.pointLighting)
            renderEncoder.setDepthStencilState(depthStencilStates.pointLighting)
            
            if !device.supportsFamily(.apple1) {
                scene.setGBufferTextures(renderEncoder: renderEncoder)
            }
            
            renderEncoder.setStencilReferenceValue(128)
            renderEncoder.setCullMode(.back)
            
            renderEncoder.setVertexBuffer(scene.frameData,
                                          offset: 0,
                                          index: Int(AAPLBufferFrameData.rawValue))
            
            renderEncoder.setVertexBuffer(scene.pointLights,
                                          offset: 0,
                                          index: Int(AAPLBufferIndexLightsData.rawValue))
            
            renderEncoder.setVertexBuffer(scene.lightPositions,
                                          offset: 0,
                                          index: Int(AAPLBufferIndexLightsPosition.rawValue))
            
            renderEncoder.setFragmentBuffer(scene.frameData,
                                            offset: 0,
                                            index: Int(AAPLBufferFrameData.rawValue))
            
            renderEncoder.setFragmentBuffer(scene.pointLights,
                                            offset: 0,
                                            index: Int(AAPLBufferIndexLightsData.rawValue))
            
            renderEncoder.setFragmentBuffer(scene.lightPositions,
                                            offset: 0,
                                            index: Int(AAPLBufferIndexLightsPosition.rawValue))
            
            renderEncoder.draw(meshes: [scene.icosahedron],
                               instanceCount: scene.numberOfLights,
                               requiresMaterials: false)
        }
    }
    
    func encodeSkyboxStage(using renderEncoder: MTLRenderCommandEncoder) {
        encodeStage(using: renderEncoder, label: "Skybox Stage") {
            
            renderEncoder.setRenderPipelineState(pipelineStates.skybox)
            renderEncoder.setDepthStencilState(depthStencilStates.skybox)
            
            renderEncoder.setCullMode(.front)
            
            renderEncoder.setVertexBuffer(scene.frameData, offset: 0, index: Int(AAPLBufferFrameData.rawValue))
            renderEncoder.setFragmentTexture(scene.skyMap, index: Int(AAPLTextureIndexBaseColor.rawValue))
            
            renderEncoder.draw(meshes: [scene.skyMesh],
                               requiresMaterials: false)
        }
    }
    
    func encodeFairyBillboardStage(using renderEncoder: MTLRenderCommandEncoder) {
        encodeStage(using: renderEncoder, label: "Fairy Lights Stage") {
            renderEncoder.setRenderPipelineState(pipelineStates.fairyLighting)
            renderEncoder.setDepthStencilState(depthStencilStates.fairyLighting)
            renderEncoder.setCullMode(.back)
            
            renderEncoder.setVertexBuffer(scene.frameData,
                                          offset: 0,
                                          index: Int(AAPLBufferFrameData.rawValue))
            
            renderEncoder.setVertexBuffer(scene.fairy,
                                          offset: 0,
                                          index: Int(AAPLBufferIndexMeshPositions.rawValue))
            
            renderEncoder.setVertexBuffer(scene.pointLights,
                                          offset: 0,
                                          index: Int(AAPLBufferIndexLightsData.rawValue))
            
            renderEncoder.setVertexBuffer(scene.lightPositions,
                                          offset: 0,
                                          index: Int(AAPLBufferIndexLightsPosition.rawValue))
            
            renderEncoder.setFragmentTexture(scene.fairyMap,
                                             index: Int(AAPLTextureIndexAlpha.rawValue))
            
            renderEncoder.drawPrimitives(type: .triangleStrip,
                                         vertexStart: 0,
                                         vertexCount: scene.fairyVerticesCount,
                                         instanceCount: scene.numberOfLights)
        }
    }
    
    func encodeShadowMapPass(into commandBuffer: MTLCommandBuffer) {
        encodePass(into: commandBuffer,
                   using: shadowRenderPassDescriptor,
                   label: "Shadow Map Pass") { renderEncoder in
                    
                    encodeStage(using: renderEncoder, label: "Shadow Generation Stage") {
                        renderEncoder.setRenderPipelineState(pipelineStates.shadowGeneration)
                        renderEncoder.setDepthStencilState(depthStencilStates.shadowGeneration)
                        renderEncoder.setCullMode(.back)
                        renderEncoder.setDepthBias(0.015, slopeScale: 7, clamp: 0.02)
                        renderEncoder.setVertexBuffer(scene.frameData, offset: 0, index: Int(AAPLBufferFrameData.rawValue))
                        
                        // The Shadow Command does not need mesh materials.
                        renderEncoder.draw(meshes: scene.meshes, requiresMaterials: false)
                    }
        }
    }
    
}

// MARK: - MTKViewDelegate
#if !os(visionOS)

extension Renderer: MTKViewDelegate {

    /// MTKViewDelegate Callback: Respond to device orientation change or other view size change
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
    }
}

#endif

@objc protocol DrawableProviding {
    var viewCount: Int { get }
    func viewMatrix(viewIndex: Int) -> simd_float4x4
    func projectionMatrix(viewIndex: Int) -> simd_float4x4

    func colorTexture(viewIndex: Int, for commandBuffer: MTLCommandBuffer) -> MTLTexture?
    func depthStencilTexture(viewIndex: Int, for commandBuffer: MTLCommandBuffer) -> MTLTexture?
    func rasterizationRateMap(viewIndex: Int) -> MTLRasterizationRateMap?
}

#if !os(visionOS)

extension MTKView: DrawableProviding {
    func rasterizationRateMap(viewIndex: Int) -> MTLRasterizationRateMap? {
        return nil
    }
    func colorTexture(viewIndex: Int, for commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        return self.currentDrawable?.texture
    }
    func depthStencilTexture(viewIndex: Int, for commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        return self.depthStencilTexture
    }
}

#endif

extension Renderer {
    @objc
    func draw(provider: DrawableProviding) {}
    @objc
    func drawableSizeWillChange(size: CGSize) {}
}
