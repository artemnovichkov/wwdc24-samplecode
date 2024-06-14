/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model for a calendar.
*/

import EventKit
import HealthKit
import Foundation

/// A calendar to associate with a particular `HKStateOfMind.Association`, with a reference to the backing `EKCalendar`.
struct CalendarModel: Identifiable, Equatable, Hashable, Sendable {
    var id: String { identifier }
    
    let identifier: String
    let color: CGColor
    let title: String
    let stateOfMindAssociation: HKStateOfMind.Association
    
    init(calendarIdentifier: String,
         calendarColor: CGColor,
         calendarTitle: String,
         stateOfMindAssociation: HKStateOfMind.Association) {
        self.identifier = calendarIdentifier
        self.color = calendarColor
        self.title = calendarTitle
        self.stateOfMindAssociation = stateOfMindAssociation
    }
    
    init(ekCalendar: EKCalendar, association: HKStateOfMind.Association) {
        self.init(calendarIdentifier: ekCalendar.calendarIdentifier,
                  calendarColor: ekCalendar.cgColor,
                  calendarTitle: ekCalendar.title,
                  stateOfMindAssociation: association)
    }
}
