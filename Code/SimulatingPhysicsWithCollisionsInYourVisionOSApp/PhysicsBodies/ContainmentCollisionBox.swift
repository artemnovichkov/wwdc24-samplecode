/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines a type that conforms to RealityKit's Entity class, which creates a box with collision physics and updates it.
*/

import RealityKit

/// An entity that creates six boxes to form an invisible container with six faces,
/// each of which has collisions physics.
class ContainmentCollisionBox: Entity {
    var lastBoundingBox: BoundingBox?

    func update(_ boundingBox: BoundingBox) {
        // Don't update this if the bounds are the same.
        guard boundingBox != lastBoundingBox else {
            return
        }

        // Store the current bounds for the next update.
        lastBoundingBox = boundingBox

        // Remove the existing faces.
        children.removeAll()

        // Define the constants for the faces' geometry for conveinence.
        let min = boundingBox.min
        let max = boundingBox.max
        let center = boundingBox.center

        let lHandFace = SIMD3<Float>(x: min.x, y: center.y, z: center.z)
        let rHandFace = SIMD3<Float>(x: max.x, y: center.y, z: center.z)
        let lowerFace = SIMD3<Float>(x: center.x, y: min.y, z: center.z)
        let upperFace = SIMD3<Float>(x: center.x, y: max.y, z: center.z)
        let nearFace = SIMD3<Float>(x: center.x, y: center.y, z: min.z)
        let afarFace = SIMD3<Float>(x: center.x, y: center.y, z: max.z)

        // Make each box relatively thin.
        let thickness = Float(1E-3)

        // Configure the size for the left and right faces.
        var size = boundingBox.extents
        size.x = thickness

        // Create the left face of the collision containment cube.
        var face = Entity.boxWithCollisionPhysics(lHandFace, size)
        addChild(face)

        // Create the right face of the collision containment cube.
        face = Entity.boxWithCollisionPhysics(rHandFace, size)
        addChild(face)

        // Configure the size for the top and bottom faces.
        size = boundingBox.extents
        size.y = thickness

        // Create the bottom face of the collision containment cube.
        face = Entity.boxWithCollisionPhysics(lowerFace, size)
        addChild(face)

        // Create the top face of the collision containment cube.
        face = Entity.boxWithCollisionPhysics(upperFace, size)
        addChild(face)

        // Configure the size for the near and far faces.
        size = boundingBox.extents
        size.z = thickness

        // Create the near face of the collision containment cube.
        face = Entity.boxWithCollisionPhysics(nearFace, size)
        addChild(face)

        // Create the far face of the collision containment cube.
        face = Entity.boxWithCollisionPhysics(afarFace, size)
        addChild(face)
    }
}
