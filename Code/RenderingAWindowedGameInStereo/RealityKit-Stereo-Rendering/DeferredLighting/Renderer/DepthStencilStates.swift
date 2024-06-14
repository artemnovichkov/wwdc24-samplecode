/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
MTLDepthStencilStates that are used by the Renderer.
*/

import Metal

// MARK: - DepthStencilStates
struct DepthStencilStates {
    
    lazy var shadowGeneration = makeDepthStencilState(label: "Shadow Generation Stage") { descriptor in
        descriptor.isDepthWriteEnabled = true
        descriptor.depthCompareFunction = .lessEqual
    }
    
    lazy var gBufferGeneration = makeDepthStencilState(label: "GBuffer Generation Stage") { descriptor in
        
        var stencilStateDescriptor: MTLStencilDescriptor?
        if LIGHT_STENCIL_CULLING == 1 {
            stencilStateDescriptor = MTLStencilDescriptor()
            stencilStateDescriptor?.depthStencilPassOperation = .replace
        }
        
        descriptor.isDepthWriteEnabled = true
        descriptor.depthCompareFunction = .less
        descriptor.frontFaceStencil = stencilStateDescriptor
        descriptor.backFaceStencil = stencilStateDescriptor
    }
    
    lazy var directionalLighting = makeDepthStencilState(label: "Directional Lighting Stage") { descriptor in
        
        // Create stencil state to apply directional lighting only to pixels drawn to in GBUffer stage
        var stencilStateDescriptor: MTLStencilDescriptor?
        if LIGHT_STENCIL_CULLING == 1 {
            stencilStateDescriptor = MTLStencilDescriptor()
            stencilStateDescriptor?.stencilCompareFunction = .equal
            stencilStateDescriptor?.readMask = 0xFF
            stencilStateDescriptor?.writeMask = 0x0
        }
        
        descriptor.frontFaceStencil = stencilStateDescriptor
        descriptor.backFaceStencil = stencilStateDescriptor
    }
    
    lazy var lightMask: MTLDepthStencilState? = {
        if LIGHT_STENCIL_CULLING == 1 {
            return makeDepthStencilState(label: "Point Light Mask Stage") { descriptor in
                let stencilStateDescriptor = MTLStencilDescriptor()
                stencilStateDescriptor.depthFailureOperation = .incrementClamp
                
                descriptor.depthCompareFunction = .lessEqual
                descriptor.frontFaceStencil = stencilStateDescriptor
                descriptor.backFaceStencil = stencilStateDescriptor
            }
        }
    }()
    
    lazy var pointLighting = makeDepthStencilState(label: "Point Lights Stage") { descriptor in
        
        var stencilStateDescriptor: MTLStencilDescriptor?
        if LIGHT_STENCIL_CULLING == 1 {
            stencilStateDescriptor = MTLStencilDescriptor()
            stencilStateDescriptor?.stencilCompareFunction = .less
            stencilStateDescriptor?.readMask = 0xFF
            stencilStateDescriptor?.writeMask = 0x0
        }
        
        descriptor.depthCompareFunction = .lessEqual
        descriptor.frontFaceStencil = stencilStateDescriptor
        descriptor.backFaceStencil = stencilStateDescriptor
    }
    
    lazy var skybox = makeDepthStencilState(label: "Skybox Stage") { descriptor in
        descriptor.depthCompareFunction = .less
    }
    
    lazy var fairyLighting = makeDepthStencilState(label: "Fairy Lights Stage") { descriptor in
        descriptor.depthCompareFunction = .less
    }
    
    let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func makeDepthStencilState(label: String,
                               block: (MTLDepthStencilDescriptor) -> Void) -> MTLDepthStencilState {
        let descriptor = MTLDepthStencilDescriptor()
        block(descriptor)
        descriptor.label = label
        if let depthStencilState = device.makeDepthStencilState(descriptor: descriptor) {
            return depthStencilState
        } else {
            fatalError("Failed to create depth-stencil state.")
        }
    }
    
}
