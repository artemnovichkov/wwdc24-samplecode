/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry point for the app.
*/

import SwiftUI

@main
struct AudioTapSampleApp: App {
    @StateObject private var model = Model()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
