/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main renderer.
*/

import CompositorServices
import Metal
import MetalKit
import simd
import Spatial

extension MemoryLayout {
    static var uniformStride: Int {
        // The 256 byte aligned size of the uniform structure.
        (size + 0xFF) & -0x100
    }
}

extension LayerRenderer.Clock.Instant.Duration {
    var timeInterval: TimeInterval {
        let nanoseconds = TimeInterval(components.attoseconds / 1_000_000_000)
        return TimeInterval(components.seconds) + (nanoseconds / TimeInterval(NSEC_PER_SEC))
    }
}

extension MTLDevice {
    var supportsMSAA: Bool {
        supportsTextureSampleCount(4) && supports32BitMSAA
    }
}

@globalActor actor RendererActor {
    static var shared = RendererActor()
}

@RendererActor
class Renderer {
    // App state
    private let appModel: AppModel
    
    // Renderers
    private let pathCollection: PathCollection
    private let tintRenderer: TintRenderer
    
    // Metal
    private let device: MTLDevice
    private let supportsMSAA: Bool
    private let commandQueue: MTLCommandQueue
    nonisolated static let maxFramesInFlight: UInt64 = 3
    private let depthState: MTLDepthStencilState
    private let layerRenderer: LayerRenderer
    private var multisampleRenderTargets: [(color: MTLTexture, depth: MTLTexture)?]

    // ARKit
    private let arSession: ARKitSession
    private let worldTracking: WorldTrackingProvider
        
    init(_ layerRenderer: LayerRenderer,
         _ appModel: AppModel,
         _ pathCollection: PathCollection,
         _ tintRenderer: TintRenderer) throws {
        self.appModel = appModel
        
        self.pathCollection = pathCollection
        self.tintRenderer = tintRenderer
        
        self.layerRenderer = layerRenderer
        self.device = layerRenderer.device
        supportsMSAA = layerRenderer.device.supportsMSAA
        self.commandQueue = self.device.makeCommandQueue()!
        multisampleRenderTargets = .init(repeating: nil, count: Int(Self.maxFramesInFlight))

        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.greater
        depthStateDescriptor.isDepthWriteEnabled = true
        self.depthState = device.makeDepthStencilState(descriptor: depthStateDescriptor)!
        
        arSession = ARKitSession()
        worldTracking = WorldTrackingProvider()
    }
    
    nonisolated static func defaultRenderPipelineDescriptor(layerRenderer: LayerRenderer) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.rasterSampleCount = layerRenderer.device.supportsMSAA ? 4 : 1
        pipelineDescriptor.colorAttachments[0].pixelFormat = layerRenderer.configuration.colorFormat
        pipelineDescriptor.depthAttachmentPixelFormat = layerRenderer.configuration.depthFormat
        pipelineDescriptor.maxVertexAmplificationCount = layerRenderer.properties.viewCount
                
        return pipelineDescriptor
    }
    
    private func memorylessTexture(from texture: MTLTexture) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: texture.pixelFormat,
                                                                  width: texture.width,
                                                                  height: texture.height,
                                                                  mipmapped: false)
        
        if supportsMSAA {
            descriptor.textureType = texture.textureType == .type2DArray ? .type2DMultisampleArray : .type2DMultisample
        } else {
            descriptor.textureType = texture.textureType
        }
        descriptor.sampleCount = supportsMSAA ? 4 : 1
        descriptor.storageMode = .memoryless
        descriptor.arrayLength = texture.arrayLength
        descriptor.usage = texture.usage

        return texture.device.makeTexture(descriptor: descriptor)!
    }
    
    private func getMultisampleRenderTarget(for frame: LayerRenderer.Frame,
                                            drawable: LayerRenderer.Drawable) -> (color: MTLTexture, depth: MTLTexture) {
        
        let intermediateRenderTargetIndex = Int(frame.frameIndex % Self.maxFramesInFlight)

        if let (color, depth) = multisampleRenderTargets[intermediateRenderTargetIndex],
           color.width == drawable.colorTextures[0].width, color.height == drawable.colorTextures[0].height {
           return (color, depth)
        } else {
            let color = memorylessTexture(from: drawable.colorTextures[0])
            let depth = memorylessTexture(from: drawable.depthTextures[0])
            multisampleRenderTargets[intermediateRenderTargetIndex] = (color, depth)
            return (color, depth)
        }
    }
}

