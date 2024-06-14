/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The object that manages access to a person's Photos and the app's reading and writing tasks in the Photos library.
*/

import CoreSpotlight
import Photos
import SwiftUI

@Observable
final class MediaLibrary: Sendable {
    enum Error: Swift.Error {
        case missingLocalIdentifier
        case failedToFetchAsset
    }

    // MARK: Properties

    @MainActor var assets: [Asset]
    @MainActor var albums: [Album]

    // MARK: Lifecycle

    @MainActor init() {
        self.assets = []
        self.albums = []
    }

    // MARK: Internal Methods

    func load() {
        Task.detached {
            await self.fetchAssets()
            await self.fetchAlbums()
        }
    }

    @discardableResult
    func createAsset(from image: Image) async throws -> Asset {
        var assetPlaceholder: PHObjectPlaceholder?

        // Convert the image.
        let kitImage = await MainActor.run {
            image.kit
        }

        // Create a new placeholder asset.
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAsset(from: kitImage)
            assetPlaceholder = request.placeholderForCreatedAsset
        }

        // Process the input.
        guard let identifier = assetPlaceholder?.localIdentifier else {
            throw Error.missingLocalIdentifier
        }

        // Fetch assets.
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let phAsset = assets.firstObject else {
            throw Error.failedToFetchAsset
        }

        let asset = Asset(phAsset: phAsset)

        // Update the assets on the main thread.
        await MainActor.run {
            self.assets.append(asset)
        }

        // Index new entity with Spotlight.
        Task {
            try await CSSearchableIndex.default().indexAppEntities([asset.entity])
        }

        return asset
    }

    func deleteAssets(_ assets: [Asset]) async throws {
        let toDelete = assets.map(\.phAsset)
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(toDelete as NSFastEnumeration)
        }

        // Update the assets on the main thread.
        await MainActor.run {
            assets.forEach { asset in
                self.assets.removeAll(where: { $0 == asset })
            }
        }

        // Remove indexed entities from Spotlight.
        Task {
            try await CSSearchableIndex.default().deleteAppEntities(identifiedBy: assets.map(\.id), ofType: AssetEntity.self)
        }
    }

    @discardableResult
    func createAlbum(with name: String) async throws -> Album {
        var collectionPlaceholder: PHObjectPlaceholder?

        // Create a new placeholder album.
        try await PHPhotoLibrary.shared().performChanges {
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            collectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }

        // Process any input.
        guard let identifier = collectionPlaceholder?.localIdentifier else {
            throw Error.missingLocalIdentifier
        }

        // Fetch an album.
        let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil)
        guard let collection = collections.firstObject else {
            throw Error.failedToFetchAsset
        }

        let album = Album(collection: collection)

        // Update the albums on the main thread.
        await MainActor.run {
            self.albums.append(album)
        }

        // Index new entity with Spotlight.
        Task {
            try await CSSearchableIndex.default().indexAppEntities([album.entity])
        }

        return album
    }

    func deleteAlbums(_ albums: [Album]) async throws {
        let toDelete = albums.map(\.collection)
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCollectionChangeRequest.deleteAssetCollections(toDelete as NSFastEnumeration)
        }

        // Update the albums on the main thread.
        await MainActor.run {
            albums.forEach { album in
                self.albums.removeAll(where: { $0 == album })
            }
        }

        // Remove indexed entities from Spotlight.
        Task {
            try await CSSearchableIndex.default().deleteAppEntities(identifiedBy: albums.map(\.id), ofType: AlbumEntity.self)
        }
    }

    // MARK: Private Methods

    private func fetchAssets() async {
        // Request access to the person's library.
        guard await getLibraryAuthorization() else {
            return
        }

        // Fetch all photos from the photo library.
        let fetchResult = PHAsset.fetchAssets(with: nil)

        // Enumerate and insert assets.
        var assets = [Asset]()
        fetchResult.enumerateObjects { (object, count, stop) in
            let asset = Asset(phAsset: object)
            assets.append(asset)
        }

        // Update the assets on the main thread.
        await MainActor.run { [assets] in
            self.assets = assets
        }

        // Index updated entities with Spotlight.
        let entities = assets.map(\.entity)
        Task {
            try await CSSearchableIndex.default().indexAppEntities(entities)
        }
    }

    private func fetchAlbums() async {
        // Request access to the person's library.
        guard await getLibraryAuthorization() else {
            return
        }

        // Fetch all albums from the photo library.
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)

        // Enumerate and insert albums.
        var albums = [Album]()
        fetchResult.enumerateObjects { (object, count, stop) in
            let album = Album(collection: object)
            albums.append(album)
        }

        // Update the albums on the main thread.
        await MainActor.run { [albums] in
            self.albums = albums
        }

        // Index updated entities with Spotlight.
        let entities = albums.map(\.entity)
        Task {
            try await CSSearchableIndex.default().indexAppEntities(entities)
        }
    }

    private func getLibraryAuthorization() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            print("Photo library access authorized.")
            return true
        case .notDetermined:
            print("Photo library access not determined.")
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
        case .denied:
            print("Photo library access denied.")
            return false
        case .limited:
            print("Photo library access limited.")
            return true
        case .restricted:
            print("Photo library access restricted.")
            return false
        @unknown default:
            return false
        }
    }
}

extension MediaLibrary {

    @MainActor
    func assets(for identifiers: [Asset.ID]) -> [Asset] {
        var toReturn = [Asset]()
        identifiers.forEach { id in
            toReturn += assets.filter { $0.id == id }
        }
        return toReturn
    }

    @MainActor
    func albums(for identifiers: [Album.ID]) -> [Album] {
        var toReturn = [Album]()
        identifiers.forEach { id in
            toReturn += albums.filter { $0.id == id }
        }
        return toReturn
    }

    @MainActor
    func albums(matching string: String) -> [Album] {
        albums.filter {
            $0.title.lowercased().contains(string.lowercased())
        }
    }
}
