/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Compute shader updating a Variable Rasterization Rates (VRR) mesh to unwrap and display a wrapped texture.
*/

#include <metal_stdlib>
#include <metal_graphics>

#include "VRRTypes.h"

using namespace metal;

[[kernel]]
void populateVRR(texture2d<float, access::write> outTexture [[ texture(0) ]],
                 constant rasterization_rate_map_data &vrrMap [[ buffer(0) ]],
                 constant simd_uint2 &screenSize [[ buffer(1) ]],
                 constant simd_uint2 &physicalSizeUsed [[ buffer(2) ]],
                 uint2 physicalCoord [[ thread_position_in_grid ]])
{
    rasterization_rate_map_decoder map(vrrMap);

    // Use `float2` version of VRR overloads instead of the `uint2` results, for ease-of-use.
    float2 screenCoord = map.map_physical_to_screen_coordinates(float2(physicalCoord), 0);

    // Green outside the physical area.
    if (any(physicalCoord >= physicalSizeUsed)) {
        outTexture.write(float4(0.0,1.0,0.0,1.0), physicalCoord);
        return;
    }

    float2 uv = float2(screenCoord) / float2(screenSize);
    int2 gridCoord = int2(uv * 32);

    int2 pixelCoord = gridCoord; // int2(screenCoord / 16);
    if ((pixelCoord.x + pixelCoord.y) % 2 > 0) {
        outTexture.write(float4(uv.x,uv.y,0,1), physicalCoord);
    } else {
        outTexture.write(float4(0,0,0,1), physicalCoord);
    }
}

int indexOfVertex(uint2 tileIndex, uint2 verticesInGrid)
{
    return tileIndex.x + tileIndex.y * verticesInGrid.x;
}

[[kernel]]
void updateVRRMesh(constant rasterization_rate_map_data &vrrMap [[ buffer(0) ]],
                   constant VRRMeshUpdateParams &params [[buffer(1)]],
                   device VRRVertex *vertices [[buffer(2)]],
                   uint2 tileIndex [[ thread_position_in_grid ]],
                   uint2 gridSize [[ threads_per_grid ]])
{
    if (any(tileIndex >= params.verticesInGrid)) {
        return;
    }

    float2 pixelCoords = float2(min(tileIndex * params.physicalGranularity, params.physicalSizeUsed - 1));
    float2 screenCoords;

    if (params.showPhysical) {
        screenCoords = pixelCoords;
    } else {
        rasterization_rate_map_decoder map(vrrMap);
        screenCoords = map.map_physical_to_screen_coordinates(pixelCoords);
    }

    float3 position;
    position.x = ((screenCoords.x * params.invScreenSize.x) + params.positionOffset.x) * params.sizeScale.x;
    position.y = ((1.0 - screenCoords.y * params.invScreenSize.y) + params.positionOffset.y) * params.sizeScale.y;
    position.z = 0.0;

    float2 uv = pixelCoords * params.invPhysicalSizeTotal;
    uv.y = 1.0 - uv.y;

    int vertexIdx = indexOfVertex(tileIndex, params.verticesInGrid);

    vertices[vertexIdx] = {
        .position = position,
        .uv0 = uv
    };
}

[[kernel]]
void updateVRRIndices(constant VRRMeshUpdateParams &params [[buffer(0)]],
                      device uint32_t *indices [[buffer(1)]],
                      uint2 tileIndex [[ thread_position_in_grid ]])
{
    int v00 = indexOfVertex(tileIndex + uint2(0, 0), params.verticesInGrid);
    int v10 = indexOfVertex(tileIndex + uint2(1, 0), params.verticesInGrid);

    int v01 = indexOfVertex(tileIndex + uint2(0, 1), params.verticesInGrid);
    int v11 = indexOfVertex(tileIndex + uint2(1, 1), params.verticesInGrid);

    int baseIndex = (tileIndex.x + tileIndex.y * params.tilesInGrid.x) * 6;

    indices[baseIndex  ] = v00;
    indices[baseIndex+2] = v10;
    indices[baseIndex+1] = v11;

    indices[baseIndex+3] = v00;
    indices[baseIndex+5] = v11;
    indices[baseIndex+4] = v01;
}
