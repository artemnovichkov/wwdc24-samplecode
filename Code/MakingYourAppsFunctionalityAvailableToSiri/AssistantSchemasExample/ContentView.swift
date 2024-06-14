/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the app's user interface.
*/

import SwiftUI

struct ContentView: View {

    // MARK: Properties

    @Environment(MediaLibrary.self) private var library
    @Environment(NavigationManager.self) private var navigation

    // MARK: Lifecycle

    var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selection) {
            Tab("Library", systemImage: "photo.on.rectangle", value: .library) {
                AssetStack()
            }
            Tab("Albums", systemImage: "photo.stack", value: .album) {
                AlbumStack()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(MediaLibrary())
}
