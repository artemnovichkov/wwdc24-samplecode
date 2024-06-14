/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate.
*/

import Foundation
import UIKit
import os

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    
    let logger = Logger(subsystem: "com.apple.liveUpdatesSample", category: "AppDelegate")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let locationsHandler = LocationsHandler.shared
        
        // If location updates were previously active, restart them after the background launch.
        if locationsHandler.updatesStarted {
            self.logger.info("Restart liveUpdates Session")
            locationsHandler.startLocationUpdates()
        }
        // If a background activity session was previously active, reinstantiate it after the background launch.
        if locationsHandler.backgroundUpdates {
            self.logger.info("Reinstantiate background activity session")
            locationsHandler.backgroundUpdates = true
        }
        return true
    }
}
