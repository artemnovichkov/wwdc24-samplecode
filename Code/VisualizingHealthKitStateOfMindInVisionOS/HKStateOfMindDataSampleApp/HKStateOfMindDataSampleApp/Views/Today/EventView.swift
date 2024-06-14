/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Visualizes a single calendar event where a person can tap the view to select an emoji to describe how the event feels.
*/

import HealthKit
import SwiftUI

struct EventView: View {
    
    @Binding var event: EventModel
    @State private var isShowingPicker = false
    
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    
    /* Error Handling */
    @State private var showAlert: Bool = false
    @State private var saveDetails: EmojiType.SaveDetails? = nil
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(event.calendarColor
                    .opacity(event.isLogged ? 0.45 : 0.7)
                )
                .animation(.easeInOut(duration: 0.25).delay(0.05), value: event.isLogged)
                .cornerRadius(15.0)
                .padding(.horizontal)
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(event.eventTitle)
                        .font(.headline)
                    Text("From \(event.startDisplayString) to \(event.endDisplayString)")
                        .font(.subheadline)
                }
                .foregroundStyle(event.isLogged ? .secondary : .primary)
                .animation(.easeInOut(duration: 0.25).delay(0.05), value: event.isLogged)
                .padding(.leading)
                
                Spacer()
                
                Button {
                    isShowingPicker.toggle()
                } label: {
                    EventLogButton(isLogged: event.isLogged)
                }
                .buttonStyle(.plain)
                .disabled(event.isLogged)
                .padding(.trailing)
            }
            .padding()
        }
        .onTapGesture {
            // Allows an entire cell to be tappable.
            if !event.isLogged {
                // Disable after completing the log.
                isShowingPicker.toggle()
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            EmojiPicker(event: event,
                        isLogged: $event.isLogged,
                        showAlert: $showAlert,
                        saveDetails: $saveDetails)
        }
        .alert("Unable to Save Health Data",
               isPresented: $showAlert,
               presenting: saveDetails,
               actions: { _ in }, // The default OK button.
               message: { details in
            Text(details.errorString)
        })
    }
    
}

// MARK: - Previews

#Preview("Event View") {
    ScrollView {
        EventView(event: .constant(.init(eventTitle: "Hike",
                                         startDate: .now,
                                         endDate: .now.advanced(by: 3456),
                                         association: .fitness,
                                         calendarIdentifier: "Fitness",
                                         calendarColor: .teal,
                                         isLogged: true)))
        EventView(event: .constant(.init(eventTitle: "Bouldering Session",
                                         startDate: .now,
                                         endDate: .now.advanced(by: 3456 * 3),
                                         association: .fitness,
                                         calendarIdentifier: "Fitness",
                                         calendarColor: .orange,
                                         isLogged: false)))
    }
    .padding(.horizontal)
}
