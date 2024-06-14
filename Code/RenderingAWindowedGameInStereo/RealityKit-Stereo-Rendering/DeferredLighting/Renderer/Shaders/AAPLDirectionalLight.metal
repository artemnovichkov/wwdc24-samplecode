/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal shaders used to render deferred directional lighting.
*/

#include <metal_stdlib>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands.
#include "AAPLShaderTypes.h"

// Include header shared between all Metal shader code files.
#include "AAPLShaderCommon.h"

struct QuadInOut
{
    float4 position [[position]];
#if USE_EYE_DEPTH
    float3 eye_position;
#endif
};

vertex QuadInOut
deferred_direction_lighting_vertex(constant AAPLSimpleVertex * vertices  [[ buffer(AAPLBufferIndexMeshPositions) ]],
                                   constant AAPLFrameData    & frameData [[ buffer(AAPLBufferFrameData) ]],
                                   uint                        vid       [[ vertex_id ]])
{
    QuadInOut out;

    out.position = float4(vertices[vid].position, 0, 1);

#if USE_EYE_DEPTH
    float4 unprojected_eye_coord = frameData.projection_matrix_inverse * out.position;
    out.eye_position = unprojected_eye_coord.xyz / unprojected_eye_coord.w;
#endif

    return out;
}

half4
deferred_directional_lighting_fragment_common(QuadInOut                in,
                                              constant AAPLFrameData & frameData,
                                              float                    depth,
                                              half4                    normal_shadow,
                                              half4                    albedo_specular)
{

    half sun_diffuse_intensity = dot(normal_shadow.xyz, half3(frameData.sun_eye_direction.xyz));

    sun_diffuse_intensity = max(sun_diffuse_intensity, 0.h);

    half3 sun_color = half3(frameData.sun_color.xyz);

    half3 diffuse_contribution = albedo_specular.xyz * sun_diffuse_intensity * sun_color;

    // Calculate specular contribution from directional light.

#if USE_EYE_DEPTH

    // Used `eye_space` depth to determine the position of the fragment in `eye_space`.
    float3 eye_space_fragment_pos = normalize(in.eye_position) * depth;

#else // IF NOT USE_EYE_DEPTH

    // Use screen space position and depth with the inverse projection matrix to determine
    // the position of the fragment in eye space.
    uint2 screen_space_position = uint2(in.position.xy);

    float2 normalized_screen_position;

    normalized_screen_position.x = 2.0  * ((screen_space_position.x/(float)frameData.framebuffer_width) - 0.5);
    normalized_screen_position.y = 2.0  * ((1.0 - (screen_space_position.y/(float)frameData.framebuffer_height)) - 0.5);

    float4 ndc_fragment_pos = float4 (normalized_screen_position.x,
                                     normalized_screen_position.y,
                                     depth,
                                     1.0f);

    ndc_fragment_pos = frameData.projection_matrix_inverse * ndc_fragment_pos;

    float3 eye_space_fragment_pos = ndc_fragment_pos.xyz / ndc_fragment_pos.w;

#endif // END not USE_EYE_DEPTH

    float4 eye_light_direction = frameData.sun_eye_direction;

    // Specular Contribution
    float3 halfway_vector = normalize(eye_space_fragment_pos - eye_light_direction.xyz );

    half specular_intensity = half(frameData.sun_specular_intensity);

    half specular_shininess = albedo_specular.w * half(frameData.shininess_factor);

    half specular_factor = powr(max(dot(half3(normal_shadow.xyz),half3(halfway_vector)),0.0h), specular_intensity);

    half3 specular_contribution = specular_factor * half3(albedo_specular.xyz) * specular_shininess * sun_color;

    half3 color = diffuse_contribution + specular_contribution;

    // Shadow Contribution
    half shadowSample = normal_shadow.w;

    // Lighten the shadow to account for some ambience.
    shadowSample += .1h;

    // Account for values greater than 1.0 (after lightening the shadow).
    shadowSample = saturate(shadowSample);

    color *= shadowSample;

    return half4(color, 1);
}

// Only Version 2.3 of the macOS Metal shading language, where Apple Silicon was introduced,
// and the iOS version of the shading language can use the `GBufferData` structure as an input.
#if __METAL_VERSION__ >= 230 ||  defined(__METAL_IOS__)

fragment AccumLightBuffer
deferred_directional_lighting_fragment_single_pass(
    QuadInOut                in        [[ stage_in ]],
    constant AAPLFrameData & frameData [[ buffer(AAPLBufferFrameData) ]],
    GBufferData              GBuffer)
{
    AccumLightBuffer output;
    output.lighting =
        deferred_directional_lighting_fragment_common(in, frameData, GBuffer.depth,  GBuffer.normal_shadow,  GBuffer.albedo_specular);

    return output;
}

#endif // __METAL_VERSION__ >= 230 ||  defined(__METAL_IOS__)

fragment half4
deferred_directional_lighting_fragment_traditional(
    QuadInOut                in                      [[ stage_in ]],
    constant AAPLFrameData & frameData               [[ buffer(AAPLBufferFrameData) ]],
    texture2d<half>          albedo_specular_GBuffer [[ texture(AAPLRenderTargetAlbedo) ]],
    texture2d<half>          normal_shadow_GBuffer   [[ texture(AAPLRenderTargetNormal) ]],
    texture2d<float>         depth_GBuffer           [[ texture(AAPLRenderTargetDepth)  ]])
{
    uint2 position = uint2(in.position.xy);

    float depth = depth_GBuffer.read(position.xy).x;
    half4 normal_shadow = normal_shadow_GBuffer.read(position.xy);
    half4 albedo_specular = albedo_specular_GBuffer.read(position.xy);

    return deferred_directional_lighting_fragment_common(in, frameData, depth, normal_shadow, albedo_specular);
}
