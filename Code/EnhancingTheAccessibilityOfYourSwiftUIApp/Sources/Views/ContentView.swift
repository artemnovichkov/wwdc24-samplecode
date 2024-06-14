/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content view that represents the main view of the app.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TripsView()
                .tabItem {
                    Label("Trips", systemImage: "binoculars.fill")
                }
            BeachesView()
                .tabItem {
                    Label("Beaches", systemImage: "beach.umbrella.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
