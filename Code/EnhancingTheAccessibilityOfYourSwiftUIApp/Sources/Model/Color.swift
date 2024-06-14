/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for a color.
*/

import SwiftUI

struct CodableColor: Codable {
    var red: Float
    var green: Float
    var blue: Float

    var color: SwiftUI.Color {
        SwiftUI.Color(
            red: Double(red), green: Double(green), blue: Double(blue))
    }
}

struct CodableGradient: Codable {
    var first: CodableColor
    var second: CodableColor

    var gradient: Gradient {
        Gradient(colors: [first.color, second.color])
    }
}

extension Color.Resolved {
    var resolvedCodableColor: CodableColor {
        .init(red: red, green: green, blue: blue)
    }
}

extension Color {
    var primaryMix: Color {
        mix(with: .primary, by: 0.15)
    }
}
