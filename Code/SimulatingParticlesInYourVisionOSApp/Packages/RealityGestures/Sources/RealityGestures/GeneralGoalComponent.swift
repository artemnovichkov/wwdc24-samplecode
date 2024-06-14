/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The component and system for moving an entity towards a goal.
*/

import RealityKit

/// This component is used to move an entity towards a position and orientation.
///
/// Used when there are other constraints in the scene that should be considered.
public struct GeneralGoalComponent: Component, Codable {
    public var linear: GeneralGoal<simd_float3>
    public var angular: GeneralGoal<simd_quatf>

    init(
        linear: GeneralGoal<simd_float3>,
        angular: GeneralGoal<simd_quatf>
    ) {
        GeneralGoalSystem.registerSystem()
        self.linear = linear
        self.angular = angular
    }
}

/// Target and strenght pairing for goal components.
public struct GeneralGoal<T: Codable>: Codable {
    public var target: T
    public var strength: Float = 1
}

extension simd_quatf: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let vector = try container.decode(simd_float4.self)
        self.init(vector: vector)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.vector)
    }
}

/// System for moving an entity to a desired position and orientation goal
internal struct GeneralGoalSystem: System {
    static let generalGoalQuery = EntityQuery(where: .has(GeneralGoalComponent.self))

    public init(scene: Scene) {}

    public mutating func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.generalGoalQuery).forEach { entity in
            guard let entity = entity as? ModelEntity,
                  let component = entity.components[GeneralGoalComponent.self]
            else { return }

            let linearForce = (component.linear.target - entity.position) * component.linear.strength
            let quat = (component.angular.target * entity.orientation.inverse).normalized
            var torque: simd_float3 = .zero
            if quat.angle != 0 {
                let axis = simd_normalize(quat.axis)
                let angle = quat.angle < .pi ? quat.angle : (quat.angle - .pi * 2)
                torque = axis * angle * component.angular.strength
            }

            entity.components.set(PhysicsMotionComponent(linearVelocity: linearForce, angularVelocity: torque))
        }
    }
}
