/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button that presents the Contact access picker.
*/

import SwiftUI

struct AddContactButton: View {
    @Environment(ContactStoreManager.self) private var storeManager
    @State private var isPresented = false
    @Binding var lastAddedContacts: Set<String>
    
    var body: some View {
        /*
            The app displays an Add button (+) that presents the Contact access
            picker when it has limited access authorization. The picker has full
            access to all contacts on the device regardless of the authorization
            status of the app. When someone dismisses the picker, the app receives
            a callback that returns identifiers of contacts the person chose. The
            callback doesn't provide any information about contacts the app can no
            longer access. Additionally, the callback doesn't include any information
            about the contacts your app could access before presenting the picker.
            The app fetches and displays all contacts the person selected in the
            picker in addition to all other contacts it can access.
        */
        addButton
            .contactAccessPicker(isPresented: $isPresented) { identifiers in
                lastAddedContacts = Set(identifiers)
                // Fetch all contacts the app has access to.
                fetchContacts()
            }
    }
    
    private func fetchContacts() {
        Task {
            await storeManager.fetchContacts()
        }
    }
    
    private var addButton: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label("Add contacts", systemImage: "person.crop.circle.fill.badge.plus")
        }
    }
}

#Preview {
    AddContactButton(lastAddedContacts: .constant([]))
        .environment(ContactStoreManager())
}
