/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension of RealityDragComopnent for more drag handling.
*/

import RealityKit

// Extension for SIMD3<Double>
extension SIMD3 where Scalar == Double {
    func toFloat3() -> SIMD3<Float> {
        return SIMD3<Float>(Float(self.x), Float(self.y), Float(self.z))
    }
}

extension RealityDragComponent {
    /// Called when a drag interaction starts.
    ///
    /// - Parameters:
    ///   - entity: The entity involved in the drag interaction.
    ///   - worldPos: A position in world space where the touch/drag is currently targeting.
    @discardableResult
    public func dragStarted(
        _ entity: Entity, parentPos: SIMD3<Float>
    ) -> Bool {
        let isDynamic = entity.components[PhysicsBodyComponent.self]?.mode == .dynamic
        self.dragData = .move(
            poi: entity.position, rot: entity.orientation,
            dynamicBody: isDynamic ? entity.components[PhysicsBodyComponent.self] : nil
        )
        if isDynamic {
            entity.components[PhysicsBodyComponent.self]?.isAffectedByGravity = false
        }
        return true
    }

    /// Called when a drag interaction is updated.
    ///
    /// - Parameters:
    ///   - entity: The entity involved in the drag interaction.
    ///   - worldPos: A position in world space where the touch/drag is currently targeting
    public func dragUpdated(
        _ entity: Entity, posDelta: SIMD3<Float>, deviceRot: simd_quatf?
    ) {
        guard let dragData else { return }

        switch dragData {
        case .move(let poi, let rot, let dynamicBody):
            var targetOrient: simd_quatf = entity.transform.rotation
            var targetPos: simd_float3 = entity.position
            if !self.rotationLocked, let rot, let newOrient = self.handleRotationState(entity, deviceRot, rot) {
                targetOrient = newOrient.normalized
                if dynamicBody == nil {
                    entity.transform.rotation = targetOrient
                }
            }
            if let newMovePos = self.handleMoveState(entity, posDelta, poi) {
                targetPos = newMovePos
                if dynamicBody == nil { entity.position = newMovePos }
            }
            if dynamicBody != nil {
                entity.components.set(GeneralGoalComponent(
                    linear: GeneralGoal(target: targetPos, strength: 20),
                    angular: GeneralGoal(target: targetOrient, strength: 20)
                ))
            }
        }
    }

    /// Called when a drag interaction ends.
    ///
    /// - Parameters:
    ///   - entity: The entity involved in the drag interaction.
    ///   - worldPos: A position in world space where the touch/drag is currently targeting
    public func dragEnded(_ entity: Entity, worldPos: SIMD3<Float>) {
        entity.components.remove(GeneralGoalComponent.self)

        // set dynamic body if we saved one
        if let body = switch self.dragData {
        case .move(_, _, let dynamicBody): dynamicBody
        default: nil
        } {
            entity.components.set(body)
        }

        self.dragData = nil
    }

    /// Called when a drag interaction is cancelled.
    ///
    /// - Parameter entity: The entity involved in the drag interaction.
    public func dragCancelled(_ entity: Entity) {
        dragData = nil
    }
}
