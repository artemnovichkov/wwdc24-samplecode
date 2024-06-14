/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents possible calendars to toggle on and off.
*/

import SwiftUI

extension CalendarChartsView {
    
    /// A view that allows the user to select and deselect calendars.
    struct CalendarSelectorView: View {
        let calendarModels: [CalendarModel]
        
        @Binding var selectedCalendars: Set<CalendarModel>
        
        init(calendarModels: [CalendarModel],
             selectedCalendars: Binding<Set<CalendarModel>>) {
            self.calendarModels = calendarModels
            self._selectedCalendars = selectedCalendars
        }
        
        var body: some View {
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(calendarModels) { calendar in
                        let isSelected = selectedCalendars.contains(calendar)
                        HStack {
                            Button(action: {
                                if isSelected {
                                    selectedCalendars.remove(calendar)
                                } else {
                                    selectedCalendars.insert(calendar)
                                }
                            }, label: {
                                if isSelected {
                                    Text(Image(systemName: "checkmark.circle.fill")) // Size the SF Symbols to the text.
                                        .foregroundStyle(Color(cgColor: calendar.color))
                                    Text(calendar.title).bold()
                                        .foregroundStyle(Color.primary)
                                } else {
                                    Text(Image(systemName: "checkmark.circle"))
                                        .foregroundStyle(Color(cgColor: calendar.color))
                                    Text(calendar.title)
                                        .foregroundStyle(Color.primary)
                                }
                            })
                        }
                        .padding(8)
#if !os(visionOS)
                        .background(Color(uiColor: .systemFill))
                        .clipShape(Capsule())
#endif
                    }
                }
            }.scrollClipDisabled() // Let calendars scroll off the edge of the screen.
        }
    }
}
