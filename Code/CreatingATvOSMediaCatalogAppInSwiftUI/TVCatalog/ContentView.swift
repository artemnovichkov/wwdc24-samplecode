/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view for the app.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // The main content app landing page.
            Tab("Stack", systemImage: "line.3.horizontal") {
                StackView()
            }

            // A gallery of the different button styles available in tvOS.
            Tab("Buttons", systemImage: "button.horizontal") {
                ButtonsView()
            }

            // An example of a full-screen product description.
            Tab("Description", systemImage: "text.quote") {
                DescriptionView()
            }

            // A searchable content grid.
            Tab("Search", systemImage: "magnifyingglass") {
                SearchView()
            }
        }
    }
}

#Preview {
    ContentView()
}
