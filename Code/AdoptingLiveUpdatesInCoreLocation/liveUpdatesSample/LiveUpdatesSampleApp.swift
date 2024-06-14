/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's entry point.
*/
import SwiftUI

@main
struct LiveUpdatesSampleApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
