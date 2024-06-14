/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates a `CALayer` arch.
*/

import UIKit
import SwiftUI

/// Draws an arc in a `UIView` using `CAShapeLayer`.
class CALayerArcView: UIView {
    var arc = CAShapeLayer()
    var centerAngle: Radians = 0
    let color: Color
    
    init(color: Color) {
        self.color = color
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layer.addSublayer(arc)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if CGRectEqualToRect(arc.frame, .zero) {
            arc.frame = bounds
            arc.fillColor = UIColor(color).cgColor
            arc.path = UIBezierPath.createArcWithPath(bounds: self.bounds, centerAngle: centerAngle).cgPath
        }
    }
}
