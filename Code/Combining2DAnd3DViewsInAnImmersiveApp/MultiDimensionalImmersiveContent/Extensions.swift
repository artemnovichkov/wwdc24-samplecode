/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions on `UIBezierPath` and `ShapeResource`.
*/

import UIKit
import RealityKit

typealias Radians = CGFloat

// MARK: Extensions on `UIBezierPath`
extension UIBezierPath {
    
    /// - Returns: A `UIBezierPath` in the shape of an arc.
    static func createArcWithPath(bounds: CGRect, centerAngle: Radians) -> UIBezierPath {
        let outerRadius = min(bounds.size.width, bounds.size.height) / 2
        let innerRadius = outerRadius / 1.2
        let path = self.arc(bounds: bounds, innerRadius: innerRadius, outerRadius: outerRadius, centerAngle: centerAngle)
        path.apply(CGAffineTransform(translationX: bounds.midX, y: bounds.midY))
        return path
    }
    
    /// Fills a path between two arcs.
    static func arc(bounds: CGRect, innerRadius: CGFloat, outerRadius: CGFloat, centerAngle: Radians) -> UIBezierPath {
        let innerAngle: Radians = CGFloat.pi / 2
        let outerAngle: Radians = CGFloat.pi / 2
        
        // The first arc's start and end angles.
        let startAngleArcOne = centerAngle - innerAngle
        let endAngleArcOne = centerAngle + innerAngle
        
        // The second arc's start and end angles.
        let startAngleArcTwo = centerAngle + outerAngle
        let endAngleArcTwo = centerAngle - outerAngle
        
        let path = UIBezierPath()
        
        // Arc one.
        path.addArc(withCenter: .zero, radius: innerRadius, startAngle: startAngleArcOne, endAngle: endAngleArcOne, clockwise: true)
        
        // Arc two.
        path.addArc(withCenter: .zero, radius: outerRadius, startAngle: startAngleArcTwo, endAngle: endAngleArcTwo, clockwise: false)
        path.close()
        
        return path
    }
    
}
