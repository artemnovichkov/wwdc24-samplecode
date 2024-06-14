/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom spatial template used to arrange Spatial Personas
  during Guess Together's team-selection stage.
*/

import GroupActivities

/// The team selection template contains three sets of seats:
///
/// 1. Five audience seats that participants are initially placed in.
/// 2. Three Blue Team seats that participants are moved to
///    when they join team Blue.
/// 3. Three Red Team seats.
///
/// ```
///                ┌────────────────────┐
///                │   Guess Together   │
///                │     app window     │
///                └────────────────────┘
///
///
///              %                       $
///                %                   $
///   Blue Team      %               $      Red Team
///                    *  *  *  *  *
///
///                       Audience
/// ```
struct TeamSelectionTemplate: SpatialTemplate {
    enum Role: String, SpatialTemplateRole {
        case blueTeam
        case redTeam
    }
    
    let elements: [any SpatialTemplateElement] = [
        // Blue team:
        .seat(position: .app.offsetBy(x: -2.5, z: 3.5), role: Role.blueTeam),
        .seat(position: .app.offsetBy(x: -3.0, z: 3.0), role: Role.blueTeam),
        .seat(position: .app.offsetBy(x: -3.5, z: 2.5), role: Role.blueTeam),
        
        // Starting positions:
        .seat(position: .app.offsetBy(x: 0, z: 4)),
        .seat(position: .app.offsetBy(x: 1, z: 4)),
        .seat(position: .app.offsetBy(x: -1, z: 4)),
        .seat(position: .app.offsetBy(x: 2, z: 4)),
        .seat(position: .app.offsetBy(x: -2, z: 4)),
        
        // Red team:
        .seat(position: .app.offsetBy(x: 2.5, z: 3.5), role: Role.redTeam),
        .seat(position: .app.offsetBy(x: 3.0, z: 3.0), role: Role.redTeam),
        .seat(position: .app.offsetBy(x: 3.5, z: 2.5), role: Role.redTeam)
    ]
}
