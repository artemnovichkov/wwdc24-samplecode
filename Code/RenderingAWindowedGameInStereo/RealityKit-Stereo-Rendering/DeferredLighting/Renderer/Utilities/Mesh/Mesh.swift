/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that contains data useful for loading assets.
*/

import Foundation
import MetalKit
import simd

// MARK: - Mesh
// An app-specific mesh structure that contains vertex data used to describe the mesh and submesh object for describing
// how to draw parts of the mesh.
struct Mesh {
    
    // A MetalKit mesh that contains the vertex buffers for describing the shape of the mesh.
    let metalKitMesh: MTKMesh
    
    let submeshes: [SubMesh]
    
    init(metalKitMesh: MTKMesh) {
        self.metalKitMesh = metalKitMesh
        
        var submeshes = [SubMesh]()
        for metalKitSubMesh in metalKitMesh.submeshes {
            submeshes.append(SubMesh(metalKitSubmesh: metalKitSubMesh))
        }
        self.submeshes = submeshes
    }
    
    init(modelIOMesh: MDLMesh,
         vertexDescriptor: MDLVertexDescriptor,
         textureLoader: MTKTextureLoader,
         device: MTLDevice) {
        // Have ModelIO create the tangents from mesh texture coordinates and normals.
        modelIOMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    normalAttributeNamed: MDLVertexAttributeNormal,
                                    tangentAttributeNamed: MDLVertexAttributeTangent)
        
        // Have ModelIO create bitangents from mesh texture coordinates and the newly created tangents.
        modelIOMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    tangentAttributeNamed: MDLVertexAttributeTangent,
                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
        
        // Apply the ModelIO vertex descriptor that the renderer created to match the Metal vertex descriptor.

        // Assigning a new vertex descriptor to a ModelIO mesh performs a re-layout of the
        // vertex data. In this case, the renderer created the ModelIO vertex descriptor so that the
        // layout of the vertices in the ModelIO mesh match the layout of vertices the Metal render
        // pipeline expects as input into its vertex shader.

        // Note: ModelIO must create tangents and bitangents (as done above) before this relayout occurs.
        // This is because the `addTangentBasis` methods in ModelIO only work with 32-bit floating-point vertex data.
        // After applying the vertex descriptor, those floats change into 16-bit
        // floats or other types from which ModelIO cannot produce tangents.
        modelIOMesh.vertexDescriptor = vertexDescriptor
        
        // Create the MetalKit mesh that contains the Metal buffer(s) with the mesh's vertex data,
        // and submeshes with info to draw the mesh.
        do {
            let metalKitMesh = try MTKMesh(mesh: modelIOMesh, device: device)
            // There should always be the same number of MetalKit submeshes in the MetalKit mesh as there
            // are ModelIO submeshes in the ModelIO mesh.
            assert(metalKitMesh.submeshes.count == modelIOMesh.submeshes?.count)
            self.metalKitMesh = metalKitMesh
        } catch {
            fatalError("Failed to create MTKMesh from MDLMesh: \(error.localizedDescription)")
        }
        
        // Create an array to hold this AAPLMesh object's AAPLSubmesh objects.
        
        var submeshes = [SubMesh]()
        
        for index in 0..<metalKitMesh.submeshes.count {
            if let modelIOSubmesh = modelIOMesh.submeshes?.object(at: index) as? MDLSubmesh {
                let subMesh = SubMesh(modelIOSubmesh: modelIOSubmesh,
                                      metalKitSubmesh: metalKitMesh.submeshes[index],
                                      textureLoader: textureLoader)
                submeshes.append(subMesh)
            }
            
        }
        
        self.submeshes = submeshes
    }
    
    // Constructs an array of meshes from the provided file URL, which indicate the location of a model
    // file in a format supported by ModelIO, such as `OBJ`, `ABC`, or `USD`. `mdlVertexDescriptor` defines
    //  the layout ModelIO will use to arrange the vertex data while the `bufferAllocator` supplies
    //  allocations of Metal buffers to store vertex and index data
    static func loadMeshes(url: URL,
                           vertexDescriptor: MDLVertexDescriptor,
                           device: MTLDevice) -> [Mesh] {
        // Create a MetalKit mesh buffer allocator so that ModelIO  will load mesh data directly into
        // Metal buffers accessible by the GPU
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        
        // Use ModelIO  to load the model file at the URL.  This returns a ModelIO  asset object, which
        // contains a hierarchy of ModelIO objects composing a "scene" described by the model file.
        // This hierarchy may include lights, cameras, but, most importantly, mesh and submesh data
        // that we'll render with Metal
        let asset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        
        // Create a MetalKit texture loader to load material textures from files or the asset catalog
        //   into Metal textures
        let textureLoader = MTKTextureLoader(device: device)
        
        var meshes = [Mesh]()
        
        // Traverse the ModelIO asset hierarchy to find ModelIO meshes and create app-specific
        // AAPLMesh objects from those ModelIO meshes
        for child in asset.childObjects(of: MDLObject.self) {
            let assetMeshes = makeMeshes(object: child, vertexDescriptor: vertexDescriptor, textureLoader: textureLoader, device: device)
            meshes.append(contentsOf: assetMeshes)
        }
        
        return meshes
    }
    
    static func makeMeshes(object: MDLObject,
                           vertexDescriptor: MDLVertexDescriptor,
                           textureLoader: MTKTextureLoader,
                           device: MTLDevice) -> [Mesh] {
        
        var meshes = [Mesh]()
        
        // If this ModelIO  object is a mesh object (not a camera, light, or something else)...
        //...create an app-specific Mesh object from it
        if let mesh = object as? MDLMesh {
            let newMesh = Mesh(modelIOMesh: mesh,
                               vertexDescriptor: vertexDescriptor,
                               textureLoader: textureLoader,
                               device: device)
            meshes.append(newMesh)
        }
        
        // Recursively traverse the ModelIO  asset hierarchy to find ModelIO  meshes that are children
        // of this ModelIO  object and create app-specific AAPLMesh objects from those ModelIO meshes
        if object.conforms(to: MDLObjectContainerComponent.self) {
            
            for child in object.children.objects {
                let childMeshes = makeMeshes(object: child, vertexDescriptor: vertexDescriptor, textureLoader: textureLoader, device: device)
                meshes.append(contentsOf: childMeshes)
            }
        }
        
        return meshes
    }
}
