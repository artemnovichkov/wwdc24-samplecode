/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry point into this app.
*/

import SwiftUI

// - Tag : AppBody
@main
struct WritingApp: App {
    var body: some Scene {
        #if os(iOS)
        DocumentGroupLaunchScene("Writing App") {
            NewDocumentButton("Start Writing")
        } background: {
            Image(.pinkJungle)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        } overlayAccessoryView: { _ in
            AccessoryView()
        }
        #endif
        DocumentGroup(newDocument: WritingAppDocument()) { file in
            StoryView(document: file.$document)
        }
    }
}
