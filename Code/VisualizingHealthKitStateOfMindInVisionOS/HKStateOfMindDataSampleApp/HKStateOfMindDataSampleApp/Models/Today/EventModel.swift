/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model for `EKEvent` and the EKCalendar-based `HKStateOfMind.Association`.
*/

import EventKit
import Foundation
import HealthKit
import SwiftUI

struct EventModel: Sendable, Identifiable {
    
    let id = UUID()
    let eventTitle: String
    let startDate: Date
    let endDate: Date
    let association: HKStateOfMind.Association
    let calendarIdentifier: String
    let calendarColor: Color
    var isLogged: Bool
    
    var startDisplayString: String {
        startDate.formatted(date: .omitted, time: .shortened)
    }
    
    var endDisplayString: String {
        endDate.formatted(date: .omitted, time: .shortened)
    }
    
    var length: TimeInterval {
        endDate.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate
    }
    
    init(eventTitle: String,
         startDate: Date,
         endDate: Date,
         association: HKStateOfMind.Association,
         calendarIdentifier: String,
         calendarColor: Color,
         isLogged: Bool) {
        self.eventTitle = eventTitle
        self.startDate = startDate
        self.endDate = endDate
        self.association = association
        self.calendarIdentifier = calendarIdentifier
        self.calendarColor = calendarColor
        self.isLogged = isLogged
    }
    
    init(ekEvent: EKEvent,
         isLogged: Bool = false) {
        self.init(eventTitle: ekEvent.title,
                  startDate: ekEvent.startDate,
                  endDate: ekEvent.endDate,
                  association: Calendars.stateOfMindAssociation(for: ekEvent.calendar),
                  calendarIdentifier: ekEvent.calendar.calendarIdentifier,
                  calendarColor: Color(ekEvent.calendar.cgColor),
                  isLogged: isLogged)
    }
}
