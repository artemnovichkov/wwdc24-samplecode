/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Renderer class that performs Metal setup and per-frame rendering for a
  single pass deferred renderer used for iOS and tvOS devices.
*/

import MetalKit

class SinglePassDeferredRenderer: Renderer {
    init(device: MTLDevice,
         scene: Scene,
         renderDestination: RenderDestination,
         commandQueue: MTLCommandQueue,
         didBeginFrame: @escaping () -> Void) {

        super.init(device: device,
                   scene: scene,
                   renderDestination: renderDestination,
                   singlePass: true,
                   commandQueue: commandQueue,
                   didBeginFrame: didBeginFrame)
    }

    let gBufferAndLightingPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        // We can't (and don't need to) store these color attachments in single pass deferred rendering
        // because they are memoryless and are only needed temporarily during the rendering process.
        descriptor.colorAttachments[Int(AAPLRenderTargetAlbedo.rawValue)].storeAction = .dontCare
        descriptor.colorAttachments[Int(AAPLRenderTargetNormal.rawValue)].storeAction = .dontCare
        descriptor.colorAttachments[Int(AAPLRenderTargetDepth.rawValue)].storeAction = .dontCare
        return descriptor
    }()
}

#if !os(visionOS)

extension SinglePassDeferredRenderer {

    /// MTKViewDelegate Callback: Respond to device orientation changes or other view size changes.
    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        guard let device = view.device else {
            fatalError("MTKView does not have a MTLDevice.")
        }
        
        self.drawableSizeWillChange(size: size)

        // Draw once, even though the view is paused to make sure the scene doesn't appear stretched.
        if view.isPaused {
            view.draw()
        }
    }

    /// MTKViewDelegate callback: Called whenever the view needs to render.
    override func draw(in view: MTKView) {
        draw(provider: view)
    }
}

#endif

extension SinglePassDeferredRenderer {

    override func drawableSizeWillChange(size: CGSize) {
        var storageMode = MTLStorageMode.private

        if #available(macOS 11, *) {
            storageMode = .memoryless
        }

        drawableSizeWillChange?(device, size, storageMode)
        // Reset GBuffer textures in the view render pass descriptor after they have been reallocated by a resize.
        setGBufferTextures(gBufferAndLightingPassDescriptor)
    }

    override func draw(provider: DrawableProviding) {
        var commandBuffer = beginFrame()
        commandBuffer.label = "Shadow Commands"

        // MARK: - Shadow Map Pass
        encodeShadowMapPass(into: commandBuffer)

        // Commit commands so that Metal can begin working on nondrawable dependent work without
        // waiting for a drawable to become avaliable.
        commandBuffer.commit()

        for viewIndex in 0..<provider.viewCount {
            scene.update(viewMatrix: provider.viewMatrix(viewIndex: viewIndex),
                         projectionMatrix: provider.projectionMatrix(viewIndex: viewIndex))

            commandBuffer = beginDrawableCommands()
            commandBuffer.label = "GBuffer & Lighting Commands"

            // MARK: - GBuffer and Lighting Pass
            // The final pass can only render if a drawable is available; otherwise, don't
            // render this frame.
            if let color = provider.colorTexture(viewIndex: viewIndex, for: commandBuffer),
               let depthStencil = provider.depthStencilTexture(viewIndex: viewIndex, for: commandBuffer) {
                gBufferAndLightingPassDescriptor.colorAttachments[Int(AAPLRenderTargetLighting.rawValue)].texture = color
                gBufferAndLightingPassDescriptor.depthAttachment.texture = depthStencil
                gBufferAndLightingPassDescriptor.stencilAttachment.texture = depthStencil
                gBufferAndLightingPassDescriptor.rasterizationRateMap = provider.rasterizationRateMap(viewIndex: viewIndex)

                encodePass(into: commandBuffer, using: gBufferAndLightingPassDescriptor, label: "GBuffer & Lighting Pass") { renderEncoder in

                    encodeGBufferStage(using: renderEncoder)
                    encodeDirectionalLightingStage(using: renderEncoder)
                    encodeLightMaskStage(using: renderEncoder)
                    encodePointLightStage(using: renderEncoder)
                    encodeSkyboxStage(using: renderEncoder)
                    encodeFairyBillboardStage(using: renderEncoder)
                }
            }

            endFrame(commandBuffer)
        }
    }
}
