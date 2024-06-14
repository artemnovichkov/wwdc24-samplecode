# RealityGestures

A package to make interating with entities as easy as pinch + drag.

---

The main entry points to RealityGestures are `RealityDragComponent` and `RealityTapComponent`. 

## RealityDragComponent

Adding a RealityDragComponent to your entity gives you a simple, sophisticated way to manipulate that entity in a 3D environment, leveraging various constraints to guide these interactions.

To pick up these gestures, you will also need to add a gesture of type `RealityDragGesture` to your `RealityView`, or use the modifier `addRealityDragGesture()` on the `RealityView`.

## Examples

The most basic of examples is as such:

```swift
let dragComponent = RealityDragComponent()
```

This will allow you to drag this entity freely while also allowing for rotations that match your hand's orientation changes.

If you instead want the orientation locked, you can use the initialiser parameter `isRotationLocked`:

```swift
let dragComponent = RealityDragComponent(isRotationLocked: true)
```

Now the entity will move freely as before, but will not change its orientation.

To add some basic constraints, you can set a BoundingBox. The entity will move freely within the box, and will stop at the edges:

```swift
let dragComponent = RealityDragComponent(
    clamp: .box(BoundingBox(min: [-1, 0, 0], max: [1, 0, 0]))
)
```

### Callback

A callback function can also be added to the RealityDragComponent, allowing you to get updates whenever the position or state of the entity updates.

```swift
func entityCallback(gesture: EntityTargetValue<DragGesture.Value>, status: RealityDragComponent.DragStatus) {
    guard status == .updated,
          let modEntity = gesture.entity as? ModelEntity
    else { return }

    modEntity.model?.materials = [UnlitMaterial(color: modEntity.position.x < 0 ? .red : .green)]
}

let dragComponent = RealityDragComponent(dragUpdate: entityCallback(gesture:status:))
```

In this example, the color of the entity's material will change to red on the left side of its containing view, and green on the right.
