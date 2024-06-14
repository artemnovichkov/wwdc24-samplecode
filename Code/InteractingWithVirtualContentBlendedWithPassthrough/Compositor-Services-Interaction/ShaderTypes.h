/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and Swift/ObjC source.
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

#include <simd/simd.h>

typedef NS_ENUM(EnumBackingType, BufferIndex)
{
    BufferIndexMeshPositions = 0,
    BufferIndexUniforms      = 1,
    BufferIndexTintUniforms = 2,
    BufferIndexCount
};

typedef NS_ENUM(EnumBackingType, VertexAttribute)
{
    VertexAttributePosition = 0,
    VertexAttributeColor = 1,
};

typedef struct {
    matrix_float4x4 modelViewProjectionMatrix;
} UniformsPerView;

typedef struct
{
    UniformsPerView perView[2];
    simd_float3     cameraPos;
} Uniforms;

typedef struct
{
    float tintOpacity;
} TintUniforms;

typedef struct
{
    simd_float3 position;
    simd_float3 color;
} Vertex;

#endif /* ShaderTypes_h */
