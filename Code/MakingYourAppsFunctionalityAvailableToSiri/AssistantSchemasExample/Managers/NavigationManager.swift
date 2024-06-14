/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The object that manages navigation in the app.
*/

import Foundation
import SwiftUI

@MainActor @Observable
final class NavigationManager {
    enum Selection: Int {
        case library
        case album
    }

    // MARK: Properties

    var libraryPath = NavigationPath()
    var albumPath = NavigationPath()

    var selection = Selection.library
    var searchText = ""

    // MARK: Methods

    func openAsset(_ asset: Asset) {
        selection = .library
        libraryPath = NavigationPath([asset])
    }

    func openAlbum(_ album: Album) {
        selection = .album
        albumPath = NavigationPath([album])
    }

    func openSearch(with criteria: String) {
        selection = .library
        searchText = criteria
        libraryPath = NavigationPath()
    }
}
