/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A singleton object that handles requesting and updating the user location.
*/

import Foundation
import CoreLocation
import Observation
import OSLog

@MainActor
@Observable class LocationService: NSObject {
    
    static let shared = LocationService()
    
    private let locationLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Location Services")
    
    /// A default location to use when updated user location data is unavailable.
    private static let sanFranciscoAppleStoreUnionSquare = CLLocation(latitude: 37.788_46, longitude: -122.407_12)
    
    private let locationManager = CLLocationManager()
    
    /// A person's current location, represented as a set of coordinates.
    private(set) var currentLocation = LocationService.sanFranciscoAppleStoreUnionSquare
    
    private override init() {
        super.init()
        locationManager.delegate = self
    }

    /// Asks a person for permission to get their location. This sample sets `NSLocationDefaultAccuracyReduced` to `YES` in the `Info.plist`
    /// file to get the person's location with reduced accuracy because precise location isn't necessary to return search results for nearby
    /// points of interest.
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            guard let newLocation = locations.last else { return }
            currentLocation = newLocation
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle any errors that `CLLocationManager` returns.
        locationLogger.error("Location manager encountered an error: \(error.localizedDescription)")
    }
}
