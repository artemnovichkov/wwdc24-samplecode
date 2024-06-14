/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays contacts when the app has full access to Contacts.
*/

import SwiftUI

struct FullAccessList: View {
    @Environment(ContactStoreManager.self) private var storeManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(storeManager.contacts) { contact in
                    Text(contact.fullName)
                }
            }
            .navigationTitle("Your Contacts")
            .overlay {
                if storeManager.contacts.isEmpty {
                    ContentUnavailableView {
                        Label("No contacts", systemImage: "text.badge.plus")
                    } description: {
                        Text("Add some contacts.")
                    }
                }
            }
            .task {
                await storeManager.fetchContacts()
            }
        }
    }
}

#Preview {
    FullAccessList()
        .environment(ContactStoreManager())
}
