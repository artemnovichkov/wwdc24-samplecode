/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for generating sample code artwork.
*/

import SwiftUI

let colors: [Color] = [
    .red,
    .orange,
    .yellow,
    .green,
    .teal,
    .mint,
    .cyan,
    .blue,
    .indigo,
    .purple,
    .pink,
    .brown,
    .gray
]

extension CGSize {
    static var moviePosterSize: Self { .init(width: 250, height: 375) }
    static var albumArtSize: Self { .init(width: 308, height: 308) }
    static var appIconSize: Self { .init(width: 400, height: 240) }
    static var topShelfSize: Self { .init(width: 360, height: 60) }
}

struct CodeSampleArtwork: View {
    var size: CGSize
    var color: Color

    init(size: CGSize = .init(width: 400, height: 240)) {
        self.size = size
        self.color = colors.randomElement()!
    }

    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .fill(color.gradient)
                .saturation(0.8)
                .aspectRatio(size.width / size.height, contentMode: .fill)

            Text("{ }")
                .font(.system(size: 160, design: .rounded))
                .minimumScaleFactor(0.2)
                .foregroundColor(.white)
                .offset(y: -10)

        }
    }
}

#Preview("AppIcon") {
    CodeSampleArtwork()
}

#Preview("MoviePoster") {
    CodeSampleArtwork(size: .init(width: 250, height: 375))
}

#Preview("AlbumCover") {
    CodeSampleArtwork(size: .init(width: 308, height: 308))
}
