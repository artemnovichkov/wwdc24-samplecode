/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Facilitates the generation of the mesh of the sparkle brush given the result of the brush's GPU particle simulation.
*/

import RealityKit
import Metal

extension SparkleDrawingMeshGenerator {
    /// Compute pipeline corresponding to the Metal compute kernel `sparkleBrushPopulate`.
    ///
    /// See `SparkleBrushSimulation.metal`.
    private static let populatePipeline: MTLComputePipelineState? = makeComputePipeline(named: "sparkleBrushPopulate")

    /// Creates a low level mesh suitable for this mesh generator to render.
    ///
    /// - Parameters:
    ///   - particleCapacity: The number of particles the `LowLevelMesh` is to support.
    ///   - particleCount: The number of particles currently visible in the `LowLevelMesh`.
    static func makeLowLevelMesh(particleCapacity: Int, particleCount: Int) throws -> LowLevelMesh {
        var descriptor = LowLevelMesh.Descriptor()

        descriptor.vertexCapacity = 4 * particleCapacity
        descriptor.indexCapacity = 6 * particleCapacity
        descriptor.vertexAttributes = SparkleBrushVertex.vertexAttributes

        let stride = MemoryLayout<SparkleBrushVertex>.stride
        descriptor.vertexLayouts = [.init(bufferIndex: 0, bufferStride: stride)]

        let mesh = try LowLevelMesh(descriptor: descriptor)

        // The bounding box is used to occlude parts of your mesh when it isn't seen.
        // The drawing app should display all brush strokes, so use an arbitrarily large bounds.
        let bounds = BoundingBox(min: [-100, -100, -100], max: [100, 100, 100])
        mesh.parts.append(LowLevelMesh.Part(indexOffset: 0, indexCount: 6 * particleCount,
                                            topology: .triangle, materialIndex: 0,
                                            bounds: bounds))

        mesh.withUnsafeMutableIndices { buffer in
            let topology: [UInt32] = [0, 1, 2, 2, 3, 0]

            // Fill the index buffer with `particleCount` copies
            // of the array `topology` offset for each particle.
            let typedBuffer = buffer.bindMemory(to: UInt32.self)
            let topologyCount = topology.count
            for particleIndex in 0..<particleCapacity {
                let baseIndex = topologyCount * particleIndex
                let offset = UInt32(particleIndex * 4)
                for vertIndex in 0..<topologyCount {
                    typedBuffer[baseIndex + vertIndex] = topology[vertIndex] + offset
                }
            }
        }
        return mesh
    }
    
    /// Populates the `LowLevelMesh` vertex buffer with the result of the particle simulation.
    ///
    /// - Parameters:
    ///   - input: The particle simulation buffer, which determines particle positions.
    ///   - output: The `LowLevelMesh` to write to.
    ///   - particleCount: The number of particles active in `input`.
    ///   - commandBuffer: The Metal command buffer to use.
    ///   - encoder: The Metal compute command encoder to use.
    static func populate(input: MTLBuffer,
                         output: LowLevelMesh,
                         particleCount: Int,
                         commandBuffer: MTLCommandBuffer,
                         encoder: MTLComputeCommandEncoder) throws {
        precondition(particleCount > 0)
        
        guard let populatePipeline = Self.populatePipeline else {
            throw SparkleBrushGenerationError.unableToCreateComputePipeline
        }
        
        let particleStride = MemoryLayout<SparkleBrushParticle>.stride
        precondition(input.length >= particleCount * particleStride)
        
        // 4 Vertices per particle.
        precondition(output.descriptor.vertexCapacity >= 4 * particleCount)
        // 6 Triangle indices per particle.
        precondition(output.descriptor.indexCapacity >= 6 * particleCount)
        
        let groupSize = populatePipeline.maxTotalThreadsPerThreadgroup
        encoder.setComputePipelineState(populatePipeline)
        
        encoder.setBuffer(input, offset: 0, index: 0)
        
        let vertexBuffer = output.replace(bufferIndex: 0, using: commandBuffer)
        encoder.setBuffer(vertexBuffer, offset: 0, index: 1)
        
        var particleCountUInt = UInt32(particleCount)
        encoder.setBytes(&particleCountUInt, length: MemoryLayout<UInt32>.size, index: 2)
        
        let numGroups = (particleCount + groupSize - 1) / groupSize
        encoder.dispatchThreadgroups(MTLSizeMake(numGroups, 1, 1),
                                     threadsPerThreadgroup: MTLSizeMake(groupSize, 1, 1))
        
        output.parts[0].indexCount = particleCount * 6
    }
}
