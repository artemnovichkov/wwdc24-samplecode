/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The visualization of an object anchor.
*/

import ARKit
import RealityKit
import SwiftUI

@MainActor
class ObjectAnchorVisualization {
    
    private let textBaseHeight: Float = 0.08
    private let alpha: CGFloat = 0.7
    private let axisScale: Float = 0.05
    
    var boundingBoxOutline: BoundingBoxOutline
    
    var entity: Entity

    init(for anchor: ObjectAnchor, withModel model: Entity? = nil) {
        boundingBoxOutline = BoundingBoxOutline(anchor: anchor, alpha: alpha)
        
        let entity = Entity()
        
        let originVisualization = Entity.createAxes(axisScale: axisScale, alpha: alpha)
        
        if let model {
            // Overwrite the model's appearance to a yellow wireframe.
            var wireframeMaterial = PhysicallyBasedMaterial()
            wireframeMaterial.triangleFillMode = .lines
            wireframeMaterial.faceCulling = .back
            wireframeMaterial.baseColor = .init(tint: .yellow)
            wireframeMaterial.blending = .transparent(opacity: 0.5)
            
            model.applyMaterialRecursively(wireframeMaterial)
            entity.addChild(model)
        }
        
        boundingBoxOutline.entity.isEnabled = model == nil
        
        entity.addChild(originVisualization)
        entity.addChild(boundingBoxOutline.entity)
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.isEnabled = anchor.isTracked
        
        let descriptionEntity = Entity.createText(anchor.referenceObject.name, height: textBaseHeight * axisScale)
        descriptionEntity.transform.translation.x = textBaseHeight * axisScale
        descriptionEntity.transform.translation.y = anchor.boundingBox.extent.y * 0.5
        entity.addChild(descriptionEntity)
        self.entity = entity
    }
    
    func update(with anchor: ObjectAnchor) {
        entity.isEnabled = anchor.isTracked
        guard anchor.isTracked else { return }
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        boundingBoxOutline.update(with: anchor)
    }
    
    @MainActor
    class BoundingBoxOutline {
        private let thickness: Float = 0.0025
        
        private var extent: SIMD3<Float> = [0, 0, 0]
        
        private var wires: [Entity] = []
        
        var entity: Entity

        fileprivate init(anchor: ObjectAnchor, color: UIColor = .yellow, alpha: CGFloat = 1.0) {
            let entity = Entity()
            
            let materials = [UnlitMaterial(color: color.withAlphaComponent(alpha))]
            let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])

            for _ in 0...11 {
                let wire = ModelEntity(mesh: mesh, materials: materials)
                wires.append(wire)
                entity.addChild(wire)
            }
            
            self.entity = entity
            
            update(with: anchor)
        }
        
        fileprivate func update(with anchor: ObjectAnchor) {
            entity.transform.translation = anchor.boundingBox.center
            
            // Update the outline only if the extent has changed.
            guard anchor.boundingBox.extent != extent else { return }
            extent = anchor.boundingBox.extent

            for index in 0...3 {
                wires[index].scale = SIMD3<Float>(extent.x, thickness, thickness)
                wires[index].position = [0, extent.y / 2 * (index % 2 == 0 ? -1 : 1), extent.z / 2 * (index < 2 ? -1 : 1)]
            }
            
            for index in 4...7 {
                wires[index].scale = SIMD3<Float>(thickness, extent.y, thickness)
                wires[index].position = [extent.x / 2 * (index % 2 == 0 ? -1 : 1), 0, extent.z / 2 * (index < 6 ? -1 : 1)]
            }
            
            for index in 8...11 {
                wires[index].scale = SIMD3<Float>(thickness, thickness, extent.z)
                wires[index].position = [extent.x / 2 * (index % 2 == 0 ? -1 : 1), extent.y / 2 * (index < 10 ? -1 : 1), 0]
            }
        }
    }
}
