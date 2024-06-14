/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A shared `HKHealthStore` to use within the app.
*/
import HealthKit

/// A reference to the shared `HKHealthStore` for views to use.
final class HealthStore: Sendable {
    
    static let shared: HealthStore = HealthStore()
    
    let healthStore = HKHealthStore()
    
    private init() { }
    
}
