/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The navigation model for selected trips.
*/

import Foundation
import SwiftUI
import SwiftData

@Observable @MainActor
final class TripRouter {
    static let shared = TripRouter()

    var selectedTrip: Trip?
    private(set) var compositionRequested: ComposeType?

    func requestComposition(for type: ComposeType) {
        compositionRequested = type
    }

    func createComposition(
        in environment: EnvironmentValues,
        for context: ModelContext
    ) {
        guard compositionRequested != nil else { return }
        let trip = Trip.makeTrip(in: environment)
        context.insert(trip)
        selectedTrip = trip
        compositionRequested = nil
    }
}
