/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content view.
*/

import SwiftUI

struct ContentView: View {
    @State private var storeManager = ContactStoreManager()
    
    var body: some View {
        MainView()
            .environment(storeManager)
    }
}

#Preview {
    ContentView()
        .environment(ContactStoreManager())
}
