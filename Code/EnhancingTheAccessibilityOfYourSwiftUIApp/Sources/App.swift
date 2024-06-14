/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for the app.
*/

import SwiftUI
import SwiftData

@main
struct SwiftUIAccessibilitySampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Trip.self, Beach.self, Contact.self])
    }
}
