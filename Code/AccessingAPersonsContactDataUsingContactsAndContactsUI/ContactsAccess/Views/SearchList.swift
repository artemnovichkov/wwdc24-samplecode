/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to display contacts a person selects when the app's authorization status is limited.
*/

import SwiftUI

struct SearchList: View {
    @Environment(ContactStoreManager.self) private var storeManager
    @Environment(IgnoreItemModel.self) private var model
    @State private var searchText = ""
    
    /*
        List of identifiers of contacts a person selects in the contact access
        picker or authorizes for the app using the contact access button. The app
        highlighs all contacts whose identifiers are contained in this list.
    */
    @State private var lastAddedIdentifiers: Set<String> = []
    @FocusState private var searchFieldIsFocused: Bool
    @State private var filter: CaptionOrder = .defaultText
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    searchField
                }
                contactView
                if !searchText.isEmpty {
                    Section("Quick-Add") {
                        QuickAddContactButton(lastAddedIdentifiers: $lastAddedIdentifiers, searchText: $searchText, caption: $filter)
                    }
                }
            }
            .navigationTitle("Your Contacts")
            .overlay {
                if storeManager.contacts.isEmpty {
                    ContentUnavailableView {
                        Label("No contacts selected", systemImage: "text.badge.plus")
                    } description: {
                        let picker = "Select some contacts from the contact access picker."
                        let access = "Alternatively, enter a name in the Search field to quickly add it to the list of contacts the app can access."
                        Text("\(picker) \(access)")
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .onAppear {
                fetchContacts()
                searchFieldIsFocused.toggle()
            }
            .toolbar {
                AddContactButton(lastAddedContacts: $lastAddedIdentifiers)
                Menu {
                    Section("Select bottom caption") {
                        CaptionOrderPicker(caption: $filter)
                    }
                    
                } label: {
                    Label("Menu", systemImage: "ellipsis.circle")
                        .labelStyle(.iconOnly)
                }
            }
        }
    }
    
    private func fetchContacts() {
        Task {
            await storeManager.fetchContacts()
        }
    }
    
    private var searchField: some View {
        TextField("Search", text: $searchText)
            .focused($searchFieldIsFocused)
            .autocorrectionDisabled(false)
    }
    
    private var contactView: some View {
        ForEach(storeManager.contacts) { contact in
            let name = contact.fullName
            let shouldHighlight = lastAddedIdentifiers.contains(contact.id)
            
            if searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText) {
                ContactDetail(shouldHighlight: shouldHighlight, contact: contact)
            }
        }
    }
}

#Preview {
    SearchList()
        .environment(ContactStoreManager())
        .environment(IgnoreItemModel())
}
