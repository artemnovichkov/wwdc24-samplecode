/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for the app.
*/

import SwiftUI

@main
struct TVCatalogApp: App {
    var body: some Scene {
        WindowGroup {
            // You have a choice here:
            //  - `ContentView` uses classic `TabView` navigation.
            //  - `SidebarContentView` uses the new sidebar, with extra filler
            //    items.
            ContentView()
//            SidebarContentView()
        }
    }
}
