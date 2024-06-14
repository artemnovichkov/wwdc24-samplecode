/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Style settings for the solid brush type.
*/

import Foundation
import Collections
import SwiftUI

/// Receives input events and generates a `SolidBrushCurvePoint` for that event.
///
/// "Drawing Styles" can modify attributes such as color or radius as the curve is drawn.
/// For example, a calligraphic style can vary the radius depending on how quickly the brush is stroked.
struct SolidBrushStyleProvider {
    enum ThicknessType: Equatable, Hashable {
        case uniform
        
        /// - Parameters:
        ///   - viscosity: The variation in thickness the brush can vary.
        ///     This is a fraction of thickness, in the closed range `[0, 1]`.
        ///   - sensitivity: The speed in meters per second a person must draw to make the brush 50 percent wide.
        ///   - response: The difference in speed, in meters per second, to go from 50 percent brush width to 100 percent.
        case calligraphic(viscosity: Float = 0.6, sensitivity: Float = 0.755, response: Float = 0.745)
    }
    
    struct Settings: Equatable, Hashable {
        var thickness: Float = 0.005
        var thicknessType: ThicknessType = .uniform
        
        var color: SIMD3<Float> = [1, 1, 1]
        var metallic: Float = 0
        var roughness: Float = 0.5
        
        func radius(forSpeed speed: Float) -> Float {
            switch thicknessType {
            case .uniform:
                return thickness
            case let .calligraphic(viscosity, sensitivity, response):
                let radiusBlend = 1.0 - smoothstep(speed,
                                                   minEdge: sensitivity - response,
                                                   maxEdge: sensitivity + response)
                return mix(max(0.001, (1.0 - viscosity) * thickness),
                           (1.0 + viscosity) * thickness,
                           t: radiusBlend)
            }
        }
    }
    
    func styleInput(position: SIMD3<Float>, speed: Float, settings: Settings) -> SolidBrushCurvePoint {
        SolidBrushCurvePoint(position: position,
                             radius: settings.radius(forSpeed: speed),
                             color: settings.color,
                             roughness: settings.roughness,
                             metallic: settings.metallic)
    }
}
