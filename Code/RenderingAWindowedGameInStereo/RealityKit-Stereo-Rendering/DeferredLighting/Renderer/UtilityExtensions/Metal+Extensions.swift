/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App specific extensions of various Metal objects to enhance use of shared indices with Metal shaders.
*/

import MetalKit

// MARK: - MTLRenderPipelineColorAttachmentDescriptorArray
extension MTLRenderPipelineColorAttachmentDescriptorArray {
    subscript(_ index: UInt32) -> MTLRenderPipelineColorAttachmentDescriptor? {
        get { self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
}

// MARK: - MTLVertexAttributeDescriptorArray
extension MTLVertexAttributeDescriptorArray {
    subscript(_ index: UInt32) -> MTLVertexAttributeDescriptor {
        get { self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
}

// MARK: - MTLVertexBufferLayoutDescriptorArray
extension MTLVertexBufferLayoutDescriptorArray {
    subscript(_ index: UInt32) -> MTLVertexBufferLayoutDescriptor {
        get { self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
}

// MARK: - MTLRenderCommandEncoder
extension MTLRenderCommandEncoder {
    
    /// Draws the provided Meshes, if requiresMaterials is true, SubMesh materials will be set.
    func draw(meshes: [Mesh], instanceCount: Int = 1, requiresMaterials: Bool = true) {
        
        for mesh in meshes {
            
            setMesh(mesh)
            
            // Draw each submesh of the mesh
            for submesh in mesh.submeshes {
                // Set any textures read/sampled from the render pipeline
                if requiresMaterials, let material = submesh.material {
                    setMaterial(material)
                }
                                
                drawIndexedPrimitives(type: submesh.metalKitSubmesh.primitiveType,
                                      indexCount: submesh.metalKitSubmesh.indexCount,
                                      indexType: submesh.metalKitSubmesh.indexType,
                                      indexBuffer: submesh.metalKitSubmesh.indexBuffer.buffer,
                                      indexBufferOffset: submesh.metalKitSubmesh.indexBuffer.offset,
                                      instanceCount: instanceCount)
            }
        }
    }
    
    private func setMesh(_ mesh: Mesh) {
        let metalKitMesh = mesh.metalKitMesh
        
        // Set mesh's vertex buffers
        for bufferIndex in 0..<metalKitMesh.vertexBuffers.count {
            let vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex]
            setVertexBuffer(vertexBuffer.buffer,
                            offset: vertexBuffer.offset,
                            index: bufferIndex)
        }
    }
    
    private func setMaterial(_ material: Material) {
        setFragmentTexture(material.baseColor, index: Int(AAPLTextureIndexBaseColor.rawValue))
        setFragmentTexture(material.normal, index: Int(AAPLTextureIndexNormal.rawValue))
        setFragmentTexture(material.specular, index: Int(AAPLTextureIndexSpecular.rawValue))
    }
}
