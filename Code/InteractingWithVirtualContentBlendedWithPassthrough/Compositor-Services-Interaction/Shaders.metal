/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contains the vertex and fragment shaders for the path and tint renderers.
*/

#include <metal_stdlib>
#include <simd/simd.h>

// Include header shared between this Metal shader code and Swift/C code executing Metal API commands.
#import "ShaderTypes.h"
#import "PathProperties.h"

using namespace metal;

float3 catmullRomPosition(float3 p0, float3 p1, float3 p2, float3 p3, float t) 
{
    float t2 = t * t;
    float t3 = t2 * t;
    
    float3 a = (-0.5 * p0) + (1.5 * p1) - (1.5 * p2) + (0.5 * p3);
    float3 b = p0 - (2.5 * p1) + (2 * p2) - (0.5 * p3);
    float3 c = (-0.5 * p0) + (0.5 * p2);
    float3 d = p1;
    
    return (a * t3) + (b * t2) + (c * t) + d;
}

float3 catmullRomTangent(float3 p0, float3 p1, float3 p2, float3 p3, float t) 
{
    float t2 = t * t;
    
    float3 a = (-1.5 * p0) + (4.5 * p1) - (4.5 * p2) + (1.5 * p3);
    float3 b = (2 * p0) - (5 * p1) + (4 * p2) - p3;
    float3 c = (-0.5 * p0) + (0.5 * p2);
    
    return normalize((3 * a * t2) + (2 * b * t) + c);
}

typedef struct
{
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float3 tangent;
    float3 bitangent;
    float2 texCoord;
    int pointIndex;
} PathColorInOut;

vertex PathColorInOut pathVertexFunction(uint vertexID [[vertex_id]],
                                         ushort viewID [[amplification_id]],
                                         constant Uniforms & uniforms [[buffer(BufferIndexUniforms)]],
                                         constant PathPoint * pathPositions [[buffer(PathPropertiesBufferIndexPositions)]],
                                         constant PathProperties & pathProperties [[buffer(PathPropertiesBufferIndexParameters)]])
{
    PathColorInOut out;
    
    UniformsPerView uniformsPerView = uniforms.perView[viewID];
    
    int pointIndex = vertexID / pathProperties.verticesPerSegment;
    float progressPerVertex = (1.0 / float(pathProperties.verticesPerSegment));
    float progress = (vertexID % pathProperties.verticesPerSegment) * progressPerVertex;
    
    PathPoint p0 = pathPositions[pointIndex];
    PathPoint p1 = pathPositions[pointIndex + 1];
    PathPoint p2 = pathPositions[pointIndex + 2];
    PathPoint p3 = pathPositions[pointIndex + 3];
    
    float3 pathCenter = catmullRomPosition(p0.position, p1.position, p2.position, p3.position, progress);
    float3 tangent = catmullRomTangent(p0.position, p1.position, p2.position, p3.position, progress);
    
    // Use the stored camera position to keep the normal consistent over time.
    float3 cameraPos = catmullRomPosition(p0.cameraPosition, p1.cameraPosition, p2.cameraPosition, p3.cameraPosition, progress);
    
    float3 cameraDirection = normalize(cameraPos - pathCenter);
    float3 normal = normalize(cross(tangent, cameraDirection));
    float3 bitangent = normalize(cross(tangent, normal));
    
    float rampSegments = 2.0; // Number of segments for the initial ramp.
    float radiusRamp = min((pointIndex + progress) / rampSegments, 1.0);
    float radius = radiusRamp * pathProperties.radius;
    
    float3 offset = (((vertexID % 2) - 0.5) * radius * normal);
    float4 position = float4(pathCenter + offset, 1.0);
    
    out.bitangent = bitangent;
    out.tangent = tangent;
    out.normal = normal;
    out.worldPosition = position.xyz;
    out.position = uniformsPerView.modelViewProjectionMatrix * position;
    out.texCoord = float2(progress, vertexID % 2);
    
    return out;
}

fragment float4 pathFragmentFunction(PathColorInOut in [[stage_in]],
                                     constant Uniforms & uniforms [[buffer(BufferIndexUniforms)]],
                                     constant PathProperties & parameters [[buffer(PathPropertiesBufferIndexParameters)]],
                                     texture2d<half> pathColor [[texture(PathPropertiesTextureIndexColor)]])
{
    if (parameters.opacity <= 0.0) {
        discard_fragment();
    }
    
    constexpr sampler linearSampler (mip_filter::linear, mag_filter::linear, min_filter::linear);
    
    float3 colorSample = float3(pathColor.sample(linearSampler, in.texCoord.xy).xyz);
    // Premultiply color channel by alpha channel.
    float4 color = float4(colorSample * parameters.color * parameters.opacity, parameters.opacity);

    return color;
}

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float3 color [[attribute(VertexAttributeColor)]];
} VertexIn;

typedef struct
{
    float4 position [[position]];
    float4 color;
} TintInOut;

vertex TintInOut tintVertexShader(VertexIn in [[stage_in]],
                                  ushort amp_id [[amplification_id]],
                                  constant Uniforms & uniformsArray [[ buffer(BufferIndexUniforms) ]],
                                  constant TintUniforms & tintUniform [[ buffer(BufferIndexTintUniforms) ]])
{
    TintInOut out;

    UniformsPerView uniformsPerView = uniformsArray.perView[amp_id];
    
    float4 position = float4(in.position, 1.0);
    out.position = uniformsPerView.modelViewProjectionMatrix * position;
    out.color = float4(in.color, tintUniform.tintOpacity);
    // Premultiply color channel by alpha channel.
    out.color.rgb = out.color.rgb * out.color.a;

    return out;
}

fragment float4 tintFragmentShader(TintInOut in [[stage_in]])
{
    if (in.color.a <= 0.0) {
        discard_fragment();
    }

    return in.color;
}
