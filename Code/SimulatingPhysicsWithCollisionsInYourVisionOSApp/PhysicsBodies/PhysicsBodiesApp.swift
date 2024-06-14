/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's initial entry point.
*/

import SwiftUI

@main
struct PhysicsBodiesApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }.windowStyle(.volumetric)
    }
}
