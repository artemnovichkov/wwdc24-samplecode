/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app class.
*/

import SwiftUI
import RealityKitContent

@main
struct EntityGestureApp: App {
    
    init() {
        RealityKitContent.GestureComponent.registerComponent()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 2, height: 1.75, depth: 1, in: .meters)
    }
}
