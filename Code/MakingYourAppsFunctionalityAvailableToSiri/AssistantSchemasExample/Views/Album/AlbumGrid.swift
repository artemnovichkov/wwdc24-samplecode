/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The grid view of loaded albums.
*/

import SwiftUI

struct AlbumGrid: View {

    // MARK: Properties

    @State private var isSheetPresented = false

    @Environment(MediaLibrary.self) private var library

    private let columns = [
        GridItem(.adaptive(minimum: 300))
    ]

    // MARK: Lifecycle

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(library.albums) { album in
                    NavigationLink(value: album) {
                        AlbumItem(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
#if os(macOS)
            .padding()
#endif
        }
        .navigationTitle("Albums")
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", systemImage: "plus", action: addAlbum)
            }
        }
        .sheet(isPresented: $isSheetPresented) {
            AlbumNameView()
        }
    }

    // MARK: Methods

    private func addAlbum() {
        isSheetPresented = true
    }
}

#Preview {
    AlbumGrid()
        .environment(MediaLibrary())
}
