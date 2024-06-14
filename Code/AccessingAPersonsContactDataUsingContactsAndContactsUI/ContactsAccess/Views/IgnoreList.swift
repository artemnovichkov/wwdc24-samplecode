/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a list of email addresses and phone numbers to ignore.
*/

import SwiftUI

struct IgnoreList: View {
    @Environment(IgnoreItemModel.self) private var model
    @State private var isPresented = false
    
    var body: some View {
        NavigationStack {
            List {
                addNoteButton
                if !model.ignoredEmails.isEmpty {
                    Section("Emails") {
                        emails
                    }
                }
                if !model.ignoredPhoneNumbers.isEmpty {
                    Section("Phone Numbers") {
                        phoneNumbers
                    }
                }
            }
            .navigationTitle("Ignore List")
            .sheet(isPresented: $isPresented) {
                AddIgnoreItem()
            }
            .toolbar {
                if !model.isEmpty {
                    EditButton()
                }
            }
        }
    }
    
    private var addNoteButton: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label("Add phone or email", systemImage: "plus.circle.fill")
        }
    }
    
    private var emails: some View {
        ForEach(model.ignoredEmails) { email in
            Text(email.item)
        }
        .onDelete { indexSet in
            for index in indexSet {
                model.removeEmailIgnoreItem(model.ignoredEmails[index])
            }
        }
    }
    
    private var phoneNumbers: some View {
        ForEach(model.ignoredPhoneNumbers) { phone in
            Text(phone.item)
        }
        .onDelete { indexSet in
            for index in indexSet {
                model.removePhoneNumberIgnoreItem(model.ignoredPhoneNumbers[index])
            }
        }
    }
}

#Preview {
    IgnoreList()
        .environment(IgnoreItemModel())
}
