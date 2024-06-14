/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A 2D arrow shape.
*/
import SwiftUI

struct Arrow: Shape {
    
    func path(in rect: CGRect) -> Path {
        
        var path = Path()
        if rect.isEmpty {
            return path
        }
        
        let arrowHeadPercentWidth = CGFloat(0.5)
        let arrowHeadHeight = CGFloat(8.0)
        let arrowBodyHeight = CGFloat(4.0)
        
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + arrowBodyHeight))
        path.addLine(to: CGPoint(x: rect.maxX * arrowHeadPercentWidth, y: rect.midY + arrowBodyHeight))
        path.addLine(to: CGPoint(x: rect.maxX * arrowHeadPercentWidth, y: rect.midY + arrowHeadHeight))

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        
        path.addLine(to: CGPoint(x: rect.maxX * arrowHeadPercentWidth, y: rect.midY - arrowHeadHeight))
        path.addLine(to: CGPoint(x: rect.maxX * arrowHeadPercentWidth, y: rect.midY - arrowBodyHeight))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY - arrowBodyHeight))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        
        return path
        
    }
    
}
