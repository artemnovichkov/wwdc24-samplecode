/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a single drink that the user consumed.
*/

public import Foundation
internal import HealthKit

// The record of a single drink.
public struct Drink: Hashable, Codable, Sendable {

    // The amount of caffeine in the drink.
    public let mgCaffeine: Double

    // The date when the user consumed the drink.
    public let date: Date

    // A globally unique identifier for the drink.
    public let uuid: UUID

    public let type: DrinkType?

    public var latitude, longitude: Double?

    // The drink initializer.
    public init(type: DrinkType, onDate date: Date, uuid: UUID = UUID()) {
        self.mgCaffeine = type.mgCaffeinePerServing
        self.date = date
        self.uuid = uuid
        self.type = type
    }

    internal init(from sample: HKQuantitySample) {
        self.mgCaffeine = sample.quantity.doubleValue(for: miligrams)
        self.date = sample.startDate
        self.uuid = sample.uuid
        self.type = nil
    }

    // Calculate the amount of caffeine remaining at the provided time,
    // based on a 5-hour half life.
    public func caffeineRemaining(at targetDate: Date) -> Double {
        // Calculate the number of half-life time periods (5-hour increments).
        let intervals = targetDate.timeIntervalSince(date) / (60.0 * 60.0 * 5.0)
        return mgCaffeine * pow(0.5, intervals)
    }
}
