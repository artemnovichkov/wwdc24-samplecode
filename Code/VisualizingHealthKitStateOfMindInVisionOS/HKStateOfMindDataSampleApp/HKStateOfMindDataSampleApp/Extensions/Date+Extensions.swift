/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A file containing extensions for working with dates.
*/

import Foundation

// MARK: - Calendar

extension Calendar {
    /// Returns midnight tomorrow. This is useful to represent the end of today, exclusively.
    var startOfTomorrow: Date {
        startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: startOfDay(for: Date()))!)
    }
}

// MARK: - DateFormatter

extension DateFormatter {
    static let chartDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .short
        return dateFormatter
    }()
    
    static let eventDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()
    
    static let eventTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none
        return dateFormatter
    }()
}

// MARK: - DateInterval

extension DateInterval {
    static var todayInterval: DateInterval {
        DateInterval(start: Calendar.current.startOfDay(for: Date()),
                     end: Calendar.current.startOfTomorrow)
    }
    
    static var weeklyInterval: DateInterval {
        let end = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end)!
        return DateInterval(start: start, end: end)
    }
    
    static var eventHighlightInterval: DateInterval {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        return DateInterval(start: start, end: now)
    }
}
