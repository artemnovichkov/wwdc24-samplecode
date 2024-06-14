/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A container for G-buffer textures.
*/

import Metal
import CoreGraphics

// MARK: - GBufferTextures
struct GBufferTextures {
    
    // GBuffer textures
    var albedoSpecular: MTLTexture!
    var normalShadow: MTLTexture!
    var depth: MTLTexture!
    
    /// Returns the current width of GBuffer textures.
    var width: UInt32 {
        UInt32(albedoSpecular.width)
    }
    
    /// Returns the current height of GBuffer textures.
    var height: UInt32 {
        UInt32(albedoSpecular.height)
    }
    
    //The pipelines of single-pass and traditional deferred renderers differ in that the single-pass
    // renderer needs the GBuffers attached as render targets, while the traditional renderer needs
    // the GBuffer set as textures to sample/read from.   So this is true for thesingle-pass renderer
    // renderer and false for the traditional renderer renderer so that some of the code to create
    // these pipelines can be shared and implemented in this AAPLRenderer base class which is common
    // to both renderers.
    static let attachedInFinalPass: Bool = {
        #if targetEnvironment(simulator)
        return false
        #else
        let device = MTLCreateSystemDefaultDevice()!
        return device.supportsFamily(.apple1)
        #endif
    }()
    
    // GBuffer pixel formats
    static let albedoSpecularFormat = MTLPixelFormat.rgba8Unorm_srgb
    static let normalShadowFormat = MTLPixelFormat.rgba8Snorm
    static let depthFormat = MTLPixelFormat.r32Float
    
    mutating func makeTextures(device: MTLDevice, size: CGSize, storageMode: MTLStorageMode) {
        let gBufferTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb,
                                 width: Int(size.width),
                                 height: Int(size.height),
                                 mipmapped: false)
        gBufferTextureDescriptor.textureType = .type2D
        gBufferTextureDescriptor.usage = [.shaderRead, .renderTarget]
        gBufferTextureDescriptor.storageMode = storageMode
        
        gBufferTextureDescriptor.pixelFormat = GBufferTextures.albedoSpecularFormat
        
        albedoSpecular = device.makeTexture(descriptor: gBufferTextureDescriptor)
        albedoSpecular.label = "Albedo + Specular GBuffer"
        
        gBufferTextureDescriptor.pixelFormat = GBufferTextures.normalShadowFormat
        normalShadow = device.makeTexture(descriptor: gBufferTextureDescriptor)
        normalShadow.label = "Normal + Shadow GBuffer"
        
        gBufferTextureDescriptor.pixelFormat = GBufferTextures.depthFormat
        depth = device.makeTexture(descriptor: gBufferTextureDescriptor)
        depth.label = "Depth GBuffer"
    }
}
