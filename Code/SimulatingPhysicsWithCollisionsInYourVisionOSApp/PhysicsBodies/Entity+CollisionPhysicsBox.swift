/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Adds a method to RealityKit's Entity class that creates a box
 with collision physics.
*/

import RealityKit

/// The default mass for a new box.
private let defaultMass1Kg = Float(1.0)

extension Entity {
    /// Creates an entity with a box shape that defines its collision and
    /// physics body components.
    /// - Parameters:
    ///   - location: The coordinates of the box, in meters.
    ///   - boxSize: The dimensions of the box, in meters.
    ///   - boxMass: The mass of the box, in kilograms.
    static func boxWithCollisionPhysics(
        _ location: SIMD3<Float>,
        _ boxSize: SIMD3<Float>,
        boxMass: Float = defaultMass1Kg
    ) -> Entity {
        // Create an entity for the box.
        let boxEntity = Entity()

        // Create the box's shape from the size.
        let boxShape = ShapeResource.generateBox(size: boxSize)

        // Create a collision component with the box's shape.
        let collisionComponent = CollisionComponent(
            shapes: [boxShape],
            isStatic: true)

        // Create a physics body component with the box's shape.
        let physicsBodyComponent = PhysicsBodyComponent(
            shapes: [boxShape],
            mass: boxMass,
            mode: PhysicsBodyMode.static
        )

        // Set the entity's position in the scene.
        boxEntity.position = location

        // Add the collision physics to the box entity.
        boxEntity.components.set(collisionComponent)
        boxEntity.components.set(physicsBodyComponent)
        return boxEntity
    }
}
