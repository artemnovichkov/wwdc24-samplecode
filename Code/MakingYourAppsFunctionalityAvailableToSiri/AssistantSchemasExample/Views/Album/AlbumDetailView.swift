/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays detail information and interactions for a media album.
*/

import AppIntents
import SwiftUI

struct AlbumDetailView: View {

    // MARK: Properties

    let album: Album

    @State private var isNameSheetPresented = false
    @State private var isAssetPickerPresented = false

    @Environment(MediaLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss

    // MARK: Lifecycle

    var body: some View {
        VStack {
            AssetGrid(assets: album.assets, album: album)
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("Select Photos", systemImage: "photo.badge.checkmark") {
                        isAssetPickerPresented = true
                    }
                    Button("Rename Album", systemImage: "pencil") {
                        isNameSheetPresented = true
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        Task {
                            try await library.deleteAlbums([album])
                            dismiss()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $isNameSheetPresented) {
            AlbumNameView(album: album)
        }
        .sheet(isPresented: $isAssetPickerPresented) {
            AlbumAssetPicker(album: album)
        }
    }
}
