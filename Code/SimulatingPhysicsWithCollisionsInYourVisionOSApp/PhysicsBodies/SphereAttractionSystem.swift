/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines a RealityKit system that applies an attractive force to all other
 entities in the system component.
*/

import RealityKit

struct SphereAttractionSystem: System {
    // Convenience property for the update method.
    let entityQuery: EntityQuery

    init(scene: RealityKit.Scene) {
        let attractionComponentType = SphereAttractionComponent.self
        entityQuery = EntityQuery(where: .has(attractionComponentType))
    }

    func update(context: SceneUpdateContext) {
        let sphereEntities = context.entities(
            matching: entityQuery,
            updatingSystemWhen: .rendering
        )

        for case let sphere as ModelEntity in sphereEntities {
            var aggregateForce: SIMD3<Float>

            // Start with a force back to the center.
            let centerForceStrength = Float(0.05)
            let position = sphere.position(relativeTo: nil)
            let distanceSquared = length_squared(position)

            // Set the initial force with the inverse-square law.
            aggregateForce = normalize(position) / distanceSquared

            // Direct the force back to the center by negating the position vector.
            aggregateForce *= -centerForceStrength
            
            let neighbors = context.entities(matching: entityQuery,
                                             updatingSystemWhen: .rendering)

            for neighbor in neighbors where neighbor != sphere {

                let spherePosition = sphere.position(relativeTo: nil)
                let neighborPosition = neighbor.position(relativeTo: nil)

                let distance = length(neighborPosition - spherePosition)

                // Calculate the force from the sphere to the neighbor.
                let forceFactor = Float(0.1)
                let forceVector = normalize(neighborPosition - spherePosition)
                let neighborForce = forceFactor * forceVector / pow(distance, 2)
                aggregateForce += neighborForce
            }

            // Add the combined force from all the sphere's neighbors.
            sphere.addForce(aggregateForce, relativeTo: nil)
        }
    }
}
