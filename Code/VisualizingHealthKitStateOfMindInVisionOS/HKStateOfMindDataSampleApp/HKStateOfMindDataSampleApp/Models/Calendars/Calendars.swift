/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model for a collection of calendars.
*/

import EventKit
import HealthKit
import Foundation

struct Calendars: Sendable, Equatable {
    var calendarModels: [CalendarModel]
    
    func calendar(for event: EventModel) throws -> CalendarModel {
        guard let calendar = calendarModels.first(where: { $0.identifier == event.calendarIdentifier }) else {
            throw CalendarFetcher.Failure.missingCalendar("Missing calendar for event \(event.eventTitle)")
        }
        return calendar
    }
    
    static func stateOfMindAssociation(for calendar: EKCalendar) -> HKStateOfMind.Association {
        // Do a fuzzy match on the title.
        switch calendar.title {
        case _ where calendar.title.contains("Workouts"): .fitness
        case _ where calendar.title.contains("Social"): .friends
        case _ where calendar.title.contains("Office"): .work
        default: .currentEvents
        }
    }
}
