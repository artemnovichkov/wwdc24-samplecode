/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Show an image thumbnail.
*/

import SwiftUI

struct ThumbnailView: View {
    let imageFolderURL: URL
    @State private var image: NSImage?

    var body: some View {
        VStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .cornerRadius(6)
                    .rotationEffect(Angle(degrees: 90))
            } else {
                ProgressView()
            }
        }
        .task {
            loadThumbnail(url: imageFolderURL)
        }
    }

    private func loadThumbnail(url: URL) {
        DispatchQueue.global().async {
            // Load the embedded thumbnail.
            let options: [CFString: Any] = [kCGImageSourceThumbnailMaxPixelSize: 100]
            if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
               let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
                DispatchQueue.main.async {
                    image = NSImage(cgImage: cgImage, size: .zero)
                }
            }
        }
    }
}
