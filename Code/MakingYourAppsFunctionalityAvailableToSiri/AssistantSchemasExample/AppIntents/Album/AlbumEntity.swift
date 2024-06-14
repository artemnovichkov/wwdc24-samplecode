/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An entity that describes a photo album.
*/

import AppIntents
import CoreLocation

@AssistantEntity(schema: .photos.album)
struct AlbumEntity: IndexedEntity {

    // MARK: Static

    static let defaultQuery = AlbumQuery()

    // MARK: Properties

    let id: String

    var name: String
    var creationDate: Date?
    var albumType: AlbumType

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: albumType.localizedStringResource
        )
    }
}

extension AlbumEntity {

    struct AlbumQuery: EntityQuery {

        @Dependency
        var library: MediaLibrary

        @MainActor
        func entities(for identifiers: [AlbumEntity.ID]) async throws -> [AlbumEntity] {
            library.albums(for: identifiers).map(\.entity)
        }

        @MainActor
        func suggestedEntities() async throws -> [AlbumEntity] {
            library.albums.prefix(3).map(\.entity)
        }
    }
}
