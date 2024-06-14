/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Logic for placing data points on the thematic map panel.
*/

import Foundation
import SwiftUI


// Inspired by the Albers equal area conic map projection centered on the lower 48 US states.
struct ThematicMapProjection: Sendable {
    var x, y: Double

    init(xLongitude: Angle, yLatitude: Angle) {
        let centralMeridian = Angle(degrees: -96.0).radians
        let theta = 0.5 * (xLongitude.radians - centralMeridian)
        let rho = 2.0 - sin(yLatitude.radians)
        self.x = rho * sin(theta)
        self.y = 1.0 - rho * cos(theta)
    }
}

