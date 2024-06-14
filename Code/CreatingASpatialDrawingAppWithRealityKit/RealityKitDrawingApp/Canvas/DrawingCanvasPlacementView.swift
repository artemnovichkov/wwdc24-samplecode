/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that provides a user interface for controlling the location of the drawing canvas.
*/

import SwiftUI
import RealityKit
import RealityKitContent

/// A view that provides a user interface for controlling the location of the drawing canvas.
///
/// Use this view in an immersive space.
/// It uses a sphere-shaped handle with a `DragGesture`.
struct DrawingCanvasPlacementView: View {
    static let inputTargetRadius: Float = 0.04
    static let indicatorRadius: Float = 0.02
    static let dashedLineRadius: Float = 0.01
    
    /// The spatial tracking session required for floor anchor tracking.
    @State private var session: SpatialTrackingSession?
    
    let settings: DrawingCanvasSettings
    
    var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .targetedToEntity(where: .has(DrawingCanvasPlacementComponent.self))
            .onChanged { value in
                guard var placement = value.entity.components[DrawingCanvasPlacementComponent.self] else { return }

                // When the person drags the handle, unlock the handle from the "Place your canvas" window.
                placement.lockedToWindow = false

                // Compute the location of the drag gesture.
                var placementPosition = value.convert(value.location3D, from: .global, to: .scene)

                // If this is the beginning of the drag gesture,
                // note the offset between the initial drag gesture location
                // and the placement entity.
                if placement.dragGestureOffset == nil {
                    placement.dragGestureOffset = value.entity.position(relativeTo: nil) - placementPosition
                }

                // Preserve the offset computed above when the drag gesture started.
                placementPosition += placement.dragGestureOffset!

                // Move the entity to the computed position.
                // A duration of `0.2` provides a smooth interpolation.
                value.entity.move(to: Transform(translation: placementPosition), relativeTo: nil, duration: 0.2)
                value.entity.components.set(placement)
            }
            .onEnded { value in
                // Reset `dragGestureOffset` to `nil` when a drag gesture ends.
                guard var placement = value.entity.components[DrawingCanvasPlacementComponent.self] else { return }
                placement.dragGestureOffset = nil
                value.entity.components.set(placement)
            }
    }

    var body: some View {
        RealityView { content in
            DrawingCanvasPlacementSystem.registerSystem()

            let placementEntity = settings.placementEntity
            placementEntity.isEnabled = false

            // Begin a spatial tracking session to understand the location of the floor,
            // via a floor anchor.
            let session = SpatialTrackingSession()
            let configuration = SpatialTrackingSession.Configuration(tracking: [.plane])
            _ = await session.run(configuration)
            self.session = session

            var floorAnchor: AnchorEntity?
#if !targetEnvironment(simulator)
            // Create a floor anchor.
            // The entity's transform updates to the position of the floor anchor,
            // thanks to the `SpatialTrackingSession`.
            floorAnchor = AnchorEntity(plane: .horizontal, classification: .floor)
            content.add(floorAnchor!)
#endif

            // Load a shader graph material for the dashed line, which connects the handle to the floor.
            let dashedLine = Entity()
            if var material = try? await ShaderGraphMaterial(named: "/Root/DashedLineMaterial",
                                                             from: "CanvasPlacementMaterial",
                                                             in: realityKitContentBundle) {
                // Set `writesDepth` to false so that this material doesn't occlude other objects.
                material.writesDepth = false

                // Create a cylinder mesh for the ground indicator.
                let model = ModelComponent(
                    mesh: .generateCylinder(height: 1, radius: Self.dashedLineRadius),
                    materials: [material]
                )
                dashedLine.scale.y = 0
                dashedLine.components.set(model)
            }
            content.add(dashedLine)

            // Create a descriptor for the material of the placement handle, with additive blend mode.
            var descriptor = UnlitMaterial.Program.Descriptor()
            descriptor.blendMode = .add

            // Load the material program corresponding with `descriptor`.
            let program = await UnlitMaterial.Program(descriptor: descriptor)

            // Create an `UnlitMaterial` from the loaded program and set its color.
            var placementMaterial = UnlitMaterial(program: program)
            placementMaterial.color = .init(tint: .lightGray)

            // Assign the components of `placementEntity`.
            placementEntity.components.set([
                // Use a sphere-shaped handle.
                ModelComponent(mesh: .generateSphere(radius: Self.indicatorRadius),
                               materials: [placementMaterial]),

                // Add a `CollisionComponent` to determine where the handle can be dragged with `DragGesture`.
                CollisionComponent(shapes: [.generateSphere(radius: Self.inputTargetRadius)]),

                // Customize hover behavior with a highlight effect.
                HoverEffectComponent(.highlight(HoverEffectComponent
                    .HighlightHoverEffectStyle(color: #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1), strength: 5)
                )),

                // `InputTargetComponent` is required for `DragGesture`.
                InputTargetComponent(),

                // Set up this entity to control the placement of the drawing canvas.
                DrawingCanvasPlacementComponent(settings: settings,
                                                dashedLine: dashedLine,
                                                floorAnchor: floorAnchor)
            ])

            content.add(placementEntity)
        }
        .gesture(dragGesture)
    }
}

