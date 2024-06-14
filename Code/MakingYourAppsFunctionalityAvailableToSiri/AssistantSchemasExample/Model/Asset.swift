/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model object for a media asset.
*/

import Foundation
import CoreLocation
import CoreSpotlight
import CoreTransferable
import Photos

@Observable
final class Asset {

    // MARK: Static

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    // MARK: Properties

    let phAsset: PHAsset

    var placemark: CLPlacemark?
    var isFavorite = false
    var isHidden = false

    var title: String {
        guard let placemark, let locality = placemark.locality else {
            return Self.dateFormatter.string(from: creationDate ?? .now)
        }

        return locality
    }

    var creationDate: Date? {
        phAsset.creationDate
    }

    var type: AssetType {
        switch phAsset.mediaType {
        case .image:
            return .photo
        default:
            return .video
        }
    }

    var duration: TimeInterval {
        phAsset.duration
    }

    // MARK: Lifecycle

    init(phAsset: PHAsset) {
        self.phAsset = phAsset
        self.isHidden = phAsset.isHidden
        self.isFavorite = phAsset.isFavorite
    }

    // MARK: Methods

    func fetchPlacemark() async throws {
        guard let location = phAsset.location, placemark == nil else {
            return
        }

        // Reverse geocode the location into the placemark.
        let placemark = try await LocationManager.shared.lookUp(location)

        await MainActor.run {
            self.placemark = placemark
        }

        // Update this entity in Spotlight with the updated placemark.
        try await CSSearchableIndex.default().indexAppEntities([entity])
    }

    func setIsFavorite(_ isFavorite: Bool) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: self.phAsset)
            request.isFavorite = isFavorite
        }
        self.isFavorite = isFavorite
    }

    func setIsHidden(_ isHidden: Bool) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: self.phAsset)
            request.isHidden = isHidden
        }
        self.isHidden = isHidden
    }
}

extension Asset: Identifiable, Hashable {

    var id: String {
        phAsset.localIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.id == rhs.id
    }
}

extension Asset: Transferable {

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { asset in
            try await asset.pngData()
        }
    }

    func pngData() async throws -> Data {
        let targetSize = CGSize(width: 1000, height: 1000)
        let image = await ImageManager.shared.requestImage(for: self, targetSize: targetSize)

        guard let kitImage = await image?.kit,
              let data = kitImage.pngData() else {
            throw MediaLibrary.Error.failedToFetchAsset
        }

        return data
    }
}

extension Asset: @unchecked Sendable {

    var entity: AssetEntity {
        let entity = AssetEntity(id: id, asset: self)
        entity.title = title
        entity.assetType = type
        entity.creationDate = creationDate
        entity.location = placemark
        entity.isFavorite = isFavorite
        entity.isHidden = isHidden
        entity.hasSuggestedEdits = false
        return entity
    }
}
