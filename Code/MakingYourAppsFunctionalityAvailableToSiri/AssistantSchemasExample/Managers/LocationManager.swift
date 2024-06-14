/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The enum that provides functionality to look up location information.
*/

import Foundation
@preconcurrency import CoreLocation

actor LocationManager {

    // MARK: Static

    static let shared = LocationManager()

    // MARK: Properties

    private let geocoder = CLGeocoder()
    private var currentTask: Task<CLPlacemark, Error>?

    // MARK: Methods

    func lookUp(_ location: CLLocation) async throws -> CLPlacemark {
        // Start an asynchronous lookup.
        currentTask = Task { [currentTask] in
            // Await any previous processing.
            _ = await currentTask?.result

            // Register a new task.
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks[0]
        }

        // Await new task completion.
        return try await currentTask!.value
    }
}
