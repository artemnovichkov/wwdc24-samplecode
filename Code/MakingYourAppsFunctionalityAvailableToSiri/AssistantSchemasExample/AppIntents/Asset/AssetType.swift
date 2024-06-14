/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The type that describes whether a loaded media asset is a video or a photo.
*/

import Foundation
import AppIntents

@AssistantEnum(schema: .photos.assetType)
enum AssetType: String, AppEnum {
    case photo
    case video

    static let caseDisplayRepresentations: [AssetType: DisplayRepresentation] = [
        .photo: "Photo",
        .video: "Video"
    ]
}
