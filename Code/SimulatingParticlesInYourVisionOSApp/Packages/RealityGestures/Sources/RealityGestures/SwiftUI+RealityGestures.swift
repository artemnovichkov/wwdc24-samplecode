/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Gesture subclasses for tap and drag handlers.
*/

import RealityKit
import SwiftUI

/// Gesture that catches taps on entities with ``RealityTapComponent``.
public struct RealityTapGesture: Gesture {
    /// The required number of taps to complete the tap gesture.
    public var count: Int
    public var body: some Gesture {
        SpatialTapGesture(count: count, coordinateSpace: .global).targetedToEntity(
            where: .has(RealityTapComponent.self)
        ).onEnded { value in
            value.entity.components.get(RealityTapComponent.self)?.action(value)
        }
    }

    /// Creates a tap gesture for ``RealityTapGesture`` entities with the number of required taps.
    /// - Parameter count: The required number of taps to complete the tap gesture
    public init(count: Int = 1) {
        self.count = count
    }
}

/// Gesture that catches drags on entities with ``RealityDragComponent``
public struct RealityDragGesture: Gesture {
    /// The minimum dragging distance for the gesture to succeed.
    public let minimumDistance: CGFloat
    /// Optional gesture update function to know when the gesture begins, updates, and ends.
    private var updated: ((EntityTargetValue<DragGesture.Value>, RealityDragComponent.DragStatus) -> Void)?

    public var body: some Gesture {
        DragGesture(minimumDistance: self.minimumDistance, coordinateSpace: .global)
            .targetedToEntity(where: .has(RealityDragComponent.self))
            .onChanged(gestureValueChanged(value:))
            .onEnded(gestureEnded(value:))
    }

    /// Add a callback to the gesture to know when it begins, updates and ends.
    /// - Parameter action: Event to be called on each gesture update.
    /// - Returns: A gesture that triggers action when this gesture updates.
    public mutating func onUpdated(
        _ action: @escaping (EntityTargetValue<DragGesture.Value>, RealityDragComponent.DragStatus) -> Void
    ) -> Self {
        self.updated = action
        return self
    }

    /// Internal gesture update callback, which updates the entity's position and orientation.
    /// - Parameter value: Gesture value.
    internal func gestureValueChanged(value: EntityTargetValue<DragGesture.Value>) {
        guard let dragComp = value.entity.components[RealityDragComponent.self],
              dragComp.isEnabled, let entityParent = value.entity.parent
        else { return }
        let endPos = value.convert(value.location3D, from: .global, to: entityParent)

        if dragComp.dragData == nil {
            dragComp.dragStarted(value.entity, parentPos: endPos)
            Task { @MainActor in
                dragComp.dragUpdate(value, .started)
                self.updated?(value, .started)
            }
        } else {
            var deviceDeltaRot: simd_quatf?
            if !dragComp.rotationLocked,
               let devicePose = value.inputDevicePose3D,
               let startDevicePose = value.startInputDevicePose3D {
                let endDeviceRot = value.convert(devicePose.rotation, from: .global, to: entityParent)
                let startDeviceRot = value.convert(startDevicePose.rotation, from: .global, to: entityParent)
                deviceDeltaRot = endDeviceRot * startDeviceRot.inverse
            }
            let deviceDeltaPos = endPos - value.convert(value.startLocation3D, from: .global, to: entityParent)

            dragComp.dragUpdated(value.entity, posDelta: deviceDeltaPos, deviceRot: deviceDeltaRot)
            Task { @MainActor in
                dragComp.dragUpdate(value, .updated)
                self.updated?(value, .updated)
            }
        }
    }

    /// Interal gesture end callback.
    /// - Parameter value: Gesture value.
    internal func gestureEnded(value: EntityTargetValue<DragGesture.Value>) {
        guard let dragComp = value.entity.components[RealityDragComponent.self],
              dragComp.dragData != nil else { return }
        let endPos = value.convert(value.location3D, from: .global, to: .scene)

        dragComp.dragEnded(value.entity, worldPos: endPos)
        Task { @MainActor in
            dragComp.dragUpdate(value, .ended)
            self.updated?(value, .ended)
        }
    }

    /// Creates a dragging gesture for all entities with ``RealityDragComponent``,
    /// with the minimum dragging distance before the gesture succeeds.
    /// - Parameter minimumDistance: The minimum dragging distance for the gesture to succeed.
    public init(minimumDistance: CGFloat = 10) {
        self.minimumDistance = minimumDistance
    }
}
