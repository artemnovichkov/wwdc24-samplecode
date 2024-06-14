/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays detailed information and interactions for a media asset.
*/

import AppIntents
import SwiftUI

struct AssetDetailView: View {
    
    // MARK: Properties

    let asset: Asset

    @State private var image: Image?

    @Environment(MediaLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss

    private let targetSize = CGSize(width: 1000, height: 1000)

    // MARK: Lifecycle

    var body: some View {
        GeometryReader { proxy in
            Group {
                if let image {
                    MediaView(
                        image: image,
                        duration: asset.duration,
                        isFavorite: asset.isFavorite,
                        proxy: proxy
                    )
                } else {
                    ProgressView()
                        .padding()
                }
            }
            .onAppear {
                let targetSize = proxy.size
                Task.detached {
                    let image = await ImageManager.shared.requestImage(for: asset, targetSize: targetSize)
                    await MainActor.run {
                        self.image = image
                    }
                }
            }
        }
        .navigationTitle(asset.title)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Menu("Actions", systemImage: "ellipsis") {
                    Button("Copy", systemImage: "doc", action: copyAction)
                    if let image {
                        Button("Duplicate", systemImage: "doc.on.doc") {
                            Task {
                                try await library.createAsset(from: image)
                                dismiss()
                            }
                        }
                    }
                    Button(asset.isFavorite ? "Unfavorite" : "Favorite", systemImage: "heart") {
                        Task {
                            try await asset.setIsFavorite(!asset.isFavorite)
                        }
                    }
                    if let image {
                        ShareLink(item: image, preview: SharePreview(asset.title, image: image))
                    }
                    Divider()
                    Button("Hide", systemImage: "eye.slash", role: .destructive) {
                        Task {
                            try await asset.setIsHidden(!asset.isHidden)
                        }
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        Task {
                            try await library.deleteAssets([asset])
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    // MARK: Methods

    func copyAction() {
        guard let kitImage = image?.kit else {
            return
        }

#if os(macOS)
        NSPasteboard.general.writeObjects([kitImage])
#else
        UIPasteboard.general.image = kitImage
#endif
    }

    // MARK: Layout

    struct MediaView: View {

        // MARK: Properties

        let image: Image
        let duration: TimeInterval
        let isFavorite: Bool
        let proxy: GeometryProxy

        @State private var contentMode: ContentMode = .fit

        // MARK: Lifecycle

        var body: some View {
            ZStack(alignment: .center) {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                    .onTapGesture(count: 2) {
                        withAnimation {
                            contentMode = contentMode == .fit ? .fill : .fit
                        }
                    }

                if !duration.isZero {
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
            }
        }
    }
}
