/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides a score from 0 to 100 representing the self-reported measure of positivity of `HKStateOfMind` samples associated with work.
*/

import Foundation
import HealthKit

struct CalendarQualityScoreProvider {
    
    /// Returns a value from 0 to 100 representing the average valence values on `HKStateOfMind` samples with an association.
    static func calendarQualityScore(
        forNumberOfDays numberOfDays: Int,
        associations: [HKStateOfMind.Association],
        healthStore: HKHealthStore
    ) async throws -> Int {
        var dayComponents = DateComponents()
        dayComponents.day = -1 * numberOfDays
        let today = Date()
        let currentCalendar = Calendar.current
        let oldestDaysAgo = currentCalendar.date(byAdding: dayComponents,
                                                 to: today,
                                                 wrappingComponents: false)
        guard let oldestDaysAgo else {
            return 0
        }
        
        let datePredicate = HKQuery.predicateForSamples(withStart: oldestDaysAgo,
                                                        end: Date(),
                                                        options: [])
        
        let associationsPredicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: associations.map { HKQuery.predicateForStatesOfMind(with: $0) }
        )
        let compoundPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [datePredicate, associationsPredicate]
        )
        let stateOfMindPredicate = HKSamplePredicate.stateOfMind(compoundPredicate)
        
        let descriptor = HKSampleQueryDescriptor(predicates: [stateOfMindPredicate],
                                                 sortDescriptors: [])
        
        let results: [HKStateOfMind]
        do {
            // Launch the query and wait for the results.
            results = try await descriptor.result(for: healthStore)
        } catch {
            print("Error querying samples: \(String(describing: error))")
            return 0
        }
        guard !results.isEmpty else {
            return 0
        }
        
        // Adjust each valence value to be within a range of 0.0 to 2.0.
        let adjustedValenceResults = results.map { $0.valence + 1.0 }
        // Calculate the average valence.
        let totalAdjustedValence = adjustedValenceResults.reduce(0.0, +)
        let averageAdjustedValence = totalAdjustedValence / Double(results.count)
        // Convert the valence to a percentage.
        let adjustedValenceAsPercent = Int(100.0 * (averageAdjustedValence / 2.0))
        return adjustedValenceAsPercent
    }
    
}
