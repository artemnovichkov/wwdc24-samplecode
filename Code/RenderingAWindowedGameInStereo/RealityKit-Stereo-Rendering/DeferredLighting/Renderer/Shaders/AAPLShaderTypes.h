/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header that contains the types and enumeration constants shared between Metal shaders and the C and Swift source.
*/
#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h

#include "AAPLConfig.h"
#include <simd/simd.h>

#ifndef __METAL_VERSION__

#include <sys/types.h>

/// 96-bit 3-component float vector type.
typedef struct __attribute__ ((packed)) packed_float3 {
    float x;
    float y;
    float z;
} packed_float3;
#endif

// Buffer index values shared between the shader and C code to ensure Metal shader buffer inputs match
// Metal API buffer set calls.
typedef enum AAPLBufferIndices
{
    AAPLBufferIndexMeshPositions     = 0,
    AAPLBufferIndexMeshGenerics      = 1,
    AAPLBufferFrameData              = 2,
    AAPLBufferIndexLightsData        = 3,
    AAPLBufferIndexLightsPosition    = 4,

} AAPLBufferIndices;

// Attribute index values shared between the shader and C code to ensure Metal shader vertex
// attribute indices match the Metal API vertex descriptor attribute indices.
typedef enum AAPLVertexAttributes
{
    AAPLVertexAttributePosition  = 0,
    AAPLVertexAttributeTexcoord  = 1,
    AAPLVertexAttributeNormal    = 2,
    AAPLVertexAttributeTangent   = 3,
    AAPLVertexAttributeBitangent = 4
} AAPLVertexAttributes;

// Texture index values shared between the shader and C code to ensure Metal shader texture indices
// match indices of Metal API texture set calls.
typedef enum AAPLTextureIndices
{
	AAPLTextureIndexBaseColor = 0,
	AAPLTextureIndexSpecular  = 1,
	AAPLTextureIndexNormal    = 2,
    AAPLTextureIndexShadow    = 3,
    AAPLTextureIndexAlpha     = 4,

    AAPLNumMeshTextures = AAPLTextureIndexNormal + 1

} AAPLTextureIndices;

typedef enum AAPLRenderTargetIndices
{
    AAPLRenderTargetLighting  = 0,
    AAPLRenderTargetAlbedo    = 1,
    AAPLRenderTargetNormal    = 2,
    AAPLRenderTargetDepth     = 3
} AAPLRenderTargetIndices;

// Structures shared between the shader and C code to ensure the layout of data accessed in
// Metal shaders matches the layout of data set in the C code.

// Data constant across all threads, vertices, and fragments.
typedef struct
{
    // Per Frame frameData
    matrix_float4x4 projection_matrix;
    matrix_float4x4 projection_matrix_inverse;
    matrix_float4x4 view_matrix;
    uint framebuffer_width;
    uint framebuffer_height;

    // Per Mesh frameData
    matrix_float4x4 temple_modelview_matrix;
    matrix_float4x4 temple_model_matrix;
    matrix_float3x3 temple_normal_matrix;
    float shininess_factor;

    float fairy_size;
    float fairy_specular_intensity;

    matrix_float4x4 sky_modelview_matrix;
    matrix_float4x4 shadow_mvp_matrix;
    matrix_float4x4 shadow_mvp_xform_matrix;

    vector_float4 sun_eye_direction;
    vector_float4 sun_color;
    float sun_specular_intensity;
} AAPLFrameData;

// Per-light characteristics
typedef struct
{
    vector_float3 light_color;
    float light_radius;
    float light_speed;
} AAPLPointLight;

// Simple vertex used to render the "fairies".
typedef struct {
    vector_float2 position;
} AAPLSimpleVertex;

typedef struct {
    packed_float3 position;
} AAPLShadowVertex;

#endif /* AAPLShaderTypes_h */

