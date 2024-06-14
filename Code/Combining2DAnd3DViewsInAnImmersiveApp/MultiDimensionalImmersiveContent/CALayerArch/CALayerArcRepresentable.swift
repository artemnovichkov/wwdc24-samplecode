/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shows the `CALayer` arch in a SwiftUI view.
*/

import UIKit
import SwiftUI

/// Represents a UIKit `UIView` in a SwiftUI context.
struct CALayerArcViewRep: UIViewRepresentable {
     let color: Color
    
    func makeUIView(context: Context) -> CALayerArcView {
        let caLayerArcView = CALayerArcView(color: color)
        caLayerArcView.centerAngle = 1.5 * .pi

        return caLayerArcView
    }
    
    func updateUIView(_ uiView: CALayerArcView, context: Context) {
        /* Use this method to update the configuration of your view to match the new state information in the context parameter.
         Because there aren't any changes from SwiftUI affecting the UIKit views, do nothing. */
    }
}

