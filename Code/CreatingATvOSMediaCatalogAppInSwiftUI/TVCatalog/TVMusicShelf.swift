/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a shelf of items that represent album covers.
*/

import SwiftUI

let titles: [String] = [
    "Mercury", "Venus", "Terra", "Mars", "Jupiter", "Saturn", "Neptune",
    "Uranus", "Pluto", "Charon", "Io", "Iapetus", "Triton", "Europa",
    "Ganymede", "Phobos", "Deimos", "Ceres"
]

struct TVMusicShelf: View {
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 40) {
                ForEach(0..<20) { _ in
                    Button {} label: {
                        CodeSampleArtwork(size: .albumArtSize)
                            .hoverEffect(.highlight)
                        Text(titles.randomElement()!)
                            .visibleWhenFocused()
                    }
                    .containerRelativeFrame(.horizontal, count: 5, spacing: 40)
                }
            }
        }
        .scrollClipDisabled()
        .buttonStyle(.borderless)
    }
}

#Preview {
    TVMusicShelf()
}
