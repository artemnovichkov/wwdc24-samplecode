/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data to represent the shape of the curve at a given point.
*/

import simd

/// An object that represents points that a smooth curve sampler emits.
///
/// It is a point along a curve originally defined as a `CurvePoint`,
/// but smoothed into a Catmull-Rom spline.
struct CurveSample {
    /// Point data at this sample (position, radius, and so on).
    ///
    /// This is interpolated between two `CurvePoint` items, which were passed to the `SmoothCurveSampler`.
    var point: SolidBrushCurvePoint

    /// The parameter of this sample along the Catmull-Rom spline.
    ///
    /// See ``SmoothCurveSampler``.
    var parameter: Float
    
    var rotationFrame: simd_float3x3
    
    /// The distance along the spline of this sample.
    ///
    /// For example, this value is 0 if this is the first sample on the curve.
    var curveDistance: Float
    
    /// The position of this sample point.
    var position: SIMD3<Float> {
        get { return point.position }
        set { point.position = newValue }
    }
    
    var tangent: SIMD3<Float> { rotationFrame.columns.2 }
    
    /// The radius of this sample point.
    var radius: Float {
        get { return point.radius }
        set { point.radius = newValue }
    }
    
    init(point: SolidBrushCurvePoint, parameter: Float = 0, rotationFrame: simd_float3x3 = .init(diagonal: .one), curveDistance: Float = 0) {
        self.point = point
        self.parameter = parameter
        self.rotationFrame = rotationFrame
        self.curveDistance = curveDistance
    }
    
    init() {
        self.init(point: SolidBrushCurvePoint(
            position: .zero, radius: .zero, color: .zero,
            roughness: .zero, metallic: .zero
        ))
    }
}
