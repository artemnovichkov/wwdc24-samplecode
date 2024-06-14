/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for a single media asset.
*/

import AppIntents
import SwiftUI

struct AssetView: View, Sendable {

    // MARK: Properties

    let asset: Asset

    private let targetSize = CGSize(width: 100, height: 100)

    @State private var image: Image?

    // MARK: Lifecycle

    var body: some View {
        Group {
            if let image {
                ThumbnailView(image: image, type: asset.type, isFavorite: asset.isFavorite)
            } else {
                ProgressView()
                    .padding()
            }
        }
        .onAppear {
            Task.detached {
                let image = await ImageManager.shared.requestImage(for: asset, targetSize: targetSize)
                await MainActor.run {
                    self.image = image
                }

                try? await asset.fetchPlacemark()
            }
        }
        .id(asset)
        .tag(asset)
    }

    // MARK: Layout

    struct ThumbnailView: View {

        // MARK: Properties

        let image: Image
        let type: AssetType
        let isFavorite: Bool

        // MARK: Lifecycle

        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .center) {
                    image

                    if type == .video {
                        Image(systemName: "video.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                }

                FavoriteView(isFavorite: isFavorite)
            }
            .clipped()
            .cornerRadius(10)
        }
    }
}
