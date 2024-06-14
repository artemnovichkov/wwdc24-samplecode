/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Swift extensions that add image functionality.
*/

import SwiftUI

#if os(macOS)
import AppKit

typealias KitImage = NSImage
#else
import UIKit

typealias KitImage = UIImage

#endif

extension Image {

    init(from data: Data) {
        let image = KitImage(data: data) ?? .init()
#if os(macOS)
        self.init(nsImage: image)
#else
        self.init(uiImage: image)
#endif
    }

    @MainActor
    var kit: KitImage {
        let renderer = ImageRenderer(content: self)
        #if os(macOS)
        return renderer.nsImage!
        #else
        return renderer.uiImage!
        #endif
    }
}

#if os(macOS)
extension NSImage {

    func pngData() -> Data? {
        tiffRepresentation
    }
}
#endif
