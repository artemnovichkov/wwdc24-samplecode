/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main tab view of the app when a person grants limited access to the app.
*/

import SwiftUI

struct LimitedAccessTab: View {
    @Environment(ContactStoreManager.self) private var storeManager
    @State private var model = IgnoreItemModel()
    
    var body: some View {
        TabView {
            SearchList()
                .tabItem {
                    Text("Contact List")
                }
            
            IgnoreList()
                .tabItem {
                    Text("Ignore List")
                }
        }
        .environment(model)
    }
}

#Preview {
    LimitedAccessTab()
        .environment(ContactStoreManager())
        .environment(IgnoreItemModel())
}
