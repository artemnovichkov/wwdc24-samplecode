/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A RealityKit component and system used to facilitate the background of the
  splash screen. The splash screen background is a RealityKit entity that
  updates a `LowLevelTexture` every frame and displays it using
  a `ShaderGraphMaterial`.
*/

import RealityKit
import RealityKitContent

/// A RealityKit component that holds the data related to the splash screen background texture.
///
/// The component structure also provides functions to manage the generation of the texture each frame.
struct SplashScreenBackgroundComponent: TransientComponent {
    private static let computePipeline: MTLComputePipelineState? = makeComputePipeline(named: "splashScreenBackgroundKernel")
    
    private static let commandQueue: MTLCommandQueue? = {
        if let metalDevice, let queue = metalDevice.makeCommandQueue() {
            queue.label = "Splash Screen Background Command Queue"
            return queue
        } else {
            return nil
        }
    }()

    private(set) var lowLevelTexture: LowLevelTexture
    
    /// The size of `lowLevelTexture`.
    private var textureSize: SIMD2<Int> {
        let descriptor = lowLevelTexture.descriptor
        return [descriptor.width, descriptor.height]
    }
    
    /// The `Date` at which the splash screen first appeared.
    private let spawnDate: Date
    
    /// The RealityKit material to use when rendering the background.
    private(set) var material: RealityKit.ShaderGraphMaterial
    
    /// Errors that could occur during splash screen background generation.
    private enum SplashScreenBackgroundGenerationError: Error {
        case unableToCreateComputePipeline
        case unableToCreateEncoders
        case unableToCreateNoiseTexture
    }
    
    /// Generate a `LowLevelTexture` suitable to be populated for the splash screen background.
    ///
    /// - Parameters:
    ///   - width: The width of the texture.
    ///   - height: The height of the texture.
    private static func generateTexture(width: Int, height: Int) throws -> LowLevelTexture {
        return try LowLevelTexture(descriptor: .init(pixelFormat: .rg16Float,
                                                     width: width,
                                                     height: height,
                                                     depth: 1,
                                                     mipmapLevelCount: 1,
                                                     textureUsage: [.shaderWrite, .shaderRead]))
    }

    /// Initializes the splash screen background to a texture with the provided resolution.
    @MainActor
    init(textureSize: SIMD2<Int>) async throws {
        spawnDate = Date.now
        lowLevelTexture = try Self.generateTexture(width: textureSize.x, height: textureSize.y)
        
        material = try await ShaderGraphMaterial(named: "/Root/Material",
                                                      from: "SplashScreenMaterial",
                                                      in: realityKitContentBundle)
        
        let textureResource = try await TextureResource(from: lowLevelTexture)
        try material.setParameter(name: "DistanceFieldTexture", value: .textureResource(textureResource))
    }
    
    /// Updates the texture size of the splash screen background to the provided resolution.
    mutating func setTextureSize(_ textureSize: SIMD2<Int>) throws {
        lowLevelTexture = try Self.generateTexture(width: textureSize.x, height: textureSize.y)
        let textureResource = try TextureResource(from: lowLevelTexture)
        try material.setParameter(name: "DistanceFieldTexture", value: .textureResource(textureResource))
        try update()
    }
    
    /// Updates the underlying `LowLevelTexture` for the splash screen.
    func update() throws {
        // Set up the Metal command buffer and compute command encoder.
        guard let commandBuffer = Self.commandQueue?.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                  throw SplashScreenBackgroundGenerationError.unableToCreateEncoders
        }
        
        commandBuffer.enqueue()

        defer {
            computeEncoder.endEncoding()
            commandBuffer.commit()
        }
        
        // Load the Metal compute pipeline corresponding with the kernel in `SplashScreenBackground.metal`.
        guard let computePipeline = Self.computePipeline else {
            throw SplashScreenBackgroundGenerationError.unableToCreateComputePipeline
        }
        computeEncoder.setComputePipelineState(computePipeline)

        // Acquire the output texture from `LowLevelTexture`, providing the command buffer.
        let outTexture: MTLTexture = lowLevelTexture.replace(using: commandBuffer)
        computeEncoder.setTexture(outTexture, index: 0)
        
        // Pass the current time to the compute kernel to facilitate animation.
        var time = Float(spawnDate.distance(to: Date.now))
        computeEncoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Compute the thread and group size for threadgroup dispatch.
        let threadGroupSizePerDimension = 16
        let threadGroupCountPerDimension = (textureSize &+ (threadGroupSizePerDimension - 1)) / threadGroupSizePerDimension

        let threadGroupSize = MTLSize(width: threadGroupSizePerDimension,
                                      height: threadGroupSizePerDimension,
                                      depth: 1)
        let threadGroupCount = MTLSize(width: threadGroupCountPerDimension.x,
                                       height: threadGroupCountPerDimension.y,
                                       depth: 1)
        
        // Dispatch the compute work.
        computeEncoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
    }
}

/// A RealityKit system used to update the splash screen background.
class SplashScreenBackgroundSystem: System {
    static let query = EntityQuery(where: .has(SplashScreenBackgroundComponent.self))
    required init(scene: RealityKit.Scene) { }

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            let background = entity.components[SplashScreenBackgroundComponent.self]!
            try? background.update()
        }
    }
}
