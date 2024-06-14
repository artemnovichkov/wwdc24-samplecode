/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that generates visible particles.
*/

import SwiftUI
import RealityKit
import RealityGestures

/// Stores and displays the entity that creates particles.
public struct EmitterView: View {
    /// Stores the particle emitter's current configuration.
    ///
    /// A person can change the particle emitter's behavior
    /// by changing the settings in a ``EmitterControls`` view.
    @EnvironmentObject var emitterSettings: EmitterSettings

    /// The entity that emits the particles.
    var emitterEntity: Entity {
        emitterSettings.emitterEntity
    }

    /// The main view for the particle emitter.
    public var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                buildEmitterContent(content, with: geometry.size.vector)
            } update: { content in
                // Update the entity's particle emitter component with the current values.
                emitterEntity.components.set(emitterSettings.emitterComponent)

                updateEmitterBounds(content, with: geometry.size.vector)
            }.gesture(RealityDragGesture())
        }.task { emitterSettings.updateEmitter() }
    }

    /// Builds a scene with a movable entity that emits particles.
    /// - Parameters:
    ///   - content: The content from a RealityView instance.
    ///   - geometryVector: The 3D bounding volume that defines where the emitter can create new particles.
    func buildEmitterContent(_ content: RealityViewContent,
                             with geometryVector: SIMD3<Double>) {
        // Add the emitter component to the entity.
        emitterEntity.components.set(emitterSettings.emitterComponent)

        // Add the emitter entity to the scene.
        content.add(emitterEntity)

        // Reposition the emitter entity.
        let viewSize = content.convert(Size3D(vector: geometryVector), from: .local, to: emitterEntity.parent!)
        let boundingBox = BoundingBox(min: -abs(viewSize) / 2.5, max: abs(viewSize) / 2.5)

        // Set a drag component so a person can move the particle emitter around the scene.
        emitterEntity.components.set(
            RealityDragComponent(clamp: .box(boundingBox))
        )

        // Set the particle entity's starting position halfway between the bottom and the middle of the view.
        emitterEntity.position.y = boundingBox.min.y + boundingBox.max.y * 0.5

        // Add the entity's collision shape.
        emitterEntity.components.set(
            CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])])
        )

        // Configure the entity to highlight itself when someone looks at it.
        emitterEntity.components.set(HoverEffectComponent())

        // Configure the entity to receive input.
        emitterEntity.components.set(InputTargetComponent())

        // Configure the entity so that it's translucent.
        emitterEntity.components.set(OpacityComponent(opacity: 0.3))
    }

    /// Recalculates the invisible bounding box that defines where a person
    /// can move the emitter around the scene with a drag gesture.
    ///
    /// The method repositions the box if a person moves the entity outside its bounds.
    /// - Parameters:
    ///   - content: The content of a RealityView in the scene.
    ///   - geometryVector: A 3D vector that represents the volume where the
    ///   entity can create new particles.
    func updateEmitterBounds(_ content: RealityViewContent,
                             with geometryVector: SIMD3<Double>) {
        // Recalculate the bounding box for the emitter.
        let viewSize = content.convert(
            Size3D(vector: geometryVector), from: .local,
            to: emitterEntity
        )
        let boundingBox = BoundingBox(min: -abs(viewSize) / 2.5,
                                      max: abs(viewSize) / 2.5)

        let dragComponent = RealityDragComponent(clamp: .box(boundingBox))
        emitterEntity.components.set(dragComponent)

        // If the entity has moved outside the window, re-center it.
        if boundingBox.contains(emitterEntity.position) {
            return
        }

        let height = boundingBox.min.y + boundingBox.max.y * 0.5
        emitterEntity.position = [0, height, 0]
        emitterEntity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
    }
}

#Preview {
    EmitterView()
        .environment(EmitterSettings())
        .glassBackgroundEffect()
}
