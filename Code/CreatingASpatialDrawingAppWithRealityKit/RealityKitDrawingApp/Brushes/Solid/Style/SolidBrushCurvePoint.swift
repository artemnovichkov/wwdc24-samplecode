/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A styled point to be passed to the `SmoothCurveSampler`.
  A list of these defines the curve of a solid brush stroke.
*/

import CoreGraphics

/// An object that represents points that a solid brush style provider emits,
/// and a smooth curve sampler consumes.
struct SolidBrushCurvePoint {
    var position: SIMD3<Float>
    
    var radius: Float
    
    var color: SIMD3<Float>
    
    var roughness: Float
    
    var metallic: Float

    var positionAndRadius: SIMD4<Float> { .init(position, radius) }
    
    init(position: SIMD3<Float>, radius: Float, color: SIMD3<Float>, roughness: Float, metallic: Float) {
        self.position = position
        self.radius = radius
        self.color = color
        self.roughness = roughness
        self.metallic = metallic
    }
    
    init(positionAndRadius par: SIMD4<Float>, color: SIMD3<Float>, roughness: Float, metallic: Float) {
        self.position = SIMD3(par.x, par.y, par.z)
        self.radius = par.w
        self.color = color
        self.roughness = roughness
        self.metallic = metallic
    }
}

/// Interpolates between two solid brush curve points by a blend value.
///
/// - Parameters:
///   - point0: The first point to interpolate, corresponding with `blend == 0`.
///   - point1: The second point to interpolate, corresponding with `blend == 1`.
///   - blend: The blend of the interpolation, typically ranging from 0 to 1.
func mix(
    _ point0: SolidBrushCurvePoint, _ point1: SolidBrushCurvePoint, t blend: Float
) -> SolidBrushCurvePoint {
    SolidBrushCurvePoint(position: mix(point0.position, point1.position, t: blend),
                         radius: mix(point0.radius, point1.radius, t: blend),
                         color: mix(point0.color, point1.color, t: blend),
                         roughness: mix(point0.roughness, point1.roughness, t: blend),
                         metallic: mix(point0.metallic, point1.metallic, t: blend))
}
