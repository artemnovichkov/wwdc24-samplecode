/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The component for handling drag events on an entity.
*/

import RealityKit
import SwiftUI

/// `RealityDragComponent` is a component for managing drag interactions in an AR or VR context.
/// It provides various constraints for dragging movements with constraints such as boxes, points and clamps.
public class RealityDragComponent: Component {

    /// Initializes a new `RealityDragComponent` with a specific drag interaction type and an optional delegate.
    ///
    /// - Parameters:
    ///   - isRotationLocked: If the rotation is locked during drag events. Default is false (free rotation)
    ///   - clamp: clamping for the movement, can be a bounding box, custom function, or other
    ///   - dragUpdate: Callback for all drag updates.
    public init(
        isRotationLocked: Bool = false,
        clamp: MoveConstraint? = nil,
        dragUpdate: @MainActor @escaping (
            EntityTargetValue<DragGesture.Value>, RealityDragComponent.DragStatus
        ) -> Void = { _, _ in }
    ) {
        self.rotationLocked = isRotationLocked
        self.clamp = clamp
        self.dragUpdate = dragUpdate
    }

    var rotationLocked: Bool
    var clamp: MoveConstraint?

    /// `MoveConstraint` defines the constraints that can be applied to the movement of entities in a 3D environment.
    ///
    /// This enumeration is used in conjunction with ``RealityDragComponent`` to specify how entities respond
    /// to drag interactions in AR or VR contexts.
    /// It offers various constraint options, each tailored to different interaction requirements,
    /// allowing for more controlled and precise entity movement.
    /// Depending on the chosen constraint, entities can be restricted to move within a bounding box,
    /// limited to predefined points, or constrained by a custom clamping function.
    ///
    /// Examples of where `MoveConstraint` can be beneficial include scenarios
    /// like guiding an entity along a specific path,
    /// confining movement within a certain area, or applying complex, custom movement rules.
    public enum MoveConstraint {
        /// Constrains movement within a bounding box.
        ///
        /// Use this constraint when you want to limit the movement of an entity
        /// within a predefined three-dimensional area.
        /// The `BoundingBox` parameter specifies the dimensions and position of the box
        /// within which the entity can move.
        ///
        /// Example usage:
        /// ```swift
        /// let constraint = MoveConstraint.box(
        ///     BoundingBox(min: [-1, -1, -1], max: [1, 1, 1])
        /// )
        /// ```
        case box(BoundingBox)
        /// Constrains movement to a set of points.
        ///
        /// This constraint limits the movement of an entity to specific locations in space,
        /// defined by an array of `SIMD3<Float>` points.
        /// It's useful for scenarios where movement should be restricted to discrete positions,
        /// like on a grid or along a path.
        ///
        /// Example usage:
        /// ```swift
        /// let constraint = MoveConstraint.points([
        ///     [0, 0, 0],
        ///     [5, 0, 0],
        ///     [10, 0, 0]
        /// ])
        /// ```
        case points([SIMD3<Float>])
        /// Applies a custom clamping function to the movement.
        ///
        /// This constraint allows for the most flexibility by enabling the use of a
        /// custom function to determine movement constraints.
        /// The function takes a `SIMD3<Float>` as input, representing the proposed new position,
        /// and returns a `SIMD3<Float>` that represents the allowed position.
        ///
        /// Example usage:
        /// ```swift
        /// let constraint = MoveConstraint.clamp { proposedPosition in
        ///     // Define custom logic to modify and return the proposed position
        ///     return modifiedPosition
        /// }
        /// ```
        case clamp(position: (SIMD3<Float>) -> SIMD3<Float>, rotation: (simd_quatf) -> simd_quatf)
    }
    /// ``DragComponentType`` represents the type of drag interaction in a 3D environment.
    ///
    /// This enumeration defines the different ways that drag interactions can be
    /// interpreted and handled within a 3D space.
    /// Each case of this enum specifies a unique type of drag interaction, allowing for customizable behavior
    /// depending on the user's input and the application's requirements.
    public enum DragComponentType {
        /// Represents a movement interaction with an optional constraint.
        case move(isRotationLocked: Bool = false, clamp: MoveConstraint? = nil)
    }

