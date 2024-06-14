/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A styled point to be passed to the `SparkleDrawingMeshGenerator`.
  A list of these defines the curve of a sparkle brush stroke.
*/

/// `SparkleBrushCurvePoints` are emitted by the `SparkleBrushStyleProvider` and consumed by the `SparkleDrawingMeshGenerator`.
///
/// These are the styled points on the curve of points to be meshed by the `SparkleDrawingMeshGenerator`.
struct SparkleBrushCurvePoint {
    /// Position of this point.
    var position: SIMD3<Float>
    
    /// Initial speed of particles emitted from this point.
    var initialSpeed: Float
    
    /// Size of particles emitted from this point.
    var size: Float
    
    /// Color of particles emitted from this point.
    var color: SIMD3<Float>
    
    init(position: SIMD3<Float>, initialSpeed: Float, size: Float, color: SIMD3<Float>) {
        self.position = position
        self.initialSpeed = initialSpeed
        self.size = size
        self.color = color
    }
}

/// Interpolate between two `SparkleBrushCurvePoints` by the blend value `blend`.
///
/// - Parameters:
///   - point0: The first point to interpolate, corresponding with `blend == 0`.
///   - point1: The second point to interpolate, corresponding with `blend == 1`.
///   - blend: The blend of the interpolation, typically ranging from 0 to 1.
func mix(_ point0: SparkleBrushCurvePoint, _ point1: SparkleBrushCurvePoint, t blend: Float) -> SparkleBrushCurvePoint {
    return SparkleBrushCurvePoint(position: mix(point0.position, point1.position, t: blend),
                                  initialSpeed: mix(point0.initialSpeed, point1.initialSpeed, t: blend),
                                  size: mix(point0.size, point1.size, t: blend),
                                  color: mix(point0.color, point1.color, t: blend))
}
