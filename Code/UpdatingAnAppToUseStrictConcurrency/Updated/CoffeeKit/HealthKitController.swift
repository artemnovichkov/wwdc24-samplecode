/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data controller that manages reading and writing data from the HealthKit store.
*/

internal import Foundation
internal import HealthKit
import os

private let hkLogger = Logger(
    subsystem:
        "com.example.apple-samplecode.Coffee-Tracker.watchkitapp.watchkitextension.HealthKitController",
    category: "HealthKit")

// The key used to save and load anchor objects from user defaults.
private let anchorKey = "anchorKey"

// The HealthKit store.
private let store = HKHealthStore()
private let isAvailable = HKHealthStore.isHealthDataAvailable()

// Caffeine types used to read and write caffeine samples.
private let caffeineType = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!
private let types: Set<HKSampleType> = [caffeineType]

// Milligram units.
internal let miligrams = HKUnit.gramUnit(with: .milli)

public actor HealthKitController {

    // MARK: - Properties

    // A weak link to the main model.
    private weak var model: CoffeeData?

    // Indicates whether the user has authorized access to their health data.
    private lazy var isAuthorized = false

    // An anchor object used to download only the changes since the last time.
    private var anchor: HKQueryAnchor? {
        get {
            // If the user defaults return nil, return it.
            guard let data = UserDefaults.standard.object(forKey: anchorKey) as? Data else {
                return nil
            }

            // Otherwise, unarchive and return the data object.
            do {
                return try NSKeyedUnarchiver.unarchivedObject(
                    ofClass: HKQueryAnchor.self, from: data)
            } catch {
                // If an error occurs while unarchiving, log the error and return nil.
                hkLogger.error("Unable to unarchive \(data): \(error.localizedDescription)")
                return nil
            }
        }
        set(newAnchor) {
            // If the new value is nil, save it.
            guard let newAnchor = newAnchor else {
                UserDefaults.standard.set(nil, forKey: anchorKey)
                return
            }

            // Otherwise, convert the anchor object to data, and save it in the user defaults.
            do {
                let data = try NSKeyedArchiver.archivedData(
                    withRootObject: newAnchor, requiringSecureCoding: true)
                UserDefaults.standard.set(data, forKey: anchorKey)
            } catch {
                // If an error occurs while archiving the anchor, only log the error.
                // The value stored in the user defaults doesn't change.
                hkLogger.error("Unable to archive \(newAnchor): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Initializers

    // The HealthKit controller's initializer.
    init(withModel model: CoffeeData) {
        self.model = model
    }

    // MARK: - Public Methods

    public func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        do {
            try await store.requestAuthorization(toShare: types, read: types)
            self.isAuthorized = true
            return true
        } catch let error {
            hkLogger.error(
                "An error occurred while requesting HealthKit Authorization: \(error.localizedDescription)"
            )
            return false
        }
    }

    private func queryHealthKit() async throws -> (
        [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?
    ) {
        try await withCheckedThrowingContinuation { continuation in
            // Create a predicate that returns only samples created within the last 24 hours.
            let endDate = Date()
            let startDate = endDate.addingTimeInterval(-24.0 * 60.0 * 60.0)
            let datePredicate = HKQuery.predicateForSamples(
                withStart: startDate, end: endDate, options: [.strictStartDate, .strictEndDate])

            // Create the query.
            let query = HKAnchoredObjectQuery(
                type: caffeineType,
                predicate: datePredicate,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { (_, samples, deletedSamples, newAnchor, error) in

                // When the query ends, check for errors.
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples, deletedSamples, newAnchor))
                }

            }
            store.execute(query)
        }
    }

    // Reads data from the HealthKit store.
    @discardableResult
    public func loadNewDataFromHealthKit() async -> Bool {

        guard isAvailable else {
            hkLogger.debug("HealthKit is not available on this device.")
            return false
        }

        hkLogger.debug("Loading data from HealthKit")

        do {
            let (samples, deletedSamples, newAnchor) = try await queryHealthKit()
            // Update the anchor.
            self.anchor = newAnchor

            // Convert new caffeine samples into drink instances.
            let newDrinks: [Drink] =
                if let samples {
                    self.drinksToAdd(from: samples)
                } else {
                    []
                }

            // Create a set of UUIDs for any samples deleted from HealthKit.
            let deletedDrinks = self.drinksToDelete(from: deletedSamples ?? [])

            // Update the data on the main queue.

            await model?.updateModel(newDrinks: newDrinks, deletedDrinks: deletedDrinks)
            return true
        } catch {
            hkLogger.error(
                "An error occurred while querying for samples: \(error.localizedDescription)")
            return false
        }
    }

    // Save a drink to HealthKit as a caffeine sample.
    public func save(drink: Drink) async {

        // Make sure HealthKit is available and authorized.
        guard isAvailable else { return }
        guard store.authorizationStatus(for: caffeineType) == .sharingAuthorized else { return }

        // Create metadata to hold the drink's UUID.
        // Use the sync identifier to remove drinks if they are deleted from
        // HealthKit.
        let metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: drink.uuid.uuidString,
            HKMetadataKeySyncVersion: 1
        ]

        // Create a quantity object for the amount of caffeine in the drink.
        let mgCaffeine = HKQuantity(unit: miligrams, doubleValue: drink.mgCaffeine)

        // Create the caffeine sample.
        let caffeineSample = HKQuantitySample(
            type: caffeineType,
            quantity: mgCaffeine,
            start: drink.date,
            end: drink.date,
            metadata: metadata)

        // Save the sample to the HealthKit store.
        do {
            try await store.save(caffeineSample)
            hkLogger.debug("\(mgCaffeine) mg Drink saved to HealthKit")
        } catch {
            hkLogger.error(
                "Unable to save \(caffeineSample) to the HealthKit store: \(error.localizedDescription)"
            )
        }

    }

    // MARK: - Private Methods
    // Take an array of caffeine samples, and return an array of drinks.
    private func drinksToAdd(from samples: [HKSample]) -> [Drink] {

        // Filter out any samples that this app saved.
        let newSamples = samples.filter { sample in
            sample.sourceRevision.source != HKSource.default()
        }

        hkLogger.debug("\(newSamples.count) samples not from this app!")

        let quantitySamples = newSamples.compactMap { sample in
            sample as? HKQuantitySample
        }

        hkLogger.debug("\(quantitySamples.count) samples are quantity samples")

        // Return each sample, converted into a drink.
        return quantitySamples.map { sample in
            Drink(from: sample)
        }
    }

    // For any drinks deleted from the HealthKit store, this function also deletes them from the app's data.
    private func drinksToDelete(from samples: [HKDeletedObject]) -> Set<UUID> {
        let uuidsToDelete = samples.lazy.map { deletedObject -> UUID in
            // Prefer HKMetadataKeySyncIdentifier if available.
            let uuidString = deletedObject.metadata?[HKMetadataKeySyncIdentifier] as? String ?? ""
            return UUID(uuidString: uuidString) ?? deletedObject.uuid
        }

        hkLogger.debug("\(uuidsToDelete.count) drinks deleted from HealthKit.")

        return Set(uuidsToDelete)
    }

}
