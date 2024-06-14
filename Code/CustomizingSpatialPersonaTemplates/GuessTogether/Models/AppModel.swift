/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable model that maintains app-wide state.
*/

import Foundation
import SwiftUI
import Observation

@Observable @MainActor
class AppModel {
    var sessionController: SessionController?
    
    var playerName: String = UserDefaults.standard.string(forKey: "player-name") ?? "" {
        didSet {
            UserDefaults.standard.set(playerName, forKey: "player-name")
            sessionController?.localPlayer.name = playerName
        }
    }
    
    var showPlayerNameAlert = false
    
    var isImmersiveSpaceOpen = false
}
