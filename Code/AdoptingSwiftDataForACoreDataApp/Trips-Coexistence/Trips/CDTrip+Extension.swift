/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model class of trips.
*/

import SwiftUI

extension CDTrip {
    var color: Color {
        let seed = name?.hashValue ?? 8
        var generator: RandomNumberGenerator = SeededRandomGenerator(seed: seed)
        return .random(using: &generator)
    }
    
    var displayName: String {
        guard let name, !name.isEmpty
        else { return "Untitled Trip" }
        return name
    }
    
    var displayDestination: String {
        guard let destination, !destination.isEmpty
        else { return "Untitled Destination" }
        return destination
    }
    
    static var preview: CDTrip {
        let result = PersistenceController.preview
        let viewContext = result.container.viewContext
        let trip = CDTrip(context: viewContext)
        trip.name = "Trip Name"
        trip.destination = "Trip destination"
        trip.startDate = .now
        trip.endDate = .now.addingTimeInterval(4 * 3600)
        return trip
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
