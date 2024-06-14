/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The object that manages loading media data.
*/

import Photos
import SwiftUI

actor ImageManager {

    // MARK: Static

    static let shared = ImageManager()

    // MARK: Properties

    private let imageManager = PHCachingImageManager()

    private var imageContentMode = PHImageContentMode.aspectFit
    private var cachedAssetIdentifiers = [String: Bool]()

    private lazy var requestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return options
    }()

    // MARK: Lifecycle

    init() {
        imageManager.allowsCachingHighQualityImages = true
    }

    // MARK: Methods

    func startCaching(for assets: [Asset], targetSize: CGSize) {
        let phAssets = assets.compactMap { $0.phAsset }
        phAssets.forEach {
            cachedAssetIdentifiers[$0.localIdentifier] = true
        }
        imageManager.startCachingImages(for: phAssets, targetSize: targetSize, contentMode: imageContentMode, options: requestOptions)
    }

    func stopCaching(for assets: [Asset], targetSize: CGSize) {
        let phAssets = assets.compactMap { $0.phAsset }
        phAssets.forEach {
            cachedAssetIdentifiers.removeValue(forKey: $0.localIdentifier)
        }
        imageManager.stopCachingImages(for: phAssets, targetSize: targetSize, contentMode: imageContentMode, options: requestOptions)
    }

    func stopCaching() {
        imageManager.stopCachingImagesForAllAssets()
    }

    func requestImage(for asset: Asset, targetSize: CGSize) async -> Image? {
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset.phAsset,
                targetSize: targetSize,
                contentMode: imageContentMode,
                options: requestOptions
            ) { image, info in
                guard let image = image else {
                    continuation.resume(returning: nil)
                    return
                }

                // Process image.
                let toReturn: Image

                #if os(macOS)
                toReturn = Image(nsImage: image)
                #else
                toReturn = Image(uiImage: image)
                #endif

                continuation.resume(returning: toReturn)
            }
        }
    }
}
