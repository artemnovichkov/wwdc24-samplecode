/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An actor for fetching calendar events from EventKit.
*/

import EventKit
import Foundation
import SwiftUI

/// Asynchronously fetches calendars and transforms them into sendable models.
actor CalendarFetcher {
    static let shared = CalendarFetcher(eventStore: EKEventStore())
    
    enum Failure: Error {
        case noSource
        case missingCalendar(String)
    }
    
    private let eventStore: EKEventStore
    private let deviceCalendar: Calendar
    
    private init(eventStore: EKEventStore, deviceCalendar: Calendar = .current) {
        self.eventStore = eventStore
        self.deviceCalendar = deviceCalendar
    }
    
    /// Requests authorization from the user to access calendar events.
    func requestAuthorization() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            eventStore.requestFullAccessToEvents { authorized, error in
                if let error { continuation.resume(throwing: error) }
                continuation.resume(returning: authorized)
            }
        }
    }
    
    /// Fetches applicable calendars.
    func fetchCalendars() throws -> Calendars {
        let source = try sourceToUse()
        var calendarModels: [CalendarModel] = []
        for calendar in source.calendars(for: .event).sorted(by: { $0.title < $1.title }) {
            let association = Calendars.stateOfMindAssociation(for: calendar)
            calendarModels.append(CalendarModel(calendarIdentifier: calendar.calendarIdentifier,
                                                calendarColor: calendar.cgColor,
                                                calendarTitle: calendar.title,
                                                stateOfMindAssociation: association))
        }
        return Calendars(calendarModels: calendarModels)
    }
    
    /// Deletes the calendar.
    func removeCalendar(_ calendarModel: CalendarModel) throws {
        let ekCalendar = try ekCalendar(for: calendarModel)
        try eventStore.removeCalendar(ekCalendar, commit: true)
    }
    
    /// Fetches all the events for today.
    func getTodayEvents(within calendar: CalendarModel) throws -> [EventModel] {
        guard let ekCalendar = eventStore.calendar(withIdentifier: calendar.identifier) else {
            throw Failure.missingCalendar(calendar.identifier)
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        var tomorrow = DateComponents()
        tomorrow.day = 1
        let oneDayFuture = deviceCalendar.date(byAdding: tomorrow, to: today, wrappingComponents: false)
        
        // Create the predicate from the event store's instance method.
        var predicate: NSPredicate? = nil
        if let oneDayFuture = oneDayFuture {
            predicate = eventStore.predicateForEvents(withStart: today, end: oneDayFuture, calendars: [ekCalendar])
        }
        
        // Fetch all events that match the predicate.
        var ekEvents: [EKEvent]? = nil
        if let aPredicate = predicate {
            ekEvents = eventStore.events(matching: aPredicate)
        }
        
        guard let ekEvents else {
            return []
        }
        
        return ekEvents
            .map { EventModel(ekEvent: $0) }
            .sorted { $0.startDate < $1.startDate }
    }
    
    /// Finds the event closest to the current date and time.
    func findCurrentEvent(within dateInterval: DateInterval, in calendars: [CalendarModel]) throws -> EventModel? {
        let events: [EventModel]
        do {
            events = try findEvents(within: dateInterval, in: calendars)
        } catch {
            print("Error finding current event: \(String(describing: error))")
            return nil
        }
        let currentTime = Date()
        var closestEvent: EventModel?
        var closestTimeDifference: TimeInterval = TimeInterval.infinity
        for event in events {
            let startDifference = abs(event.startDate.timeIntervalSince(currentTime))
            let endDifference = abs(event.endDate.timeIntervalSince(currentTime))
            let minDifference = min(startDifference, endDifference)
            
            if minDifference < closestTimeDifference {
                closestEvent = event
                closestTimeDifference = minDifference
            }
        }
        return closestEvent
    }
    
    /// Find the longest event in the given predicate scope.
    /// If multiple events have the same duration, returns the first one alphabetically, based on the title.
    func findLongestEvent(within dateInterval: DateInterval, in calendars: [CalendarModel]) throws -> EventModel? {
        var events: [EventModel] = []
        do {
            events = try findEvents(within: dateInterval, in: calendars)
        } catch {
            print("Error finding longest event: \(String(describing: error))")
            return nil
        }
        
        return events
            .sorted(by: { $0.eventTitle < $1.eventTitle })
            .max(by: { $0.length < $1.length })
    }
    
    /// Fetches events within the specified date interval and calendar.
    func findEvents(within dateInterval: DateInterval, in calendar: CalendarModel) throws -> [EventModel] {
        return try findEvents(within: dateInterval, in: [calendar])
    }
    
    /// Find events in the given time scope.
    func findEvents(within dateInterval: DateInterval, in calendars: [CalendarModel]) throws -> [EventModel] {
        let ekCalendars = try calendars.map { try ekCalendar(for: $0) }
        
        let predicate = eventStore.predicateForEvents(withStart: dateInterval.start,
                                                      end: dateInterval.end,
                                                      calendars: ekCalendars)
        let ekEvents = eventStore.events(matching: predicate)
        let events = ekEvents.map { EventModel(ekEvent: $0) }
        return events
    }
    
    // MARK: - Helpers
    
    private func sourceToUse() throws -> EKSource {
        guard let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) else {
            throw Failure.noSource
        }
        return localSource
    }
    
    private func ekCalendar(for calendar: CalendarModel) throws -> EKCalendar {
        guard let ekCalendar = eventStore.calendar(withIdentifier: calendar.identifier) else {
            throw Failure.missingCalendar("Missing calendar for identifier \(calendar.identifier)")
        }
        return ekCalendar
    }
}
