/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to add an ignore item.
*/

import SwiftUI

struct AddIgnoreItem: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(IgnoreItemModel.self) private var model
    @FocusState private var itemEntryIsFocused: Bool
    
    @State private var itemEntry = ""
    @State private var itemType: IgnoreItemType = .email
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Select", selection: $itemType) {
                        ForEach(IgnoreItemType.allCases) { item in
                            Text(item.rawValue)
                        }
                    }
                }
                
                Section {
                    TextField("\(itemType.rawValue)", text: $itemEntry)
                        .focused($itemEntryIsFocused)
                        .textInputAutocapitalization(.never)
                        .textContentType(itemType == .email ? .emailAddress : .telephoneNumber)
                        .autocorrectionDisabled(true)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                itemEntryIsFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add \(itemType.rawValue.capitalized) to Ignore")
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        withAnimation {
                            dismiss()
                        }
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle.fill")
                            .labelStyle(.titleOnly)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let newItem = IgnoreItem(type: itemType, item: itemEntry)
                        model.addIgnoreItem(newItem)
                        
                        withAnimation {
                            dismiss()
                        }
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down.fill")
                            .labelStyle(.titleOnly)
                    }
                    .disabled(itemEntry.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddIgnoreItem()
        .environment(IgnoreItemModel())
}
