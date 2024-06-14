/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A tap gesture recognizer customized for the animal stamp.
*/

import UIKit

class StampGestureRecognizer: UITapGestureRecognizer {
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
      
#if os(iOS)
        UIPencilInteraction.addObserver(self, forKeyPath: prefersPencilOnlyDrawingKeyPath, options: [ .initial ], context: nil)
#endif
    }

    var angleInRadians: CGFloat = 0
    
    private let prefersPencilOnlyDrawingKeyPath = "prefersPencilOnlyDrawing"
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        
        if let firstTouch = touches.first {
            // Subtract the `rollAngle` instead of adding it, because it's defined to go in the opposite
            // direction from `azimuthAngle`.
            angleInRadians = firstTouch.azimuthAngle(in: self.view) - firstTouch.rollAngle
        } else {
            angleInRadians = 0
        }
    }
    
    override func reset() {
        super.reset()
        
        angleInRadians = 0
    }
    
#if os(iOS)
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if object as? Any.Type == UIPencilInteraction.self && keyPath == prefersPencilOnlyDrawingKeyPath {
            updateAllowedTouchTypes()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func updateAllowedTouchTypes() {
        if UIPencilInteraction.prefersPencilOnlyDrawing {
            self.allowedTouchTypes = [ NSNumber(value: UITouch.TouchType.pencil.rawValue) ]
        } else {
            self.allowedTouchTypes = [ NSNumber(value: UITouch.TouchType.direct.rawValue),
                                       NSNumber(value: UITouch.TouchType.indirectPointer.rawValue),
                                       NSNumber(value: UITouch.TouchType.pencil.rawValue) ]
        }
    }
#endif
    
}
