/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Allows a person to select and save one emoji (of many) to represent how a calendar event feels.
*/

import HealthKit
import SwiftUI

struct EmojiPicker: View {
    
    let event: EventModel
    @Binding var isLogged: Bool
    
    @Binding var showAlert: Bool
    @Binding var saveDetails: EmojiType.SaveDetails?
    
    @State private var selectedEmoji: EmojiType?
    
    @Environment(\.dismiss) var dismiss
    
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("How did this event go?")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                HStack {
                    ForEach(EmojiType.allCases, id: \.emoji) { emojiType in
                        Button {
                            selectedEmoji = emojiType
                        } label: {
                            EmojiButton(emojiType: emojiType, isSelected: selectedEmoji == emojiType)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Log State of Mind")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: saveThenDismiss) {
                        Text("Save to HealthKit")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedEmoji == nil)
                }
            }
        }
        
    }
    
    func saveThenDismiss() {
        isLogged = true
        if let selectedEmoji {
            Task {
                saveDetails = await healthStore.saveStateOfMindSample(event: event,
                                                                      emoji: selectedEmoji,
                                                                      didError: $showAlert)
                dismiss()
            }
        }
    }
}
