/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main window that presents the app's user interface.
*/

import SwiftUI

struct GuessTogetherWindow: Scene {
    @Environment(AppModel.self) var appModel
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .frame(width: 900, height: 600)
            .nameAlert()
        }
        .windowResizability(.contentSize)
    }
}
