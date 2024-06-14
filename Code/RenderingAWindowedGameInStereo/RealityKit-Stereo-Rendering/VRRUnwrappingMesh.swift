/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Mesh used to unwarp and display a texture warped by Variable Rate Rasterization (VRR).
*/

import RealityKit
import Metal
import simd

extension VRRVertex {
    static var vertexAttributes: [LowLevelMesh.Attribute] {
        return [
            .init(semantic: .position,
                  format: .float3,
                  offset: MemoryLayout.offset(of: \Self.position)!),

                .init(semantic: .uv0,
                      format: .float2,
                      offset: MemoryLayout.offset(of: \Self.uv0)!)
        ]
    }

    static var vertexLayouts: [LowLevelMesh.Layout] {
        return [.init(bufferIndex: 0, bufferStride: MemoryLayout<Self>.stride)]
    }
}

extension BoundingBox {
    init(center: SIMD3<Float>, extents: SIMD3<Float>) {
        self.init(min: center - extents * 0.5,
                  max: center + extents * 0.5)
    }
}

extension simd_uint2 {
    init(_ size: MTLSize) {
        self.init(UInt32(size.width), UInt32(size.height))
    }
}

extension VRRMeshUpdateParams {
    init(from vrr: MTLRasterizationRateMap, textureSize: MTLSize) {
        self.init()
        self.positionOffset = .zero
        self.screenSize = .init(vrr.screenSize)
        self.physicalGranularity = .init(vrr.physicalGranularity)
        self.physicalSizeUsed = .init(vrr.physicalSize(layer: 0))
        self.physicalSizeTotal = .init(textureSize)

        self.tilesInGrid = (self.physicalSizeTotal &+ self.physicalGranularity &- 1) / self.physicalGranularity
        self.verticesInGrid = self.tilesInGrid &+ simd_uint2(1, 1)

        self.sizeScale = .init(self.widthMultiplier, self.heightMultiplier)
        self.invScreenSize = simd_recip(simd_float2(self.screenSize))
        self.invPhysicalSizeTotal = simd_recip(simd_float2(self.physicalSizeTotal))
    }

    func indexOfVertex(x: Int, y: Int) -> Int {
        return x + y * Int(verticesInGrid.x)
    }

    func indexOfVertex(x: UInt32, y: UInt32) -> UInt32 {
        return x + y * verticesInGrid.x
    }

    var heightMultiplier: Float {
        if screenSize.x >= screenSize.y {
            return Float(screenSize.y) / Float(screenSize.x)
        } else {
            return 1.0
        }
    }

    var widthMultiplier: Float {
        if screenSize.x >= screenSize.y {
            return 1.0
        } else {
            return Float(screenSize.x) / Float(screenSize.y)
        }
    }
}

/// Object that can create and update a mesh that unwarps VRR rendered content.
///
/// The mesh is at most 1 x 1 meters, and centered at (0,0,0). The aspect ratio matches the
/// aspect ratio of the supplied texture.
struct VRRUnwrappingMesh {
    static let updateMeshPipeline = mtlComputePipeline(named: "updateVRRMesh")!
    static let updateIndicesPipeline = mtlComputePipeline(named: "updateVRRIndices")!

    var mesh: LowLevelMesh
    var positionOffset = simd_float3(-0.5, -0.5, 0.0)
    var unwarp = true

    init(maxTextureSize: MTLSize, granularity: MTLSize = .init(width: 16, height: 16, depth: 1)) {
        let maxTilesWide = (maxTextureSize.width + granularity.width - 1) / granularity.width
        let maxTilesHigh = (maxTextureSize.height + granularity.height - 1) / granularity.height

        var descriptor = LowLevelMesh.Descriptor()
        descriptor.indexCapacity = maxTilesWide * maxTilesHigh * 6
        descriptor.indexType = .uint32
        descriptor.vertexCapacity = (maxTilesWide + 1) * (maxTilesHigh + 1)
        descriptor.vertexAttributes = VRRVertex.vertexAttributes
        descriptor.vertexLayouts = VRRVertex.vertexLayouts

        self.mesh = try! LowLevelMesh(descriptor: descriptor)
        self.mesh.parts.replaceAll([
            .init(indexCount: 0,
                  topology: .triangle,
                  bounds: .init(min: .init(-0.5, -0.5, 0), max: .init(0.5, 0.5, 0)))
        ])
    }

