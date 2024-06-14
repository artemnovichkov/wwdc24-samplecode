/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a shelf of movies.
*/

import SwiftUI

struct MovieShelf: View {
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 40) {
                ForEach(Asset.allCases) { asset in
                    Button {} label: {
                        asset.portraitImage
                            .resizable()
                            .aspectRatio(250 / 375, contentMode: .fit)
                            .containerRelativeFrame(.horizontal, count: 6, spacing: 40)
                        Text(asset.title)
                    }
                }
            }
        }
        .scrollClipDisabled()
        .buttonStyle(.borderless)
    }
}

#Preview {
    MovieShelf()
}
