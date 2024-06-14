/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main view.
*/

import os
import SwiftUI
import CoreLocation

let globalAuthDeniedError = "Please enable Location Services by going to Settings -> Privacy & Security"
let authDeniedError = "Please authorize LiveUpdaterSampleApp to access Location Services"
let authRestrictedError = "LiveUpdaterSampleApp can't access your location. Do you have Parental Controls enabled?"
let accuracyLimitedError = "LiveUpdatesSample can't access your precise location, displaying your approximate location instead"

@MainActor class LocationsHandler: ObservableObject {
    let logger = Logger(subsystem: "com.apple.liveUpdatesSample", category: "LocationsHandler")
    
    static let shared = LocationsHandler()  // Create a single, shared instance of the object.

    //private let manager: CLLocationManager
    private var backgroundActivitySession: CLBackgroundActivitySession?

    @Published var lastUpdate: CLLocationUpdate? = nil
    @Published var lastLocation = CLLocation()
    @Published var count = 0
    @Published var isStationary = false

    @Published
    var updatesStarted: Bool = UserDefaults.standard.bool(forKey: "liveUpdatesStarted") {
        didSet {
            updatesStarted ? self.startLocationUpdates() : self.stopLocationUpdates()
            UserDefaults.standard.set(updatesStarted, forKey: "liveUpdatesStarted")
        }
    }
    
    @Published
    var backgroundUpdates: Bool = UserDefaults.standard.bool(forKey: "BGActivitySessionStarted") {
        didSet {
            backgroundUpdates ? self.backgroundActivitySession = CLBackgroundActivitySession() : self.backgroundActivitySession?.invalidate()
            UserDefaults.standard.set(backgroundUpdates, forKey: "BGActivitySessionStarted")
        }
    }
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var notificationContent = UNMutableNotificationContent()
    
    private init() {
        //self.manager = CLLocationManager()  // Creating a location manager instance is safe to call here in `MainActor`.
        notificationContent.title = "Location updates inactive"
        notificationContent.body = "Can't receive location updates while not in the foreground"
        
        Task {
            try await notificationCenter.requestAuthorization(options: [.badge])
        }
    }
    
    func startLocationUpdates() {
        //if self.manager.authorizationStatus == .notDetermined {
        //    self.manager.requestWhenInUseAuthorization()
        //}
        self.logger.info("Starting location updates")
        Task {
            do {
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    if !self.updatesStarted { break }  // End location updates by breaking out of the loop.
                    self.lastUpdate = update
                    if let loc = update.location {
                        self.lastLocation = loc
                        self.isStationary = update.stationary
                        self.count += 1
                        self.logger.info("Location \(self.count): \(self.lastLocation)")
                    }
                    if lastUpdate!.insufficientlyInUse {
                        let notification = UNNotificationRequest(identifier: "com.example.mynotification", content: notificationContent, trigger: nil)
                        try await notificationCenter.add(notification)
                    }
                }
            } catch {
                self.logger.error("Could not start location updates")
            }
            return
        }
    }
    
    func stopLocationUpdates() {
        self.logger.info("Stopping location updates")
        backgroundUpdates = false
    }
}

struct ContentView: View {
    let logger = Logger(subsystem: "com.apple.liveUpdatesSample", category: "DemoView")
    @ObservedObject var locationsHandler = LocationsHandler.shared
    
    var body: some View {
        VStack {
            Spacer()
            if locationsHandler.updatesStarted {
                if locationsHandler.lastUpdate?.authorizationDeniedGlobally ?? false {
                    ErrorView(errorMessage: globalAuthDeniedError)
                } else if locationsHandler.lastUpdate?.authorizationDenied ?? false {
                    ErrorView(errorMessage: authDeniedError)
                } else if locationsHandler.lastUpdate?.authorizationRestricted ?? false {
                    ErrorView(errorMessage: authRestrictedError)
                } else if locationsHandler.lastUpdate?.accuracyLimited ?? false {
                    ErrorView(errorMessage: accuracyLimitedError)
                } else if locationsHandler.lastUpdate?.insufficientlyInUse ?? false {
                    EmptyView()
                }
            }
            
            Text("Location: \(self.locationsHandler.lastLocation.description)")
                .padding(10)
            Text("Count: \(self.locationsHandler.count)")
            Text("isStationary:")
            Rectangle()
                .fill(self.locationsHandler.isStationary ? .green : .red)
                .frame(width: 100, height: 100, alignment: .center)
            Spacer()
            Toggle("Location Updates", isOn: $locationsHandler.updatesStarted)
            .frame(width: 200)
            Toggle("BG Activity Session", isOn: $locationsHandler.backgroundUpdates)
            .frame(width: 200)
            .disabled(!locationsHandler.updatesStarted)
        }
    }
}

struct ErrorView: View {
    @State var errorMessage: String
    
    var body: some View {
        GroupBox {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .frame(width: 50, height: 50)
                Text(errorMessage)
            }
        }
        .padding(20)
        .cornerRadius(1)
    }
}
