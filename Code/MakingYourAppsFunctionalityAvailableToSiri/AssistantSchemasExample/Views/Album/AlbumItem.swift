/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A row in the album grid.
*/

import AppIntents
import SwiftUI

struct AlbumItem: View, Sendable {

    // MARK: Properties

    let album: Album

    @State private var image: Image?

    // MARK: Lifecycle

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                if let image {
                    image
                        .resizable()
                        .blur(radius: 4)
                } else {
                    Rectangle()
                }

                HStack(alignment: .top) {
                    Text(album.title)
                        .font(.title)
                        .multilineTextAlignment(.leading)
                        .bold()
                    Spacer()
                    Text(album.assets.count.description)
                        .font(.title)
                        .opacity(0.75)
                }
                .foregroundColor(.white)
                .padding()
            }
            .cornerRadius(10)
            .padding(.horizontal)
            .onAppear {
                let targetSize = proxy.size
                Task.detached {
                    try await album.fetchAssets()
                    guard let asset = album.assets.first else {
                        return
                    }

                    let image = await ImageManager.shared.requestImage(for: asset, targetSize: targetSize)
                    await MainActor.run {
                        self.image = image
                    }
                }
            }
        }
        .frame(height: 200)
        .id(album)
        .tag(album)
    }
}
