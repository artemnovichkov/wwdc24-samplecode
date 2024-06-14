/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates the `UIView` arch.
*/

import SwiftUI
import UIKit
  
/// Draws an arc in a `UIView`.
class UIViewArcView: UIView {
    var arc = UIBezierPath()
    var centerAngle: Radians = 0
    let color: UIColor
    
    init(color: UIColor) {
        self.color = color
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Overrides `draw(_ rect:)` to display the arch.
    override func draw(_ rect: CGRect) {
        arc = UIBezierPath.createArcWithPath(bounds: self.bounds, centerAngle: centerAngle)
        color.setFill()
        arc.fill()
    }
}
