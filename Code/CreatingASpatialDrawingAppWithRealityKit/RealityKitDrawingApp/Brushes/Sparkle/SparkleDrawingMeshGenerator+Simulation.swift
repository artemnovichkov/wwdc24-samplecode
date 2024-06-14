/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Facilitates the GPU particle simulation, used to generate meshes of the sparkle brush.
*/

import RealityKit
import Metal

extension SparkleDrawingMeshGenerator {
    /// Compute pipeline corresponding to the Metal compute kernel `sparkleBrushSimulate`.
    ///
    /// See `SparkleBrushGeneration.metal`.
    private static let simulatePipeline: MTLComputePipelineState? = makeComputePipeline(named: "sparkleBrushSimulate")
    
    static func simulate(input: MTLBuffer,
                         output: MTLBuffer,
                         particleOffsetInOutput: Int = 0,
                         particleCount: Int,
                         parameters: SparkleBrushSimulationParams,
                         encoder: MTLComputeCommandEncoder) throws {
        precondition(particleCount > 0)
        
        guard let simulatePipeline = Self.simulatePipeline else {
            throw SparkleBrushGenerationError.unableToCreateComputePipeline
        }
        
        let particleStride = MemoryLayout<SparkleBrushParticle>.stride
        let paramSize = MemoryLayout<SparkleBrushSimulationParams>.size
        precondition(input.length >= particleCount * particleStride)
        precondition(output.length >= (particleCount + particleOffsetInOutput) * particleStride)
        
        let groupSize = simulatePipeline.maxTotalThreadsPerThreadgroup
        encoder.setComputePipelineState(simulatePipeline)
        
        encoder.setBuffer(input, offset: 0, index: 0)
        encoder.setBuffer(output, offset: particleOffsetInOutput * particleStride, index: 1)
        
        withUnsafePointer(to: parameters) { parametersPtr in
            encoder.setBytes(parametersPtr, length: paramSize, index: 2)
        }
        
        let numGroups = (particleCount + groupSize - 1) / groupSize
        encoder.dispatchThreadgroups(MTLSizeMake(numGroups, 1, 1),
                                     threadsPerThreadgroup: MTLSizeMake(groupSize, 1, 1))
    }
    
    static func addParticlesToSimulation(input: UnsafeBufferPointer<SparkleBrushParticle>,
                                         output: MTLBuffer,
                                         particleOffsetInOutput: Int = 0,
                                         encoder: MTLComputeCommandEncoder) throws {
        let particleCount = input.count
        precondition(particleCount > 0)
        
        guard let simulatePipeline = Self.simulatePipeline else {
            throw SparkleBrushGenerationError.unableToCreateComputePipeline
        }
        
        let particleStride = MemoryLayout<SparkleBrushParticle>.stride
        precondition(output.length >= (particleOffsetInOutput + particleCount) * particleStride)
        
        let groupSize = simulatePipeline.maxTotalThreadsPerThreadgroup
        // `setBytes` has a maximum payload size of 4 KB.
        // Usually, expect to have less than 4 KB of data, but in case you run over you'll need to split the data.
        let maxParticlesPerDispatch = 4096 / particleStride
        
        for particleStartIndex in stride(from: 0, to: particleCount, by: maxParticlesPerDispatch) {
            let particleEndIndex = min(particleStartIndex + maxParticlesPerDispatch, particleCount)
            
            let length = particleEndIndex - particleStartIndex
            let byteLength = length * particleStride
            
            let inputSlice = UnsafeBufferPointer(rebasing: input[particleStartIndex..<particleEndIndex])
            precondition(inputSlice.count == length)
            
            encoder.setComputePipelineState(simulatePipeline)
            
            encoder.setBytes(inputSlice.baseAddress!, length: byteLength, index: 0)
            encoder.setBuffer(output, offset: (particleOffsetInOutput + particleStartIndex) * particleStride, index: 1)
            
            // Set `particleCount` to the number of particles being added this batch.
            // Set `deltaTime` and `dragCoefficient` to zero, because you don't yet want to simulate the particles.
            var currentParameters = SparkleBrushSimulationParams(particleCount: UInt32(length),
                                                                 deltaTime: 0,
                                                                 dragCoefficient: 0)
            encoder.setBytes(&currentParameters, length: MemoryLayout<SparkleBrushSimulationParams>.size, index: 2)
            
            let numGroups = (length + groupSize - 1) / groupSize
            encoder.dispatchThreadgroups(MTLSizeMake(numGroups, 1, 1),
                                         threadsPerThreadgroup: MTLSizeMake(groupSize, 1, 1))
        }
    }
}
