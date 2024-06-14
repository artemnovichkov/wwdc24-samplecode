/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The component for tap events on entities.
*/

import RealityKit
import SwiftUI

/// ``RealityTapComponent`` is a component that allows entities to respond
/// to tap actions in the RealityKit environment.
///
/// When an entity is associated with a ``RealityTapComponent``, it indicates
/// that the entity should trigger an action when tapped.
/// There is also requirement for the entity to have a `CollisionComponent`.
///
/// The action is a closure that provides both the tapped entity and
/// the world position (if available) of the point where the entity was tapped.
///
/// > The world position might be `nil` if the exact point of collision cannot be determined.
///
/// Example usage:
/// ```swift
/// let entity: Entity = ...
/// entity.components.set(RealityTapComponent { gestureValue in
///     print("Entity \(gestureValue.entity.name) was tapped!")
/// })
/// ```
public struct RealityTapComponent: Component {
    /// The action to be triggered when the entity is tapped.
    ///
    /// - Parameters:
    ///   - Entity: The entity that was tapped.
    public var action: ((EntityTargetValue<SpatialTapGesture.Value>) -> Void)

    /// Create a new TapActionComponent object.
    /// - Parameter action: The action to be triggered when the entity is tapped.
    public init(action: @escaping ((EntityTargetValue<SpatialTapGesture.Value>) -> Void)) {
        self.action = action
    }
}
