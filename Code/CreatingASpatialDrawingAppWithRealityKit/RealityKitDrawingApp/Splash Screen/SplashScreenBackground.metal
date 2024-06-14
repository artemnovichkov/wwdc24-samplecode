/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A compute kernel written in Metal Shading Language which is displayed on the splash screen when launching the app.
*/

#include <metal_stdlib>

#include "DistanceFunctions.h"

using namespace metal;

constexpr constant float capsule_radius = 0.08;
constexpr constant float padding = 0.04;

constexpr constant uint8_t capsule_count_per_row = 8;
constexpr constant float x_lengths_per_capsule[capsule_count_per_row] = { 0.1, 0.15, 0.06, 0.18, 0.1, 0.07, 0.11, 0.08 };
constexpr constant float x_lengths_per_capsule_sum = 0.85; // sum of all x_lengths_per_capsule
constexpr constant float x_modulo = x_lengths_per_capsule_sum + (padding + capsule_radius * 2) * capsule_count_per_row;

constexpr constant uint8_t row_count = 10;
constexpr constant float2 x_offsets_and_speeds_per_row[row_count] = {
    float2 { 2.4523, 0.03 },
    float2 { 6.123, 0.1 },
    float2 { 0.2, 0.054 },
    float2 { 0.4, 0.07 },
    float2 { 0.8, 0.045 },
    float2 { 1.45, 0.09 },
    float2 { 0, 0.11 },
    float2 { 0.12, 0.075 },
    float2 { 0.5, 0.065 },
    float2 { 1, 0.06 } };

inline float signed_distance_to_capsule(float2 p, float2 a, float2 b, float r)
{
    return distance_to_line_segment(p, a, b) - r;
}

inline float signed_distance_union(float d0, float d1)
{
    return min(d0, d1);
}

inline float capsule_row(float2 point)
{
    float sdf = 9999;
    float x_offset = capsule_radius;
    for (float capsule_length : x_lengths_per_capsule) {
        float2 t = point - float2 { x_offset, 0 };
        t.x -= x_modulo * round(t.x / x_modulo);
        
        float capsule_sdf = signed_distance_to_capsule(t, 0,
                                                       float2 { capsule_length, 0 },
                                                       capsule_radius);
        x_offset += capsule_length + padding + capsule_radius * 2;
        sdf = signed_distance_union(sdf, capsule_sdf);
    }
    return sdf;
}

float capsule_field(float2 p, float2 frame_extents, float time)
{
    constexpr float warp = 0.15;
    p.y += precise::sin(p.x * 1.6) * warp;
    
    float sdf = 9999;
    float y_offset = -frame_extents.y / 2 - capsule_radius - warp;
    for (float2 x_offset_and_speed : x_offsets_and_speeds_per_row) {
        float x_offset = x_offset_and_speed.x;
        float x_speed = x_offset_and_speed.y;
        
        float row_sdf = capsule_row(p - float2 { x_offset - x_speed * time, y_offset });
        sdf = signed_distance_union(row_sdf, sdf);
        y_offset += capsule_radius * 2 + padding;
    }
    return sdf;
}

kernel void
splashScreenBackgroundKernel(texture2d<float, access::write>  outTexture     [[texture(0)]],
                             constant float                  &time           [[buffer(0)]],
                             uint2                            gid            [[thread_position_in_grid]])
{
    const float width = outTexture.get_width();
    const float height = outTexture.get_height();
    const float2 pixel = float2 { float(gid[0]), float(height - gid[1]) };
    
    const float pixel_to_frame = 1.3f / min(width, height);
    const float2 frame_extents = float2 { width, height } * pixel_to_frame;
    const float2 frame_center = frame_extents / 2;
    
    float2 position = pixel * pixel_to_frame - frame_center;
    float sdf = capsule_field(position, frame_extents, time);
    float out_red = saturate((sdf + capsule_radius) / (2 * capsule_radius));
    
    float fade_sdf = signed_distance_to_rounded_box(position, frame_extents / 2, 0.5);
    float out_green = smoothstep(0.f, 1.f, saturate(fade_sdf / -0.6f));
    
    float4 outColor { out_red, out_green, 0, 0 };
    outTexture.write(outColor, gid);
}
