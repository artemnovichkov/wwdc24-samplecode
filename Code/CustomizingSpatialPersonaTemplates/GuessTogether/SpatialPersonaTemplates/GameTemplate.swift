/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom spatial template used to arrange Spatial Personas
  during Guess Together's game stage.
*/

import GroupActivities
import Spatial

/// The team selection template contains three sets of seats:
///
/// 1. An seat to the left of the app window for the active player.
/// 2. Two seats to the right of the app window for the active player's
///    teammates.
/// 3. Five seats in front of the app window for the inactive team-members
///    and any audience members.
///
/// ```
///                  ┌────────────────────┐
///                  │   Guess Together   │
///                  │     app window     │
///                  └────────────────────┘
///
///
/// Active Player  %                       $  Active Team
///                                        $
///
///                      *  *  *  *  *
///
///                         Audience
///
/// ```
struct GameTemplate: SpatialTemplate {
    enum Role: String, SpatialTemplateRole {
        case player
        case activeTeam
    }
    
    static let playerPosition = Point3D(x: -2, z: 3)
    
    var elements: [any SpatialTemplateElement] {
        let activeTeamCenterPosition = SpatialTemplateElementPosition.app.offsetBy(x: 2, z: 3)

        let playerSeat = SpatialTemplateSeatElement(
            position: .app.offsetBy(x: Self.playerPosition.x, z: Self.playerPosition.z),
            direction: .lookingAt(activeTeamCenterPosition),
            role: Role.player
        )
        
        let activeTeamSeats: [any SpatialTemplateElement] = [
            .seat(
                position: activeTeamCenterPosition.offsetBy(x: 0, z: -0.5),
                direction: .lookingAt(playerSeat),
                role: Role.activeTeam
            ),
            .seat(
                position: activeTeamCenterPosition.offsetBy(x: 0, z: 0.5),
                direction: .lookingAt(playerSeat),
                role: Role.activeTeam
            )
        ]
        
        let audienceSeats: [any SpatialTemplateElement] = [
            .seat(position: .app.offsetBy(x: 0, z: 5)),
            .seat(position: .app.offsetBy(x: 1, z: 5)),
            .seat(position: .app.offsetBy(x: -1, z: 5)),
            .seat(position: .app.offsetBy(x: 2, z: 5)),
            .seat(position: .app.offsetBy(x: -2, z: 5))
        ]
        
        return audienceSeats + [playerSeat] + activeTeamSeats
    }
}
