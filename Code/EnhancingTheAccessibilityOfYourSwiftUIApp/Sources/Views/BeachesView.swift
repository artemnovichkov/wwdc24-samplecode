/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows information about all beaches.
*/

import SwiftUI
import SwiftData
import WidgetKit

/// The entry point for the beaches tab item. A view for creating and rating beaches.
struct BeachesView: View {
    @State private var editingBeach: Beach?
    @Query(sort: \Beach.dateCreated, order: .reverse) private var beaches: [Beach]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List(beaches) { beach in
                BeachView(editingBeach: $editingBeach, beach: beach)
                    .modifier(CenteredListItemModifier())
                    .listRowSeparator(.hidden)
                    .contextMenu {
                        deleteButton(for: beach)
                    }
                    // Create a container element so that when someone is editing beach information,
                    // VoiceOver on iOS can access the text field.
                    .accessibilityElement(
                        children: isSelectedBeach(beach) ? .contain : .combine)
                    .accessibilityLabel { label in
                        label
                        if !isSelectedBeach(beach) {
                            Text(beach.rating.label)
                        }
                    }
                    .accessibilityActions {
                        // Provide the delete button for quicker access as a custom action.
                        deleteButton(for: beach)
                    }
            }
            .accessibilityLabel("Beaches")
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .navigationTitle("Beaches")
            .toolbar {
                BeachComposerItem(editingBeach: $editingBeach)
            }
        }
        .frame(minWidth: 400)
    }

    @ViewBuilder
    private func deleteButton(for beach: Beach) -> some View {
        Button("Delete") {
            modelContext.delete(beach)
            try? modelContext.save()
        }
    }

    private func isSelectedBeach(_ beach: Beach) -> Bool {
        editingBeach?.id == beach.id
    }
}

private struct BeachComposerItem: View {
    @Binding var editingBeach: Beach?
    @Environment(\.self) private var environment
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button(action: createNewBeach) {
            Image(systemName: "square.and.pencil")
        }
        .accessibilityLabel("New Beach")
    }

    private func createNewBeach() {
        if let editingBeach, editingBeach.name.isEmpty {
            return
        }
        let beach = Beach.makeBeach(in: environment)
        editingBeach = beach
        modelContext.insert(beach)
    }
}

private struct BeachView: View {
    @Binding var editingBeach: Beach?
    let beach: Beach
    @FocusState private var isEditing: Bool
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            if let editingBeach, editingBeach.id == beach.id {
                TextField("Name", text: Bindable(editingBeach).name)
                    .focused($isEditing)
                    .fontWeight(.heavy)
                    .font(.title2)
                    .padding()
                    .onAppear { isEditing = true }
            } else {
                Text(beach.name)
                    .fontWeight(.heavy)
                    .font(.title2)
            }
            Spacer()

            Button(action: toggleRating) {
                ZStack {
                    Circle()
                        .foregroundStyle(.primary.opacity(0.8))
                    Image(systemName: beach.rating.imageName)
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, value: beach.rating)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 30, maxHeight: 30)
            .accessibilityLabel(beach.rating.label)

            if let editingBeach, editingBeach.id == beach.id {
                Button(action: finishEditing) {
                    ZStack {
                        Circle()
                            .foregroundStyle(.primary.opacity(0.8))
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 30, maxHeight: 30)
                .accessibilityLabel("Complete Editing")
            }
        }
        .padding()
        .frame(minHeight: 75)
        .frame(maxWidth: 500)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(beach.gradient.gradient)
                .shadow(radius: 5)
        }
        .padding(.vertical, 5)
        .onChange(of: editingBeach) { oldValue, newValue in
            if let oldValue, oldValue.id == beach.id, oldValue.name.isEmpty {
                modelContext.delete(oldValue)
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    private func finishEditing() {
        editingBeach = nil
        AccessibilityNotification.LayoutChanged().post()
    }

    private func toggleRating() {
        switch beach.rating {
        case .none:
            beach.rating = .halfStar
        case .halfStar:
            beach.rating = .fullStar
        case .fullStar:
            beach.rating = .none
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
