/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry point to the app.
*/

import SwiftUI

@main
struct ConstantColorCamApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().preferredColorScheme(.dark)
        }
    }
}
