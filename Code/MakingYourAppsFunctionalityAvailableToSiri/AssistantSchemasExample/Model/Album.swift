/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model object for an album of media assets.
*/

import Foundation
import Photos

@Observable
final class Album {

    // MARK: Properties

    let collection: PHAssetCollection

    var title: String
    var assets = [Asset]()

    var creationDate: Date? {
        collection.startDate
    }

    // MARK: Lifecycle

    init(collection: PHAssetCollection) {
        self.collection = collection
        self.title = collection.localizedTitle ?? ""
    }

    // MARK: Methods

    func setTitle(_ title: String) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest(for: self.collection)
            request?.title = title
        }
        self.title = title
    }

    func setAssets(_ assets: Set<Asset>) async throws {
        let current = Set(self.assets)

        let toInsert = assets.subtracting(current).map(\.phAsset)
        let toRemove = current.subtracting(assets).map(\.phAsset)

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest(for: self.collection)
            request?.addAssets(toInsert as NSFastEnumeration)
            request?.removeAssets(toRemove as NSFastEnumeration)
        }
        self.assets = Array(assets)
    }

    func fetchAssets() async throws {
        // Fetch all assets from this collection.
        let fetchResult = PHAsset.fetchAssets(in: collection, options: nil)

        // Enumerate and insert assets.
        var phAssets = [PHAsset]()
        fetchResult.enumerateObjects { (object, count, stop) in
            phAssets.append(object)
        }

        // Process the assets.
        let assets = phAssets.map { phAsset in
            Asset(phAsset: phAsset)
        }

        // Update the assets on the main thread.
        await MainActor.run {
            self.assets = assets
        }
    }
}

extension Album: Identifiable, Hashable {

    var id: String {
        collection.localIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Album, rhs: Album) -> Bool {
        lhs.id == rhs.id
    }
}

extension Album: @unchecked Sendable {

    var entity: AlbumEntity {
        let entity = AlbumEntity(id: id)
        entity.name = title
        entity.albumType = .custom
        entity.creationDate = creationDate
        return entity
    }
}
