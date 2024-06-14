# Making your app's functionality available to Siri

Add assistant schemas to your app so Siri can complete requests, and integrate your app with Apple Intelligence, Spotlight, and other system experiences.

## Overview

Using this sample app, people can keep track of photos and videos they capture with their device and can use Siri to access app functionality. 
To make its main functionality available to Siri, the app uses the App Intents framework. 
 
 > Related sessions from WWDC24: Session 10133: [Bring your app to Siri](https://developer.apple.com/wwdc24/10133/)

## Make app functionality available to Siri
 
This sample uses <doc:app-intent-domains> to make the ``AppEnum``, ``AppEntity``, and ``AppIntent`` implementations available to Siri as shown in the following example:

``` swift
@AssistantEnum(schema: .photos.assetType)
enum AssetType: String, AppEnum {
    case photo
    case video

    static let caseDisplayRepresentations: [AssetType : DisplayRepresentation]  = [
        .photo: "Photo",
        .video: "Video"
    ]
}
```

## Make data available in Spotlight

People can use Spotlight to search for data the sample contains. To enable this functionality, the sample defines an app entity that conforms to <doc://com.apple.documentation/documentation/appintents/indexedentity>:

```swift
@AssistantEntity(schema: .photos.asset)
struct AssetEntity: IndexedEntity {

    // MARK: Static

    static let defaultQuery = AssetQuery()

    // MARK: Properties

    let id: String
    let asset: Asset

    @Property(title: "Title")
    var title: String?

    var creationDate: Date?
    var location: CLPlacemark?
    var assetType: AssetType?
    var isFavorite: Bool
    var isHidden: Bool
    var hasSuggestedEdits: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: title.map { "\($0)" } ?? "Unknown",
            subtitle: assetType?.localizedStringResource ?? "Photo"
        )
    }
}
```

## Make app entities shareable

By adopting the <doc://com.apple.documentation/documentation/coretransferable/transferable/> protocol, this sample makes the data it describes
as app entities more shareable and allows other apps to understand its data formats.
For example, the sample's `AssetEntity` implements `Transferable` to make it easy to share a photo
as a PNG image with Siri or the share sheet:

```swift
extension AssetEntity: Transferable {

    struct AssetQuery: EntityQuery {
        @Dependency
        var library: MediaLibrary

        @MainActor
        func entities(for identifiers: [AssetEntity.ID]) async throws -> [AssetEntity] {
            library.assets(for: identifiers).map(\.entity)
        }

        @MainActor
        func suggestedEntities() async throws -> [AssetEntity] {
            library.assets.prefix(3).map(\.entity)
        }
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { entity in
            try await entity.asset.pngData()
        }
    }
}
```
