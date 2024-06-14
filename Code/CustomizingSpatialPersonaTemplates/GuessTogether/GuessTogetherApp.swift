/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/

import SwiftUI

@main
struct GuessTogetherApp: App {
    @State var appModel = AppModel()
    
    var body: some Scene {
        Group {
            GuessTogetherWindow()
            GameSpace()
        }
        .environment(appModel)
    }
}
