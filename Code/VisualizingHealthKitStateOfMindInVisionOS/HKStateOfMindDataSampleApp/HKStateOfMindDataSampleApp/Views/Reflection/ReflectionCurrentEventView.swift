/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that finds and shows the current event,
 with the ability to log an emotion associated with it.
*/

import SwiftUI
import HealthKit
import EventKit
#if os(visionOS)

struct ReflectionCurrentEventView: View {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    private let calendars: Calendars
    
    @Binding var selectedEmoji: EmojiType?
    @State private var currentEvent: EventModel?
    @State private var currentCalendar: CalendarModel?
    
    /* Error Handling */
    @State private var showAlert = false
    @State private var saveDetails: EmojiType.SaveDetails? = nil
    
    init(calendars: Calendars,
         selectedEmoji: Binding<EmojiType?>) {
        self.calendars = calendars
        self._selectedEmoji = selectedEmoji
    }
    
    var body: some View {
        VStack {
            if let currentEvent, let currentCalendar {
                Text("How did this event go?")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                HStack {
                    VStack() {
                        // The current event information.
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(currentEvent.eventTitle)")
                                    .font(.title).fontWeight(.bold)
                                Text("\(dateFormatterHour(from: currentEvent.startDate)) in \(currentCalendar.title)")
                                    .font(.title).fontWeight(.regular)
                            }
                            Spacer()
                        }
                        .frame(width: 375)
                        .padding()
                        .background(.thickMaterial)
                        .cornerRadius(16)
                        
                        // The emoji picker.
                        ReflectionCurrentEmojiPickerView(event: currentEvent,
                                                         selectedEmoji: $selectedEmoji)
                        .padding()
                        Button("Save to HealthKit") {
                            guard let selectedEmoji else { return }
                            Task {
                                self.saveDetails = await healthStore.saveStateOfMindSample(event: currentEvent,
                                                                                           emoji: selectedEmoji,
                                                                                           didError: $showAlert)
                                await dismissImmersiveSpace()
                            }
                        }
                        .padding()
                        .disabled(selectedEmoji == nil)
                    }
                    .padding()
                    .foregroundStyle(.primary)
                    Spacer()
                }
                .frame(width: 400)
            }
        }
        .alert("Unable to Save Health Data",
               isPresented: $showAlert,
               presenting: saveDetails,
               actions: { _ in }, // The default OK button.
               message: { details in
            Text(details.errorString)
        })
        .onAppear {
            Task {
                do {
                    currentEvent = try await CalendarFetcher.shared.findCurrentEvent(within: .todayInterval, in: calendars.calendarModels)
                    if let currentEvent {
                        currentCalendar = try calendars.calendar(for: currentEvent)
                    }
                } catch {
                    print("Unable to fetch current event and calendar: \(String(describing: error))")
                }
            }
        }
    }
    
    // Format the date to an hour, such as 4:00 p.m.
    private func dateFormatterHour(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
#endif