extension Renderer {
    func renderLoop() async throws {
        // Setup ARKit Session
        let authorizations: [ARKitSession.AuthorizationType] = WorldTrackingProvider.requiredAuthorizations
        let dataProviders: [any DataProvider] = [worldTracking]
                
        _ = await arSession.requestAuthorization(for: authorizations)
        try await arSession.run(dataProviders)
        // Render loop
        while true {
            if layerRenderer.state == .invalidated {
                print("Layer is invalidated")
                Task { @MainActor in
                    arSession.stop()
                }
                
                return
            } else if layerRenderer.state == .paused {
                layerRenderer.waitUntilRunning()
                continue
            } else {
                try await self.renderFrame()
            }
        }
    }
    
    private func renderPassDescriptor(_ frame: LayerRenderer.Frame, _ drawable: LayerRenderer.Drawable) -> MTLRenderPassDescriptor {
        // Create the render descriptor with the drawable targets.
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        if supportsMSAA {
            let (colorTarget, depthTarget) = getMultisampleRenderTarget(for: frame, drawable: drawable)
            renderPassDescriptor.colorAttachments[0].texture = colorTarget
            renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.colorTextures[0]
            renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
            
            renderPassDescriptor.depthAttachment.texture = depthTarget
            renderPassDescriptor.depthAttachment.resolveTexture = drawable.depthTextures[0]
            renderPassDescriptor.depthAttachment.storeAction = .multisampleResolve
        } else {
            renderPassDescriptor.colorAttachments[0].texture = drawable.colorTextures[0]
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            renderPassDescriptor.depthAttachment.texture = drawable.depthTextures[0]
            renderPassDescriptor.depthAttachment.storeAction = .store
        }
        
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 0.0
        
        renderPassDescriptor.rasterizationRateMap = drawable.rasterizationRateMaps.first
        if layerRenderer.configuration.layout == .layered {
            renderPassDescriptor.renderTargetArrayLength = drawable.views.count
        }
        
        return renderPassDescriptor
    }
    
    func renderFrame() async throws {
        guard let frame = layerRenderer.queryNextFrame() else { return }
                
        frame.startUpdate()
        
        guard let timing = frame.predictTiming() else { return }
        
        // Update scene and generate draw commands.
        let pathCollectionDrawCommand = try await Task { @MainActor in
            try pathCollection.update(withTiming: timing, worldTracking: worldTracking)
            return try pathCollection.drawCommand(frame: frame)
        }.result.get()
        let tintDrawCommand = try await Task { @MainActor in
            return try tintRenderer.drawCommand(frame: frame)
        }.result.get()

        // Query the drawable after scene update to avoid blocking on the drawable.
        guard let drawable = frame.queryDrawable() else { return }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { fatalError("Failed to create command buffer") }
        
        // Encode the GPU render commands.
        let renderPassDescriptor = self.renderPassDescriptor(frame, drawable)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { fatalError("Failed to create render encoder") }
    
        renderEncoder.label = "Primary Render Encoder"
        renderEncoder.pushDebugGroup("Mesh drawing")
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setDepthStencilState(depthState)
        
        let viewports = drawable.views.map { $0.textureMap.viewport }
        
        renderEncoder.setViewports(viewports)
        
        if drawable.views.count > 1 {
            var viewMappings = (0..<drawable.views.count).map {
                MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: UInt32($0), renderTargetArrayIndexOffset: UInt32($0))
            }
            renderEncoder.setVertexAmplificationCount(viewports.count, viewMappings: &viewMappings)
        }
        pathCollection.encodeDraw(pathCollectionDrawCommand, encoder: renderEncoder, commandBuffer: commandBuffer)
        tintRenderer.encodeDraw(tintDrawCommand, encoder: renderEncoder, drawable: drawable, device: device, tintValue: appModel.tintOpacity)
        
        renderEncoder.popDebugGroup()
        renderEncoder.endEncoding()
        
        frame.endUpdate()
        
        // Pace frames by waiting for the optimal prediction time.
        try await LayerRenderer.Clock().sleep(until: timing.optimalInputTime, tolerance: nil)
        
        // Start submitting the updated frame.
        frame.startSubmission()
        
        // Get the drawable device anchor state at presentation time.
        let time = LayerRenderer.Clock.Instant.epoch.duration(to: drawable.frameTiming.presentationTime).timeInterval
        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: time)
        drawable.deviceAnchor = deviceAnchor
        
        // Update the renderer uniforms using the latest device anchor.
        pathCollection.updateUniformBuffers(pathCollectionDrawCommand, drawable: drawable)
        tintRenderer.updateUniformBuffers(tintDrawCommand, drawable: drawable)
                
        drawable.encodePresent(commandBuffer: commandBuffer)
        
        commandBuffer.commit()
        
        frame.endSubmission()
    }
}
