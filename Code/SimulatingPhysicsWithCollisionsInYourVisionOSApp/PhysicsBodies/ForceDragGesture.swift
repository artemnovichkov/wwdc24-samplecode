/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines a SwiftUI gesture that applies a force to an entity in a RealityKit
 scene.
*/

import SwiftUI
import RealityKit

struct ForceDragGesture: Gesture {

    var body: some Gesture {
        EntityDragGesture { entity, targetPosition in
            guard let modelEntity = entity as? ModelEntity else { return }

            let spherePosition = entity.position(relativeTo: nil)

            let direction = targetPosition - spherePosition
            var strength = length(direction)
            if strength < 1.0 {
                strength *= strength
            }

            let forceFactor: Float = 3000
            let force = forceFactor * strength * simd_normalize(direction)
            modelEntity.addForce(force, relativeTo: nil)
        }
    }
}
