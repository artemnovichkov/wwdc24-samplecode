/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app structure.
*/
import OSLog
import SwiftUI

let immersiveSpace = "ImmersiveSpace"

/// The entry point for the app.
@main
@MainActor
struct ARKitRoomTrackingApp: App {
    
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }.defaultSize(CGSize(width: 800, height: 400))
        
        ImmersiveSpace(id: immersiveSpace) {
            WorldAndRoomView()
                .environment(appState)
        }
    }
}

@MainActor
let logger = Logger(subsystem: "com.example.apple-samplecode.arkitroomtracking.ARKitRoomTracking", category: "general")