    var dragUpdate: @MainActor (
        EntityTargetValue<DragGesture.Value>, RealityDragComponent.DragStatus
    ) -> Void

    /// Whether the drag gesture should be enabled for this Entity.
    public var isEnabled: Bool = true

    public enum DragStatus {
        case started
        case updated
        case ended
    }

    /// The current touch state of the drag component.
    internal var dragData: DragData?

    /// `DragData` represents the state of the current in-progress touch in an AR/VR context.
    ///
    /// This enum is used to track the touch state, including the position
    /// and distance of the touch in relation to the AR object.
    internal enum DragData {

        /// Represents a move touch state in an AR environment.
        ///
        /// The `move` case is used when the object can move around in space.
        /// It provides details about the location of the initial touch and its distance from a point of view (POV).
        ///
        /// - Parameters:
        ///   - poi: A `SIMD3<Float>` value representing the place on the AR object where the touch first collided.
        ///          This gives the 3D coordinates of the initial touch point in the entity's local space.
        ///   - distance: A `Float` value indicating the distance from the POV (Point of View) to the first touch point.
        ///               This helps in understanding how far the touch point is from the user's perspective.
        ///   - dynamicBody: Added at the start of the drag if the body type of the entity is dynamic.
        ///                In this case, the entity will be moved via spring forces and torques,
        ///                and the body will be reset at the end of the drag.
        case move(poi: SIMD3<Float>, rot: simd_quatf?, dynamicBody: PhysicsBodyComponent? = nil)
    }

    /// Calculates the collision points based on the provided ray.
    ///
    /// - Parameter ray: A tuple containing the origin and direction of the ray.
    /// - Returns: The collision point as `SIMD3<Float>` if a collision occurs, otherwise `nil`.
    internal static func getCollisionPoints(
        with localPos: SIMD3<Float>, dragData: DragData?
    ) -> SIMD3<Float>? {
        switch dragData {
        case .move: localPos
        case .none: nil
        }
    }

    fileprivate static func getClampedPosition(
        _ moveConstraint: MoveConstraint?, _ endPos: SIMD3<Float>
    ) -> SIMD3<Float> {
        switch moveConstraint {
        case .box(let bbox): bbox.clamp(endPos)
        case .points(let points): RealityDragComponent.closestPoint(from: endPos, points: points)
        case .clamp(let clampPos, _): clampPos(endPos)
        case .none: endPos
        }
    }

    fileprivate static func getClampedRotation(
        _ moveConstraint: MoveConstraint?, _ endRot: simd_quatf
    ) -> simd_quatf {
        switch moveConstraint {
        case .clamp(_, let clampRot): clampRot(endRot)
        default: simd_quatf(vector: normalize(endRot.vector))
        }
    }

    internal func handleMoveState(
        _ entity: Entity, _ touchDelta: SIMD3<Float>?, _ poi: SIMD3<Float>
    ) -> SIMD3<Float>? {
        guard let touchDelta else { return nil }
        let endPos = poi + touchDelta
        return RealityDragComponent.getClampedPosition(self.clamp, endPos)
    }

    internal func handleRotationState(
        _ entity: Entity, _ newRotation: simd_quatf?, _ oldRotation: simd_quatf
    ) -> simd_quatf? {
        guard let newRotation else { return nil }
        let newOrient = (newRotation * oldRotation)
        return RealityDragComponent.getClampedRotation(self.clamp, newOrient)
    }

    internal static func closestPoint(from start: SIMD3<Float>, points: [SIMD3<Float>]) -> SIMD3<Float> {
        if points.isEmpty { return start }
        var bestPoint = points[0]
        var minDist = Float.infinity
        for point in points {
            let newDist = simd_distance_squared(start, point)
            if newDist < minDist {
                minDist = newDist
                bestPoint = point
            }
        }
        return bestPoint
    }
}

fileprivate extension BoundingBox {
    func clamp(_ position: SIMD3<Float>) -> SIMD3<Float> {
        [Swift.min(max.x, Swift.max(min.x, position.x)),
         Swift.min(max.y, Swift.max(min.y, position.y)),
         Swift.min(max.z, Swift.max(min.z, position.z))]
    }
}

extension Entity.ComponentSet {
    func get<T>(_ component: T.Type) -> T? where T: Component {
        self[T.self]
    }
}
