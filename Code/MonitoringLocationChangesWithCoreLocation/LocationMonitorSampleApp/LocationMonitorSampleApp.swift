/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's entry point.
*/

import SwiftUI

@main
struct LocationMonitorSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
