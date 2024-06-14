/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The container view for a person's collection of individual media assets.
*/

import SwiftUI

struct AssetStack: View {

    // MARK: Properties

    @Environment(MediaLibrary.self) private var library
    @Environment(NavigationManager.self) private var navigation

    // MARK: Lifecycle

    var body: some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.libraryPath) {
            AssetGrid(assets: library.assets)
        }
    }
}

#Preview {
    AssetStack()
        .environment(MediaLibrary())
        .environment(NavigationManager())
}
