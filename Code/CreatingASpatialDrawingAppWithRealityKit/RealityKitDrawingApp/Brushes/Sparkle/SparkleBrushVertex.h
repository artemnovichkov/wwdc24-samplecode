/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Vertex data for the sparkle brush style, written in Metal Shading Language.
*/

#pragma once

#include "../../Utilities/MetalPacking.h"
#include <simd/simd.h>

#pragma pack(push, 1)
struct SparkleBrushAttributes {
    packed_float3 position;
    packed_half3 color;
    float curveDistance;
    float size;
};

struct SparkleBrushParticle {
    struct SparkleBrushAttributes attributes;
    packed_float3 velocity;
};

struct SparkleBrushVertex {
    struct SparkleBrushAttributes attributes;
    simd_half2 uv;
};

struct SparkleBrushSimulationParams {
    uint32_t particleCount;
    float deltaTime;
    float dragCoefficient;
};
#pragma pack(pop)

static_assert(sizeof(struct SparkleBrushAttributes) == 26, "ensure packing");
static_assert(sizeof(struct SparkleBrushParticle) == 38, "ensure packing");
static_assert(sizeof(struct SparkleBrushVertex) == 30, "ensure packing");
static_assert(sizeof(struct SparkleBrushSimulationParams) == 12, "ensure packing");
