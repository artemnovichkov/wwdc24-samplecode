/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for the Coffee Tracker app.
*/

import SwiftUI

@main
struct CoffeeTrackerApp: App {

    @WKApplicationDelegateAdaptor private var appDelegate: ExtensionDelegate

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
