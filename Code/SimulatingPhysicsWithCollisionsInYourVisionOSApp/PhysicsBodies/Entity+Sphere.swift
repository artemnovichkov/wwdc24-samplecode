/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Adds a method to RealityKit's Entity class that creates a sphere
 with collision physics.
*/

import RealityKit

import simd
import CoreGraphics

extension Entity {
    /// Creates an entity with a sphere that defines its collision and
    /// physics body components.
    /// - Parameters:
    ///   - radius: The radius of the sphere, in meters.
    static func metallicSphere(
        _ sphereRadius: Float = 0.15 * .random(in: (0.2)...(1.0))
    ) -> Entity {
        // Create the sphere entity with a spherical mesh.
        let sphereEntity = ModelEntity(
            mesh: MeshResource.generateSphere(radius: sphereRadius),
            materials: [metallicSphereMaterial()]
        )
        
        // Create the physics body from the same shape.
        let shape = ShapeResource.generateSphere(radius: sphereRadius)
        sphereEntity.components.set(CollisionComponent(shapes: [shape]))
        
        var physics = PhysicsBodyComponent(
            shapes: [shape],
            density: 10_000
        )

        // Make each sphere float in the air by turning off gravity.
        physics.isAffectedByGravity = false

        // Add the physics component to the sphere.
        sphereEntity.components.set(physics)

        // Place the sphere in a semi-random place in the scene.
        sphereEntity.position = SIMD3<Float>.random(in: -0.2...0.2)

        // Highlight the sphere when a person looks at it.
        sphereEntity.components.set(HoverEffectComponent())

        // Configure the sphere to receive gesture inputs.
        sphereEntity.components.set(InputTargetComponent())

        // Add an attaction force to the sphere.
        sphereEntity.components.set(SphereAttractionComponent())

        return sphereEntity
    }
}

/// Creates a metallic material for a sphere.
/// - Parameter hue: The color of the metallic material.
private func metallicSphereMaterial(
    hue: CGFloat = CGFloat.random(in: (0.0)...(1.0))
) -> PhysicallyBasedMaterial {
    var material = PhysicallyBasedMaterial()

    let color = RealityKit.Material.Color(
        hue: hue,
        saturation: CGFloat.random(in: (0.5)...(1.0)),
        brightness: 0.9,
        alpha: 1.0)

    material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: color)
    material.metallic = 1.0
    material.roughness = 0.5
    material.clearcoat = 1.0
    material.clearcoatRoughness = 0.1

    return material
}
