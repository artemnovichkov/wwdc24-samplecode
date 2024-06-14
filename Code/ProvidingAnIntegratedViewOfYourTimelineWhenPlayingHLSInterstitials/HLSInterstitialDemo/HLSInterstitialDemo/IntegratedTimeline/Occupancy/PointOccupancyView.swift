/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show a point occupancy interstitial.
*/
import Foundation
import SwiftUI

struct PointOccupancyView: View {
    let diameter: CGFloat
    let pointXPos: Double
    
    var body: some View {
        // Show filled-in circle.
        Circle()
            .foregroundStyle(Color.yellow.opacity(0.8))
            .frame(width: diameter, height: diameter)
            .offset(x: max(pointXPos - (diameter / 2), 0))
    }
    
}
