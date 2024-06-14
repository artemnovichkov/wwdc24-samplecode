/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A wrapper view that instantiates the coffee tracker view and the data for the hosting controller.
*/

import CoffeeKit
import SwiftUI
import os

let logger = Logger(
    subsystem:
        "com.example.apple-samplecode.Coffee-Tracker.watchkitapp.watchkitextension.ContentView",
    category: "Root View")

// A wrapper view that simplifies adding the main view to the hosting controller.
public struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject var recaffeinater: Recaffeinater

    // Access the shared model object.
    let data = CoffeeData.shared

    var minimumCaffeine: Double = 1.0

    // Create the main view, and pass the model.
    public var body: some View {
        CoffeeTrackerView()
            .environmentObject(data)
            .onChange(of: scenePhase) { (phase) in
                switch phase {

                case .inactive:
                    logger.debug("Scene became inactive.")

                case .active:
                    logger.debug("Scene became active.")
                    let model = CoffeeData.shared
                    model.locationProvider.authorizeLocation()
                    
                    Task {
                        // Make sure the app has requested health authorization.
                        let success = await model.healthKitController.requestAuthorization()

                        // Check for errors.
                        if !success { fatalError("*** Unable to authenticate HealthKit ***") }

                        // Check for updates from HealthKit.
                        await model.healthKitController.loadNewDataFromHealthKit()
                    }

                case .background:
                    logger.debug("Scene moved to the background.")

                    // Schedule a background refresh task
                    // to update the complications.
                    scheduleBackgroundRefreshTasks()

                @unknown default:
                    logger.debug("Scene entered unknown state.")
                    assertionFailure()
                }
            }
    }

}

@MainActor
class Recaffeinater: ObservableObject {
    @Published var recaffeinate: Bool = false
    var minimumCaffeine: Double = 0.0
}

extension Recaffeinater: CaffeineThresholdDelegate {
    public func caffeineLevel(at level: Double) {
        if level < minimumCaffeine {
            // TODO: Alert the user to drink more coffee!
        }
    }
}

// The preview for the content view.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
