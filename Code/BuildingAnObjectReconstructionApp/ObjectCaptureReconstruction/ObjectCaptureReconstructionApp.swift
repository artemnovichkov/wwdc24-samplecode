/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Top-level app structure of the view hierarchy.
*/

import SwiftUI

@main
struct ObjectCaptureReconstructionApp: App {
    static let subsystem: String = "com.example.apple-samplecode.ObjectCaptureReconstruction"

    var body: some Scene {
        Window("ObjectCaptureReconstruction", id: "main") {
            ContentView()
                .frame(width: 400, height: 360)
        }
        .windowResizability(.contentSize)
    }
}
