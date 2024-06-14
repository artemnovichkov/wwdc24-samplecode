/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines a SwiftUI gesture that repositions an entity in a RealityKit scene.
*/

import SwiftUI
import RealityKit

struct RelocateDragGesture: Gesture {
    var body: some Gesture {
        EntityDragGesture { entity, targetPosition in
            entity.setPosition(targetPosition, relativeTo: nil)
        }
    }
}
