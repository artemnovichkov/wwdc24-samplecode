/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
2D signed distance functions, used for the splash screen background.
*/

/*
 * Copyright 2024 Inigo Quilez
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of 
 * the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#pragma once

#include <metal_stdlib>
 
// Returns the distance from a point p to line segment a <-> b.
// https://iquilezles.org/articles/distfunctions2d/
inline float distance_to_line_segment(float2 p, float2 a, float2 b)
{
    using namespace metal;
    
    float2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// Returns the distance from a point p to a box with rounded corners.
// https://iquilezles.org/articles/distfunctions2d/
//
// b.x = width
// b.y = height
// r.x = roundness top-right
// r.y = roundness bottom-right
// r.z = roundness top-left
// r.w = roundness bottom-left
inline float signed_distance_to_rounded_box(float2 p, float2 b, float4 r)
{
    using namespace metal;
    
    r.xy = (p.x > 0.0) ? r.xy : r.zw;
    r.x  = (p.y > 0.0) ? r.x : r.y;
    float2 q = abs(p) - b + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}