struct DrawingCanvasPlacementComponent: TransientComponent {
    /// The drawing canvas settings.
    ///
    /// This stores the app state of the drawing canvas.
    let settings: DrawingCanvasSettings

    /// The entity that visualizes the dashed line that connects the handle (this entity) with the ground.
    var dashedLine: Entity

    /// The offset of a drag gesture's position relative to the entity.
    ///
    /// If no drag gesture active, this property has a value of `nil`.
    var dragGestureOffset: SIMD3<Float>?

    /// A Boolean value that determines whether the placement component is locked to a position
    /// relative to the "Place your canvas" window.
    var lockedToWindow: Bool = true

    /// An anchor entity that tracks where the floor is.
    ///
    /// This position of this entity determines the value of ``DrawingCanvasSettings/floorHeight``.
    var floorAnchor: AnchorEntity?
}

private struct DrawingCanvasPlacementSystem: System {
    private static let placementQuery = EntityQuery(where: .has(DrawingCanvasPlacementComponent.self))

    init(scene: RealityKit.Scene) {
        DrawingCanvasPlacementComponent.registerComponent()
    }

    func update(context: SceneUpdateContext) {
        let indicatorRadius = DrawingCanvasPlacementView.indicatorRadius
        let dashedLineRadius = DrawingCanvasPlacementView.dashedLineRadius

        for handleEntity in context.entities(matching: Self.placementQuery, updatingSystemWhen: .rendering) {
            let placement = handleEntity.components[DrawingCanvasPlacementComponent.self]!
            let indicator = placement.dashedLine

            // Compute the floor height based on the placement of the floor anchor.
            let floorHeight = placement.floorAnchor?.position(relativeTo: nil).y ?? placement.settings.floorHeight
            placement.settings.floorHeight = floorHeight

            // Compute the position and scale of the dashed line to connect the handle and the floor.
            let yPos = handleEntity.isEnabled ? handleEntity.position(relativeTo: nil).y : floorHeight

            // Account for the radius of the dashed line and the handle
            // to prevent overlap between the two meshes.
            let top = yPos - sqrt(indicatorRadius * indicatorRadius - dashedLineRadius * dashedLineRadius)
            let bottom = floorHeight

            let yExtents = max(top - bottom, 0)
            let yCenter = (top + bottom) / 2

            var position = handleEntity.position(relativeTo: nil)
            position.y = yCenter

            // The height of the underlying mesh is 1 m; this scale
            // is equal the model's height.
            indicator.scale.y = yExtents
            indicator.setPosition(position, relativeTo: nil)
        }
    }
}
