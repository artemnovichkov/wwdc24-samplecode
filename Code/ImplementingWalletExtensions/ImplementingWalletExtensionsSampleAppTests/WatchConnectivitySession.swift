/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates a Watch Connectivity session to check if the iPhone has a paired Apple Watch.
*/

import WatchConnectivity

/**
 A class that supports creating a `WCSession` object.
 */
class WatchConnectivitySession: NSObject, WCSessionDelegate {
    let session = WCSession.default
    
    override init() {
        
        // Initialize the superclass.
        super.init()
        
        // Activate the session if the current iPhone can use a
        // session object.
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // A Boolean indicating whether the current iPhone has a paired Apple Watch.
    var isPaired: Bool {
        if session.activationState == .activated {
            return session.isPaired
        } else {
            return false
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
