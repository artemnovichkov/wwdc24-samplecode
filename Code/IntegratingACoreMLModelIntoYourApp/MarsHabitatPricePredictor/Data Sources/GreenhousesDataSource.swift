/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data source for the number of greenhouses.
*/

import Foundation

struct GreenhousesDataSource {
    /// Possible values for greenhouses in the habitat
    let values = [1, 2, 3, 4, 5]
    
    func title(for index: Int) -> String? {
        guard index < values.count else { return nil }
        return String(values[index])
    }
    
    func value(for index: Int) -> Double? {
        guard index < values.count else { return nil }
        return Double(values[index])
    }
}
