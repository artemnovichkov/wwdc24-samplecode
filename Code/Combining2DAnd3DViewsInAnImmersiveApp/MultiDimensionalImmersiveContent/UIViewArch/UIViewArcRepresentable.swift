/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shows the `UIView` arch in a SwiftUI view.
*/
 
import SwiftUI
import UIKit

/// Represents a UIKit `UIView` in a SwiftUI context.
struct UIViewArcViewRep: UIViewRepresentable {
     let color: Color
    
    func makeUIView(context: Context) -> UIViewArcView {
        let uiViewArc = UIViewArcView(color: UIColor(color))
        uiViewArc.centerAngle = 1.5 * .pi
        
        return uiViewArc
    }
    
    func updateUIView(_ uiView: UIViewArcView, context: Context) {
        /* Use this method to update the configuration of your view to match the new state information in the context parameter.
         Because there aren't any changes from SwiftUI affecting the UIKit views, do nothing. */
        
    }
}
