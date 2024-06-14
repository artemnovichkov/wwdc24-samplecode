/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/

import AppIntents
import SwiftUI

@main
struct AssistantSchemasExampleApp: App {

    // MARK: Lifecycle

    let library: MediaLibrary
    let navigationManager: NavigationManager

    init() {
        let navigationManager = NavigationManager()
        let library = MediaLibrary()
        library.load()
        AppDependencyManager.shared.add(dependency: library)
        AppDependencyManager.shared.add(dependency: navigationManager)
        self.library = library
        self.navigationManager = navigationManager
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environment(library)
        .environment(navigationManager)
    }
}
