/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The grid view of loaded assets.
*/

import SwiftUI
import UniformTypeIdentifiers

struct AssetGrid: View {

    // MARK: Properties

    var assets: [Asset]

    let album: Album?

    private let targetSize = CGSize(width: 100, height: 100)

    private let columns = [
        GridItem(.adaptive(minimum: 110))
    ]

    @MainActor
    private var filteredAssets: [Asset] {
        let searchText = navigation.searchText
        guard !searchText.isEmpty else {
            return assets
        }

        return assets.filter {
            $0.title.lowercased().contains(searchText.lowercased())
        }
    }

    @Environment(NavigationManager.self) private var navigation
    @Environment(MediaLibrary.self) private var library

    // MARK: Lifecycle

    init(assets: [Asset], album: Album? = nil) {
        self.assets = assets
        self.album = album
    }

    var body: some View {
        @Bindable var navigation = navigation
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredAssets) { asset in
                    NavigationLink(value: asset) {
                        AssetView(asset: asset)
                    }
                    .buttonStyle(.plain)
                }
            }
#if os(iOS)
            // The search bar on iOS already comes with spacing at the top,
            // so only add it on the sides and bottom.
            .padding([.horizontal, .bottom], 8)
#else
            .padding(8)
#endif
        }
        .navigationTitle(album?.title ?? "Gallery")
        .toolbarTitleDisplayMode(.inline)
        .navigationDestination(for: Asset.self) { asset in
            AssetDetailView(asset: asset)
        }
        .searchable(text: $navigation.searchText)
        .onAppear {
            Task.detached {
                await ImageManager.shared.startCaching(for: assets, targetSize: targetSize)
            }
        }
        .onDisappear {
            Task.detached {
                await ImageManager.shared.stopCaching(for: assets, targetSize: targetSize)
            }
        }
        .dropDestination(for: Image.self) { images, _ in
            for image in images {
                Task {
                    try await library.createAsset(from: image)
                }
            }
            
            return true
        }
    }
}

#Preview {
    AssetGrid(assets: [])
}
