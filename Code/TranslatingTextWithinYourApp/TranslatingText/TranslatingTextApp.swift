/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main structure that launches the app.
*/

import SwiftUI

@main
struct TranslatingTextApp: App {
    @State private var model = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}
