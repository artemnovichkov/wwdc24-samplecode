/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point into the app.
*/
import SwiftUI

@main
struct SpatialAudioRendererApp: App {
    let model = ChainViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
