/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contains the logic that represents the bounded canvas space.
*/

import RealityKit

/// The app state which controls the size and placement of the person's drawing canvas.
@Observable
class DrawingCanvasSettings {
    /// The size of the drawing canvas in meters.
    var radius: Float = 0.75

    /// The position of the user-provided placement dragger with respect to the immersive space.
    var placementPosition: SIMD3<Float> { placementEntity.position(relativeTo: nil) }

    /// An entity used to determine placement position.
    ///
    /// Add the entity to the immersive space.
    let placementEntity = Entity()

    /// The height of the floor when the canvas was placed.
    ///
    /// The app uses this value for representing the canvas visually.
    var floorHeight: Float = 0

    /// Returns a Boolean value that tells you if a point is considered inside of the drawing canvas.
    func isInsideCanvas(_ point: SIMD3<Float>) -> Bool {
        let localPos = point - placementPosition
        let localPos2 = SIMD2<Float>(localPos.x, localPos.z)
        return length(localPos2) < radius
    }
}
