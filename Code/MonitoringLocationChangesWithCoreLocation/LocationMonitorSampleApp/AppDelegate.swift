/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate.
*/

import Foundation
import OSLog
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var locationMonitor = ObservableMonitorModel.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        locationMonitor.startMonitoringConditions()
        return true
    }
}
