/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Actions that the app exposes to system experiences as app intents.
*/

import AppIntents
import Foundation
import SwiftUI

enum IntentError: Error {
    case noEntity
}

@AssistantIntent(schema: .photos.createAssets)
struct CreateAssetsIntent: AppIntent {
    var files: [IntentFile]

    @Dependency
    var library: MediaLibrary

    @MainActor
    func perform() async throws -> some ReturnsValue<[AssetEntity]> {
        guard !files.isEmpty else {
            throw IntentError.noEntity
        }

        var toReturn: [AssetEntity] = []

        // Process input
        for file in files {
            let image = Image(from: file.data)
            let asset = try await library.createAsset(from: image)
            toReturn.append(asset.entity)
        }
        
        return .result(value: toReturn)
    }
}

@AssistantIntent(schema: .photos.openAsset)
struct OpenAssetIntent: OpenIntent {
    var target: AssetEntity

    @Dependency
    var library: MediaLibrary

    @Dependency
    var navigation: NavigationManager

    @MainActor
    func perform() async throws -> some IntentResult {
        let assets = library.assets(for: [target.id])
        guard let asset = assets.first else {
            throw IntentError.noEntity
        }

        navigation.openAsset(asset)
        return .result()
    }
}

@AssistantIntent(schema: .photos.updateAsset)
struct UpdateAssetIntent: AppIntent {
    var target: [AssetEntity]
    var name: String?
    var isHidden: Bool?
    var isFavorite: Bool?

    @Dependency
    var library: MediaLibrary

    func perform() async throws -> some IntentResult {
        let assets = await library.assets(for: target.map(\.id))
        for asset in assets {
            if let isHidden {
                try await asset.setIsHidden(isHidden)
            }
            if let isFavorite {
                try await asset.setIsFavorite(isFavorite)
            }
        }
        return .result()
    }
}

@AssistantIntent(schema: .photos.deleteAssets)
struct DeleteAssetsIntent: DeleteIntent {
    static let openAppWhenRun = true

    var entities: [AssetEntity]

    @Dependency
    var library: MediaLibrary

    @MainActor
    func perform() async throws -> some IntentResult {
        let identifiers = entities.map(\.id)
        let assets = library.assets(for: identifiers)
        try await library.deleteAssets(assets)
        return .result()
    }
}

@AssistantIntent(schema: .photos.search)
struct SearchAssetsIntent: ShowInAppSearchResultsIntent {
    static let searchScopes: [StringSearchScope] = [.general]

    var criteria: StringSearchCriteria

    @Dependency
    var navigation: NavigationManager

    @MainActor
    func perform() async throws -> some IntentResult {
        navigation.openSearch(with: criteria.term)
        return .result()
    }
}
