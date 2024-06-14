/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example of using the `Stripes` shader as a `ShapeStyle`.
*/

import SwiftUI

#Preview("Stripes") {
    VStack {
        let fill = ShaderLibrary.Stripes(
            .float(12),
            .colorArray([
                .red, .orange, .yellow, .green, .blue, .indigo
            ])
        )

        Circle().fill(fill)
    }
    .padding()
}
