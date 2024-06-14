/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A RealityKit component and system to facilitate the generation of sparkle brush strokes.
*/

import Foundation
import RealityKit

struct SparkleBrushComponent: Component {
    var generator: SparkleDrawingMeshGenerator
    var material: Material
}

class SparkleBrushSystem: System {
    private static let query = EntityQuery(where: .has(SparkleBrushComponent.self))
    
    required init(scene: RealityKit.Scene) { }
    
    private var lastUpdateTime: Date?
    
    func update(context: SceneUpdateContext) {
        let now = Date.now
        let deltaTime = Float(lastUpdateTime?.distance(to: now) ?? 0)
        lastUpdateTime = now
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            let brushComponent: SparkleBrushComponent = entity.components[SparkleBrushComponent.self]!
            let generator = brushComponent.generator
            
            // Calls `update` on the generator.
            // This returns a non-nil `LowLevelMesh` if a new mesh had to be allocated.
            // This can happen when the number of samples exceeds the capacity of the mesh.
            //
            // If the generator returns a new `LowLevelMesh`,
            // apply to the entity's `ModelComponent`.
            try? generator.update(deltaTime: deltaTime) { newMesh in
                guard let resource = try? await MeshResource(from: newMesh) else { return }
                
                if entity.components.has(ModelComponent.self) {
                    entity.components[ModelComponent.self]!.mesh = resource
                } else {
                    let modelComponent = ModelComponent(mesh: resource, materials: [brushComponent.material])
                    entity.components.set(modelComponent)
                }
            }
        }
    }
}
