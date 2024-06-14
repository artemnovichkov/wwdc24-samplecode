/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry point to the app.
*/
import SwiftUI

@main
struct HLSInterstitialDemoApp: App {
    let menuViewModel = MenuViewModel.createViewModelWithMenu
    
    var body: some Scene {
        WindowGroup {
            MenuView(viewModel: menuViewModel)
        }
    }
}
