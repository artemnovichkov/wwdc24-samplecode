/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
MTLRenderPipelineStates used by the Renderer.
*/

import Metal

// MARK: - PipelineStates
struct PipelineStates {
    
    lazy var shadowGeneration = makeRenderPipelineState(label: "Shadow Generation Stage") { descriptor in
        descriptor.vertexFunction = library.makeFunction(name: "shadow_vertex")
        descriptor.depthAttachmentPixelFormat = .depth32Float
    }
    
    lazy var gBufferGeneration = makeRenderPipelineState(label: "GBuffer Generation Stage") { descriptor in
        descriptor.vertexFunction = library.makeFunction(name: "gbuffer_vertex")
        descriptor.fragmentFunction = library.makeFunction(name: "gbuffer_fragment")
        descriptor.vertexDescriptor = vertexDescriptors.basic
        descriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        
        if GBufferTextures.attachedInFinalPass {
            descriptor.colorAttachments[AAPLRenderTargetLighting.rawValue]?.pixelFormat = colorPixelFormat
        }
        
        setRenderTargetPixelFormats(descriptor: descriptor)
    }
    
    lazy var directionalLighting = makeRenderPipelineState(label: "Directional Lighting Stage") { descriptor in
        descriptor.vertexFunction = library.makeFunction(name: "deferred_direction_lighting_vertex")
        
        if singlePass {
            descriptor.fragmentFunction = library.makeFunction(name: "deferred_directional_lighting_fragment_single_pass")
        } else {
            descriptor.fragmentFunction = library.makeFunction(name: "deferred_directional_lighting_fragment_traditional")
        }
        
        descriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        
        descriptor.colorAttachments[AAPLRenderTargetLighting.rawValue]?.pixelFormat = colorPixelFormat
        
        if GBufferTextures.attachedInFinalPass {
            setRenderTargetPixelFormats(descriptor: descriptor)
        }
    }
    
    lazy var lightMask: MTLRenderPipelineState? = {
        if LIGHT_STENCIL_CULLING == 1 {
            return makeRenderPipelineState(label: "Light Mask Stage") { descriptor in
                descriptor.vertexFunction = library.makeFunction(name: "light_mask_vertex")
                descriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
                descriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
                
                descriptor.colorAttachments[AAPLRenderTargetLighting.rawValue]?.pixelFormat = colorPixelFormat
                
                if GBufferTextures.attachedInFinalPass {
                    setRenderTargetPixelFormats(descriptor: descriptor)
                }
            }
        }
    }()
    
    lazy var pointLighting = makeRenderPipelineState(label: "Point Lights Stage") { descriptor in
        descriptor.vertexFunction = library.makeFunction(name: "deferred_point_lighting_vertex")

         if singlePass {
            descriptor.fragmentFunction = library.makeFunction(name: "deferred_point_lighting_fragment_single_pass")
        } else {
            descriptor.fragmentFunction = library.makeFunction(name: "deferred_point_lighting_fragment_traditional")
        }
        
        descriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        
        descriptor.colorAttachments[AAPLRenderTargetLighting.rawValue]?.pixelFormat = colorPixelFormat
        
        if GBufferTextures.attachedInFinalPass {
            setRenderTargetPixelFormats(descriptor: descriptor)
        } else {
            // Enable additive blending
            let colorAttachment = descriptor.colorAttachments[AAPLRenderTargetLighting.rawValue]
            colorAttachment?.isBlendingEnabled = true
            colorAttachment?.destinationRGBBlendFactor = .one
            colorAttachment?.destinationAlphaBlendFactor = .one
        }
    }
    
    lazy var skybox = makeRenderPipelineState(label: "Skybox Stage") { descriptor in
        descriptor.vertexFunction = library.makeFunction(name: "skybox_vertex")
        descriptor.fragmentFunction = library.makeFunction(name: "skybox_fragment")
        descriptor.vertexDescriptor = vertexDescriptors.skybox
        descriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        
        descriptor.colorAttachments[AAPLRenderTargetLighting.rawValue]?.pixelFormat = colorPixelFormat
        
        if GBufferTextures.attachedInFinalPass {
            setRenderTargetPixelFormats(descriptor: descriptor)
        }
    }
    
    lazy var fairyLighting = makeRenderPipelineState(label: "Fairy Lights Stage") { descriptor in
        descriptor.vertexFunction = library.makeFunction(name: "fairy_vertex")
        descriptor.fragmentFunction = library.makeFunction(name: "fairy_fragment")
        descriptor.depthAttachmentPixelFormat = depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = depthStencilPixelFormat
        
        descriptor.colorAttachments[AAPLRenderTargetLighting.rawValue]?.pixelFormat = colorPixelFormat
        
        if GBufferTextures.attachedInFinalPass {
            setRenderTargetPixelFormats(descriptor: descriptor)
        }
        
        let colorAttachment = descriptor.colorAttachments[AAPLRenderTargetLighting.rawValue]
        colorAttachment?.isBlendingEnabled = true
        colorAttachment?.sourceRGBBlendFactor = .sourceAlpha
        colorAttachment?.sourceAlphaBlendFactor = .sourceAlpha
        colorAttachment?.destinationRGBBlendFactor = .one
        colorAttachment?.destinationAlphaBlendFactor = .one
    }
    
    let device: MTLDevice
    let library: MTLLibrary
    
    let singlePass: Bool
    let colorPixelFormat: MTLPixelFormat
    let depthStencilPixelFormat: MTLPixelFormat
    
    let vertexDescriptors = VertexDescriptors()
    
    init(device: MTLDevice, renderDestination: RenderDestination, singlePass: Bool) {
        self.device = device
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default library with device: \(device.description)")
        }
        self.library = library
        
        self.singlePass = singlePass
        
        colorPixelFormat = renderDestination.colorPixelFormat
        depthStencilPixelFormat = renderDestination.depthStencilPixelFormat
    }
    
    func makeRenderPipelineState(label: String,
                                 block: (MTLRenderPipelineDescriptor) -> Void) -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        block(descriptor)
        descriptor.label = label
        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func setRenderTargetPixelFormats(descriptor: MTLRenderPipelineDescriptor) {
        
        descriptor.colorAttachments[AAPLRenderTargetAlbedo.rawValue]?.pixelFormat = GBufferTextures.albedoSpecularFormat
        
        descriptor.colorAttachments[AAPLRenderTargetNormal.rawValue]?.pixelFormat = GBufferTextures.normalShadowFormat
        
        descriptor.colorAttachments[AAPLRenderTargetDepth.rawValue]?.pixelFormat = GBufferTextures.depthFormat
    }
    
}

