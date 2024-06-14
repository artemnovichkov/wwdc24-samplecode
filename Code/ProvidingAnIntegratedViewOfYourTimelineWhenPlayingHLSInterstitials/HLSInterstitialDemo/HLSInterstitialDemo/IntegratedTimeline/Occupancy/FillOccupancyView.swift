/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show a fill occupany interstitial.
*/
import Foundation
import SwiftUI

struct FillOccupancyView: View {
    let height: CGFloat
    let fillWidth: Double
    let fillXStart: Double
    let asPrimary: Bool
    
    var body: some View {
        if asPrimary {
            // Show filled-in rectangle with the same color as the primary content.
            Rectangle()
                .foregroundStyle(Color.gray.opacity(0))
                .frame(width: fillWidth, height: height)
                .offset(x: fillXStart)
        } else {
            // Show filled-in rectangle with a different color from the primary content.
            Rectangle()
                .foregroundStyle(Color.yellow.opacity(0.8))
                .frame(width: fillWidth, height: height)
                .offset(x: fillXStart)
        }
        
    }
    
}
