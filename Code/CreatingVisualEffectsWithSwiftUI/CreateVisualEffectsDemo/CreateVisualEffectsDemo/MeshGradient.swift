/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A simple mesh gradient.
*/

import SwiftUI

#Preview {
    MeshGradient(
        width: 3,
        height: 3,
        points: [
            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
            [0.0, 0.5], [0.8, 0.2], [1.0, 0.5],
            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
        ], colors: [
            .black, .black, .black,
            .blue, .blue, .blue,
            .green, .green, .green
        ])
        .edgesIgnoringSafeArea(.all)
}
