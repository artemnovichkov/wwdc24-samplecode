/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom enumeration implementation that describes your album data.
*/

import Foundation
import AppIntents

@AssistantEnum(schema: .photos.albumType)
enum AlbumType: String, AppEnum {
    case custom

    static let caseDisplayRepresentations: [AlbumType: DisplayRepresentation] = [
        .custom: "Custom"
    ]
}
