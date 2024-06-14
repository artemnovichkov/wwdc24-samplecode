/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents each player's state in the SharePlay group session.
*/

import Spatial
import SwiftUI

struct PlayerModel: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var name: String
    
    var score: Int = 0
    var isPlaying: Bool = false
    
    var team: Team? = nil
    var seatPose: Pose3D?
    
    enum Team: String, Codable, Hashable, Sendable {
        case blue
        case red
    }
}

extension PlayerModel.Team {
    var name: String {
        switch self {
        case .blue: "Team Blue"
        case .red: "Team Red"
        }
    }
    
    var color: Color {
        switch self {
        case .red: .red
        case .blue: .blue
        }
    }
}
