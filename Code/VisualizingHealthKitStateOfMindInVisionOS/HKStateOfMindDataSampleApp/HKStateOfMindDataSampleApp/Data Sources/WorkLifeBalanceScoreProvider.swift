/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides a score from 0 to 100 representing the percentage of calendar time that's associated with work.
*/

import EventKit
import Foundation

struct WorkLifeBalanceScoreProvider {
    
    /// Returns a value from 0 to 100 representing the percentage of allocated time across all calendars for work events.
    static func calculateWorkLifeBalanceScore(from calendars: Calendars,
                                              numberOfDays: Int) async -> Int {
        let workCalendar = calendars.calendarModels.first(where: { $0.stateOfMindAssociation == .work })
        guard let workCalendar else {
            return 0
        }
        
        let totalWorkSeconds = await totalSecondsAllocated(to: workCalendar, numberOfDays: numberOfDays)
        print("Calculated total work seconds to be \(totalWorkSeconds)")
        var totalSecondsByCalendar: [TimeInterval] = []
        for calendar in calendars.calendarModels {
            totalSecondsByCalendar.append(await totalSecondsAllocated(to: calendar,
                                                                      numberOfDays: numberOfDays))
        }
        let totalSecondsForAllCalendars = totalSecondsByCalendar.reduce(0, +)
        print("Calculated total calendar seconds to be \(totalSecondsForAllCalendars)")
        guard totalSecondsForAllCalendars > 0 else {
            return 0
        }
        
        let percentAllocatedToWork = totalWorkSeconds / totalSecondsForAllCalendars
        let roundedPercentAllocatedToWork = Int(100 * percentAllocatedToWork)
        
        // Dedicating a lot of time to work results in a low work-life balance score.
        let workLifeBalanceScore = 100 - roundedPercentAllocatedToWork
        print("Computed work-life balance store to be \(workLifeBalanceScore)")
        return workLifeBalanceScore
    }
    
    /// Returns the amount of allocated time for a particular calendar for the specified number of days.
    private static func totalSecondsAllocated(to calendar: CalendarModel,
                                              numberOfDays: Int) async -> TimeInterval {
        let endDate = Calendar.current.startOfTomorrow
        let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: endDate)!
        let dateInterval = DateInterval(start: startDate, end: endDate)
        
        do {
            let events = try await CalendarFetcher.shared.findEvents(within: dateInterval, in: calendar)
            
            let eventDurations = events.map {
                let startDate = $0.startDate
                let endDate = $0.endDate
                let duration = endDate.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate
                print("Adding duration \(duration) to calendar \(calendar.title) for event \($0.eventTitle)")
                return duration
            }
            
            let totalTime = eventDurations.reduce(0.0, +)
            return totalTime
        } catch {
            print("Error finding events: \(error)")
            return 0.0
        }
    }
}
