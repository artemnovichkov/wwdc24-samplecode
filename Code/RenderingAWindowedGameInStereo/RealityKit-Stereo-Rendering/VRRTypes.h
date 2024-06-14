/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Types used by the VRRMesh.
*/

#pragma once

#include <simd/simd.h>

struct VRRVertex
{
    simd_float3 position;
    simd_float2 uv0;
};

struct VRRMeshUpdateParams
{
    simd_float3 positionOffset;
    
    simd_uint2 verticesInGrid;
    simd_uint2 tilesInGrid;

    simd_uint2 screenSize;
    simd_uint2 physicalGranularity;
    simd_uint2 physicalSizeUsed;
    simd_uint2 physicalSizeTotal;

    uint showPhysical;

    // Derived parameters.
    simd_float2 invScreenSize;
    simd_float2 invPhysicalSizeTotal;
    simd_float2 sizeScale;
};
