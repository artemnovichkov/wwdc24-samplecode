/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model class of trips.
*/

import Foundation
import SwiftUI
import SwiftData

@Model class Trip {
    #Index<Trip>([\.name], [\.startDate], [\.endDate], [\.name, \.startDate, \.endDate])
    #Unique<Trip>([\.name, \.startDate, \.endDate])
    
    @Attribute(.preserveValueOnDeletion)
    var name: String
    var destination: String
    
    @Attribute(.preserveValueOnDeletion)
    var startDate: Date
    
    @Attribute(.preserveValueOnDeletion)
    var endDate: Date

    @Relationship(deleteRule: .cascade, inverse: \BucketListItem.trip)
    var bucketList: [BucketListItem] = [BucketListItem]()
    
    @Relationship(deleteRule: .cascade, inverse: \LivingAccommodation.trip)
    var livingAccommodation: LivingAccommodation?
    
    init(name: String, destination: String, startDate: Date = .now, endDate: Date = .distantFuture) {
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
    }
}
 
extension Trip {
    var color: Color {
        let seed = name.hashValue
        var generator: RandomNumberGenerator = SeededRandomGenerator(seed: seed)
        return .random(using: &generator)
    }
    
    var displayName: String {
        name.isEmpty ? "Untitled Trip" : name
    }
    
    var displayDestination: String {
        destination.isEmpty ? "Untitled Destination" : destination
    }
    
    static var preview: Trip {
        Trip(name: "Trip Name", destination: "Trip destination",
             startDate: .now, endDate: .now.addingTimeInterval(4 * 3600))
    }
    
    private static func date(calendar: Calendar = Calendar(identifier: .gregorian),
                             timeZone: TimeZone = TimeZone.current,
                             year: Int, month: Int, day: Int) -> Date {
        let dateComponent = DateComponents(calendar: calendar, timeZone: timeZone,
                                           year: year, month: month, day: day)
        let date = Calendar.current.date(from: dateComponent)
        return date ?? Date.now
    }
    
    static var previewTrips: [Trip] {
        [
            Trip(name: "Camping!", destination: "Yosemite",
                 startDate: date(year: 2024, month: 6, day: 27),
                 endDate: date(year: 2024, month: 7, day: 1)),
            Trip(name: "Bridalveil Falls", destination: "Yosemite",
                 startDate: date(year: 2024, month: 6, day: 28),
                 endDate: date(year: 2024, month: 6, day: 28))
        ]
    }
}

private struct SeededRandomGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
    
    func next() -> UInt64 {
        UInt64(drand48() * Double(UInt64.max))
    }
}

private extension Color {
    static var random: Color {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }
    
    static func random(using generator: inout RandomNumberGenerator) -> Color {
        let red = Double.random(in: 0..<1, using: &generator)
        let green = Double.random(in: 0..<1, using: &generator)
        let blue = Double.random(in: 0..<1, using: &generator)
        return Color(red: red, green: green, blue: blue)
    }
}
