/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A file containing extensions for saving data from app models to HealthKit.
*/

import Foundation
import HealthKit
import SwiftUI

extension HKHealthStore {

    /// Create a State of Mind sample for a date and State of Mind association.
    func createSample(event: EventModel, emoji: EmojiType) -> HKStateOfMind {
        return HKStateOfMind(date: event.endDate,
                             kind: .momentaryEmotion,
                             valence: emoji.valence,
                             labels: [emoji.label],
                             associations: [event.association])
    }

    /// Saves a State of Mind sample from an event, updating the provided binding, and returning an error description if an error occurs.
    func saveStateOfMindSample(event: EventModel,
                               emoji: EmojiType,
                               didError: Binding<Bool>) async -> EmojiType.SaveDetails? {
        let sample = createSample(event: event, emoji: emoji)
        let saveDetails = await save(sample: sample, didError: didError)
        return saveDetails
    }

    /// Saves a State of Mind sample from an emoji type, updating the provided binding, and returning an error description if an error occurs.
    func save(sample: HKSample, didError: Binding<Bool>) async -> EmojiType.SaveDetails? {
        do {
            try await save(sample)
        } catch {
            switch error {
            case HKError.errorNotPermissibleForGuestUserMode:
                // Drop data you generate in a Guest User session.
                didError.wrappedValue = true
                return .init(errorString: "Health data cannot be saved while Guest User is on.")
            default:
                // Existing error handling.
                didError.wrappedValue = true
                return .init(errorString: "Your health data could not be saved: \(error.localizedDescription)")
            }
        }
        return nil // No error.
    }
}

