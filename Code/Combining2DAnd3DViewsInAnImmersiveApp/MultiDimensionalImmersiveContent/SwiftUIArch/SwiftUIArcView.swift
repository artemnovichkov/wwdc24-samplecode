/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates an arc shape in a SwiftUI view.
*/

import SwiftUI

/// A SwiftUI view containing a custom `Arc` shape.
struct SwiftUIArcView: View {
    let color: Color
  
    var body: some View {
            Arc(centerAngle: .degrees(-90))
                .fill(color)
    }
}

// MARK: - Arc
/// A custom Arc shape you create from a `UIBezierPath`.
struct Arc: Shape {
    var centerAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        return Path(UIBezierPath.createArcWithPath(bounds: rect, centerAngle: centerAngle.radians).cgPath)
    }
}

