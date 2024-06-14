/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that allows a person to choose a media asset.
*/

import SwiftUI

struct AlbumAssetPicker: View {

    // MARK: Properties

    let album: Album

    @State private var selection: Set<Asset>

    @Environment(MediaLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss

    private let targetSize = CGSize(width: 100, height: 100)

    private let columns = [
        GridItem(.adaptive(minimum: 110))
    ]

    // MARK: Lifecycle

    init(album: Album) {
        self.album = album
        self._selection = State(wrappedValue: Set(album.assets))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(library.assets) { asset in
                        let isSelected = selection.contains(asset)
                        ZStack(alignment: .bottomLeading) {
                            Button {
                                didSelect(asset)
                            } label: {
                                AssetView(asset: asset)
                                    .opacity(isSelected ? 0.5 : 1)
                            }

                            if isSelected {
                                Image(systemName: "checkmark.circle")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.blue))
                                    .shadow(radius: 4)
                                    .padding(4)
                            }
                        }
                    }
                }
#if os(iOS)
                // The search bar on iOS already comes with spacing at the top,
                // so only add it on the sides and bottom.
                .padding([.horizontal, .bottom])
#else
                .padding()
#endif
            }
            .navigationTitle(album.title)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: saveAction)
                }
            }
        }
    }

    // MARK: Methods

    private func saveAction() {
        Task {
            // Save changes.
            try await album.setAssets(selection)

            // Close.
            dismiss()
        }
    }

    private func didSelect(_ asset: Asset) {
        if selection.contains(asset) {
            selection.remove(asset)
        } else {
            selection.insert(asset)
        }
    }
}
