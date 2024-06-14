/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that receives input events and uses them to style points for the sparkle brush.
*/

/// Receives input events and generates a `SparkleBrushCurvePoint` for that event.
///
/// "Drawing Styles" can modify attributes such as color as the curve is drawn.
struct SparkleBrushStyleProvider {
    struct Settings: Equatable, Hashable {
        var initialSpeed: Float = 0.012
        var size: Float = 0.0002
        var color: SIMD3<Float> = [1, 1, 1]
    }
    
    func styleInput(position: SIMD3<Float>, speed: Float, settings: Settings) -> SparkleBrushCurvePoint {
        return SparkleBrushCurvePoint(position: position,
                                      initialSpeed: settings.initialSpeed,
                                      size: settings.size,
                                      color: settings.color)
    }
}
