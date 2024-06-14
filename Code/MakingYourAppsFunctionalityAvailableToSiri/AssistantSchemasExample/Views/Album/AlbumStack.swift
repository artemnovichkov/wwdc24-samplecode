/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The container view for a person's media albums.
*/

import SwiftUI

struct AlbumStack: View {

    // MARK: Properties

    @Environment(NavigationManager.self) private var navigation

    // MARK: Lifecycle

    var body: some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.albumPath) {
            AlbumGrid()
        }
    }
}

#Preview {
    AlbumStack()
        .environment(MediaLibrary())
}