    mutating func update(_ rateMap: MTLRasterizationRateMap) {
        guard let buffer = commandQueue.makeCommandBuffer(),
              let encoder = buffer.makeComputeCommandEncoder() else {
            return
        }

        update(rateMap, textureSize: rateMap.screenSize, using: buffer, computeEncoder: encoder)

        encoder.endEncoding()
        buffer.commit()
    }

    func updateParams(_ rateMap: MTLRasterizationRateMap,
                      textureSize: MTLSize) -> VRRMeshUpdateParams {
        var params = VRRMeshUpdateParams(from: rateMap,
                                         textureSize: textureSize)
        params.positionOffset = self.positionOffset

        if !unwarp {
            params.showPhysical = 1
            params.physicalSizeUsed = params.physicalSizeTotal
        }

        return params
    }

    mutating func update(_ rateMap: MTLRasterizationRateMap,
                         textureSize: MTLSize,
                         using commandBuffer: MTLCommandBuffer,
                         computeEncoder: MTLComputeCommandEncoder) {
        var params = updateParams(rateMap, textureSize: textureSize)

        updateVertices(params: &params, rateMap: rateMap, using: commandBuffer, computeEncoder: computeEncoder)
        updateIndices(params: &params, using: commandBuffer, computeEncoder: computeEncoder)
    }

    mutating func updateVertices(params: inout VRRMeshUpdateParams,
                                 rateMap: MTLRasterizationRateMap,
                                 using commandBuffer: MTLCommandBuffer,
                                 computeEncoder: MTLComputeCommandEncoder) {
        let info = rateMap.parameterDataSizeAndAlign
        let buffer = rateMap.device.makeBuffer(length: info.size, options: .storageModeShared)!
        rateMap.copyParameterData(buffer: buffer, offset: 0)

        // Update Vertices
        computeEncoder.setBuffer(buffer, offset: 0, index: 0)
        computeEncoder.setBytes(&params, length: MemoryLayout.size(ofValue: params), index: 1)
        computeEncoder.setBuffer(mesh.replace(bufferIndex: 0, using: commandBuffer), offset: 0, index: 2)

        computeEncoder.setComputePipelineState(Self.updateMeshPipeline)
        computeEncoder.dispatchThreads(
            MTLSize(width: Int(params.verticesInGrid.x),
                    height: Int(params.verticesInGrid.y),
                    depth: 1),
            threadsPerThreadgroup: MTLSize(width: 32, height: 32, depth: 1)
        )
    }

    mutating func updateIndices(
        params: inout VRRMeshUpdateParams,
        using commandBuffer: MTLCommandBuffer,
        computeEncoder: MTLComputeCommandEncoder
    ) {
        // Update Indices
        computeEncoder.setBytes(&params, length: MemoryLayout.size(ofValue: params), index: 0)
        computeEncoder.setBuffer(mesh.replaceIndices(using: commandBuffer), offset: 0, index: 1)

        computeEncoder.setComputePipelineState(Self.updateIndicesPipeline)
        computeEncoder.dispatchThreads(
            MTLSize(
                width: Int(params.tilesInGrid.x),
                height: Int(params.tilesInGrid.y),
                depth: 1
            ),
            threadsPerThreadgroup: MTLSizeMake(32, 32, 1)
        )

        let indexCount = params.tilesInGrid.x * params.tilesInGrid.y * 6
        mesh.parts[0].indexCount = Int(indexCount)
        mesh.parts[0].bounds = .init(center: .zero,
                                     extents: .init(params.widthMultiplier, params.heightMultiplier, 0.0))
    }
}
