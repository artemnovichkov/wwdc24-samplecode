/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data source for calendar events and State of Mind samples.
*/

import Foundation
import HealthKit
import EventKit

extension HKStateOfMind: @unchecked @retroactive Sendable {

}

/// Groups State of Mind data together for a given calendar and the given date range.
@Observable @MainActor final class CalendarChartStateOfMindData {
    let healthStore: HKHealthStore
    let calendar: CalendarModel
    
    /// The current samples from HealthKit, which views can reference and observe.
    fileprivate(set) var stateOfMindSamples: [HKStateOfMind]? = nil
    
    /// The date range for querying data.
    /// The range isn't inclusive of the end of the last day, fetching samples up to the end of that day (midnight the day after).
    fileprivate(set) var dateInterval: DateInterval
    
    /// The label to use to query State of Mind data.
    fileprivate(set) var stateOfMindLabel: HKStateOfMind.Label?
    
    init(healthStore: HKHealthStore,
         calendar: CalendarModel,
         dateInterval: DateInterval,
         stateOfMindLabel: HKStateOfMind.Label? = nil) {
        self.healthStore = healthStore
        self.calendar = calendar
        self.dateInterval = dateInterval
        self.stateOfMindLabel = stateOfMindLabel
    }
}

/// Fetches and maintains a dataset of `CalendarChartStateOfMindData` and coordinates changes in the date interval to keep the set coherent.
@Observable @MainActor class CalendarChartStateOfMindDataProvider {
    let healthStore: HKHealthStore
    
    var selectedCalendars: Set<CalendarModel> = [] {
        didSet {
            updateCalendarData(for: Array(selectedCalendars))
        }
    }
    
    /// References to the open queries for each calendar, which the system keys by the calendar identifier.
    private var queryTasks: [String: Task<Void, any Error>] = [:]
    
    /// The date range for querying data.
    /// The range is *closed* over the last day, fetching samples up to the end of that day (midnight the day after).
    var dateInterval: DateInterval {
        didSet {
            // Fetch fresh data.
            calendarStateOfMindData = []
            updateCalendarData(for: Array(selectedCalendars))
        }
    }
    
    /// The label to use to query State of Mind data.
    var stateOfMindLabel: HKStateOfMind.Label?
    
    /// The fetched data associated with each selected calendar, for the given date range.
    private(set) var calendarStateOfMindData: [CalendarChartStateOfMindData] = []
    
    init(healthStore: HKHealthStore,
         selectedCalendars: Set<CalendarModel>,
         dateInterval: DateInterval,
         stateOfMindLabel: HKStateOfMind.Label? = nil) {
        self.healthStore = healthStore
        self.selectedCalendars = selectedCalendars
        self.dateInterval = dateInterval
        self.stateOfMindLabel = stateOfMindLabel
        updateCalendarData(for: Array(selectedCalendars))
    }
    
    func fetchAndObserveDataSources() {
        for calendarData in calendarStateOfMindData {
            fetchAndObserveData(for: calendarData)
        }
    }
    
    func stopObservingDataSources() {
        for calendarData in calendarStateOfMindData {
            stopObservation(for: calendarData)
        }
    }
    
    func fetchAndObserveData(for calendarData: CalendarChartStateOfMindData) {
        queryTasks[calendarData.calendar.identifier] = Task(priority: .userInitiated) {
            // Fetch samples based on configuration.
            let samples: [HKStateOfMind]
            if let stateOfMindLabel {
                samples = try await fetchStateOfMindSamples(label: stateOfMindLabel,
                                                            association: calendarData.calendar.stateOfMindAssociation)
            } else {
                samples = try await fetchStateOfMindSamples(association: calendarData.calendar.stateOfMindAssociation)
            }
            calendarData.stateOfMindSamples = samples
        }
    }
    
    func fetchStateOfMindSamples(label: HKStateOfMind.Label,
                                 association: HKStateOfMind.Association) async throws -> [HKStateOfMind] {
        // Configure the query.
        let datePredicate = HKQuery.predicateForSamples(withStart: dateInterval.start, end: dateInterval.end)
        let associationPredicate = HKQuery.predicateForStatesOfMind(with: association)
        let labelPredicate = HKQuery.predicateForStatesOfMind(with: label)
        let compoundPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [datePredicate, associationPredicate, labelPredicate]
        )
        
        let stateOfMindPredicate = HKSamplePredicate.stateOfMind(compoundPredicate)
        let descriptor = HKSampleQueryDescriptor(predicates: [stateOfMindPredicate], sortDescriptors: [])
        
        // Fetch the results.
        return try await descriptor.result(for: healthStore)
    }
    
    func fetchStateOfMindSamples(association: HKStateOfMind.Association) async throws -> [HKStateOfMind] {
        // Configure the query.
        let datePredicate = HKQuery.predicateForSamples(withStart: dateInterval.start, end: dateInterval.end)
        let associationPredicate = HKQuery.predicateForStatesOfMind(with: association)
        let compoundPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [datePredicate, associationPredicate]
        )
        let stateOfMindPredicate = HKSamplePredicate.stateOfMind(compoundPredicate)
        let descriptor = HKSampleQueryDescriptor(predicates: [stateOfMindPredicate], sortDescriptors: [])
        
        // Fetch the results.
        return try await descriptor.result(for: healthStore)
    }
    
    func stopObservation(for calendarData: CalendarChartStateOfMindData) {
        queryTasks[calendarData.calendar.identifier]?.cancel()
        queryTasks[calendarData.calendar.identifier] = nil
    }
    
    private func updateDateInterval(_ dateInterval: DateInterval, for calendarDataToUpdate: CalendarChartStateOfMindData) {
        calendarDataToUpdate.dateInterval = dateInterval
        // Start an updated query.
        fetchAndObserveData(for: calendarDataToUpdate)
    }
    
    private func updateCalendarData(for calendars: [CalendarModel]) {
        var updatedData = [CalendarChartStateOfMindData]()
        for calendar in calendars {
            if let existingData = calendarStateOfMindData.first(where: { $0.calendar == calendar }) {
                updatedData.append(existingData)
            } else {
                let newData = CalendarChartStateOfMindData(healthStore: healthStore,
                                                           calendar: calendar,
                                                           dateInterval: dateInterval,
                                                           stateOfMindLabel: stateOfMindLabel)
                fetchAndObserveData(for: newData)
                updatedData.append(newData)
            }
        }
        // Set with a consistent sort order.
        self.calendarStateOfMindData = updatedData.sorted(by: { $0.calendar.title < $1.calendar.title })
    }
}
