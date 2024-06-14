/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates attachments and adds all entities and attachments to a `RealityView`.
*/

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor struct RainbowView: View {
    // MARK: - Properties
    @State private var rainbowModel = RainbowModel()
    
    // The root entity for the scene.
    private let root = Entity()
    
    var body: some View {
        RealityView { content, attachments in
            root.name = "root"
            
            // Create the plane entity.
            let planeEntity = await createEntity(for: rainbowModel.plane)
            
            // Add the plane as a subentity of the root.
            root.addChild(planeEntity)
            
            // Iterate over the green and yellow arches, which load through Reality Composer Pro.
            for (index, item) in rainbowModel.realityKitAssets.enumerated() {
                
                // Create the entity and set necessary components.
                let entity = await createEntity(for: item)
                
                // Add each entity to the root.
                planeEntity.addChild(entity)
                
                // Set the position to be 0.3 behind the first entity.
                entity.position.z = Float(-0.3 * Double(index))
            }
            // Set the position of the root and the plane.
            root.position = [0, -1, -3]
            planeEntity.setPosition([0, 0, 0], relativeTo: root)
            
            // Scale the plane entity and it's subentities to be taller.
            planeEntity.scale.y *= 1.2
            content.add(root)
            
        } update: { content, attachments in
            // MARK: - Update closure
            
            // Find entities from the scene necessary for positioning the attachments.
            let plane = root.findEntity(named: "plane")
            let yellowArch = root.findEntity(named: "yellow")
            
            // Find the visual bounds of the model entity.
            let yellowBounds = yellowArch?.findEntity(named: "yellow")!.visualBounds(relativeTo: plane)
            
            // Get the entities, scales, and positions that are to be added as attachments.
            let viewAttachmentArray = scaleAndPositionArches(yellowArchSize: yellowBounds ?? BoundingBox())
            
            // Add and configure attachments.
            for viewAttachmentEntity in viewAttachmentArray {
                
                // Check if there's an attachment.
                if let attachment = attachments.entity(for: "\(viewAttachmentEntity.entity.title)ArchAttachmentEntity") {
                    
                    attachment.name = viewAttachmentEntity.entity.title
                    
                    // Add it as a subentity of the plane.
                    plane?.addChild(attachment)
                    
                    // Set the scale and position.
                    attachment.scale = viewAttachmentEntity.scale
                    attachment.setPosition(viewAttachmentEntity.position, relativeTo: yellowArch)
                }
            }
        } attachments: {
            // MARK: - Attachments closure
            ForEach(rainbowModel.attachments) { entity in
                // Iterate over the attachments array and create the various arches.
                createArchAttachment(for: ArchAttachment(rawValue: entity.title)!)
            }
        }
    }
}
    
extension RainbowView {
    /// Creates an attachment based on the type of view passed in.
    func createArchAttachment(for arch: ArchAttachment) -> Attachment<some View> {
        // Create an attachment with an ID that the `update` closure references.
        Attachment(id: "\(arch.rawValue)ArchAttachmentEntity") {
            switch arch {
            case .blue:
                SwiftUIArcView(color: .blue)
            case .orange:
                UIViewArcViewRep(color: .orange)
            case .pink:
                SwiftUIArcView(color: .pink)
            case .red:
                CALayerArcViewRep(color: .red)
            }
        }
    }
    
    /// Creates an array containing the scale and position for each attachment entity.
    func scaleAndPositionArches(yellowArchSize: BoundingBox) -> [ViewAttachment] {
        var viewAttachmentArray: [ViewAttachment] = []
        
        // MARK: - Scaling properties
        
        // Set the x scale to be the same as the yellow arch.
        // Set the y scale to be double the yellow arch to account for the larger frame due to the SwiftUI view.
        var archScale = SIMD3(x: yellowArchSize.extents.x, y: yellowArchSize.max.y * 2, z: 1)
        
        // MARK: - Positioning properties
        
        // Set the y position to be the same as the yellow arch.
        let yPosition = yellowArchSize.min.y
        
        // Set the z position to be 0.1 meters back.
        var zPosition: Float = -0.1
        var position = SIMD3(x: 0, y: yPosition, z: zPosition)
        
        for entity in rainbowModel.attachments {

            // Push the arch back by 0.1 meters.
            zPosition -= 0.1
            position.z = zPosition
            
            // Add the attachments to the view attachment array.
            viewAttachmentArray.append(ViewAttachment(entity: entity, position: position, scale: archScale))
            
            // Scale the next attachment to be 75% of the size of the previous arch.
            archScale *= 3 / 4
        }
        return viewAttachmentArray
    }
    
    /// Creates an entity from the data model for each Reality Composer Pro asset.
    func createEntity(for item: EntityData) async -> Entity {
        var entity = Entity()
        
        // Load the entity from Reality Composer Pro.
        let realityComposerEntity = try! await Entity(named: item.title, in: realityKitContentBundle)
        
        // Find the model component entity and model component.
        let modelEntity = realityComposerEntity.findEntity(named: item.title)
        guard var modelComponent = modelEntity?.components[ModelComponent.self] else {
            return Entity()
        }
        
        // Set the material if it has a simple material.
        if let material = item.simpleMaterial {
            modelComponent.materials = [material]
        }
        
        // Set the model component.
        modelEntity?.components.set(modelComponent)
        
        entity = modelEntity!
        
        return entity
    }
}
