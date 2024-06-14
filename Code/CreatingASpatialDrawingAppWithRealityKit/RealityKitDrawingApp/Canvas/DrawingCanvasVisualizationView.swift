/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view which displays a ring-shaped visualization of the drawing canvas in your immersive space.
*/

import RealityKit
import SwiftUI

/// A view that displays a ring-shaped mesh visualization of the drawing canvas in your immersive space.
///
/// The mesh is automatically regenerated when a new canvas is selected.
struct DrawingCanvasVisualizationView: View {
    let settings: DrawingCanvasSettings
    private let visualization = Entity()

    var body: some View {
        RealityView { content in
            DrawingCanvasVisualizationSystem.registerSystem()

            var descriptor = UnlitMaterial.Program.Descriptor()
            descriptor.blendMode = .add

            let program = await UnlitMaterial.Program(descriptor: descriptor)
            var material = UnlitMaterial(program: program)
            material.color = UnlitMaterial.BaseColor(tint: #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1))

            visualization.components.set(DrawingCanvasVisualizationComponent(settings: settings, material: material))
            content.add(visualization)
        }
    }
}

/// A transient component that visualizes a 3D drawn geometry.
struct DrawingCanvasVisualizationComponent: TransientComponent {
    public static let extrusionDepth: Float = 0.05

    static func generateMesh(radius: Float) throws -> MeshResource {
        let outerRadius = CGFloat(radius)
        let innerRadius = CGFloat(outerRadius - 0.02)

        return try Self.generateMesh(innerRadius: innerRadius, outerRadius: outerRadius)
    }

    static func generateMesh(innerRadius: CGFloat, outerRadius: CGFloat) throws -> MeshResource {
        // Generate two concentric circles as a SwiftUI path.
        let path = Path { path in
            // A circle is an arc that spans 360 degrees.
            path.addArc(center: .zero,
                        radius: outerRadius,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360),
                        clockwise: true)

            path.addArc(center: .zero,
                        radius: innerRadius,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360),
                        clockwise: true)

            // Normalize the path to use an even-odd fill mode.
            // This ensures that the path is interpreted as a ring shape.
            path = path.normalized(eoFill: true)
        }
        // Set the resolution of the generated geometry and extrusion depth.
        var extrusionOptions = MeshResource.ShapeExtrusionOptions()
        extrusionOptions.boundaryResolution = .uniformSegmentsPerSpan(segmentCount: 64)
        extrusionOptions.extrusionMethod = .linear(depth: extrusionDepth)

        // Generate a `MeshResource` from the SwiftUI path.
        return try MeshResource(extruding: path, extrusionOptions: extrusionOptions)
    }
    
    /// The app state that defines the active drawing canvas.
    let settings: DrawingCanvasSettings

    /// The radius of the active mesh for visualization, or `nil` if no mesh has been created.
    ///
    /// Compare this against ``DrawingCanvasSettings/radius`` to know if the mesh needs to be regenerated.
    var meshedRadius: Float?
    
    /// The material of the visualization mesh.
    var material: RealityKit.Material
}

/// A system that updates the mesh drawn on entities that have a drawing canvas visualization component.
private struct DrawingCanvasVisualizationSystem: System {

    private static let visualizationQuery = EntityQuery(where: .has(DrawingCanvasVisualizationComponent.self))

    init(scene: RealityKit.Scene) {
        DrawingCanvasVisualizationComponent.registerComponent()
    }

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.visualizationQuery, updatingSystemWhen: .rendering) {
            var visualization = entity.components[DrawingCanvasVisualizationComponent.self]!

            let settings = visualization.settings
            let previousRadius = visualization.meshedRadius ?? 0
            let extrusionDepth = DrawingCanvasVisualizationComponent.extrusionDepth
            
            // The indicator mesh is centered in Y, so it should be positioned at half extrusion depth above the floor.
            var translation = settings.placementPosition
            translation.y = settings.floorHeight + extrusionDepth / 2
            
            // `MeshResource(extruding:)` extrudes in Z. Rotate the entity to extrude in Y.
            let rotation = simd_quatf(from: [0, 0, 1], to: [0, 1, 0])

            // Move the canvas visualization to the computed pose.
            entity.move(to: Transform(rotation: rotation, translation: translation), relativeTo: nil)

            // If the entity is enabled and the radius is different from the previous one,
            // recompute the visualization mesh.
            if !approximatelyEqual(settings.radius, previousRadius) && settings.placementEntity.isEnabled {
                if let mesh = try? DrawingCanvasVisualizationComponent.generateMesh(radius: settings.radius) {
                    visualization.meshedRadius = settings.radius

                    let model = ModelComponent(mesh: mesh, materials: [visualization.material])
                    entity.components.set([visualization, model])
                }
            }
        }
    }
}
