/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
MTLVertexDescriptors used by the Renderer.
*/

import Metal

// MARK: - VertexDescriptors
struct VertexDescriptors {
    
    let basic: MTLVertexDescriptor = {
        let descriptor = MTLVertexDescriptor()
        // Positions.
        let position = descriptor.attributes[AAPLVertexAttributePosition.rawValue]
        position.format = .float3
        position.bufferIndex = Int(AAPLBufferIndexMeshPositions.rawValue)
        
        // Texture coordinates.
        let texcoord = descriptor.attributes[AAPLVertexAttributeTexcoord.rawValue]
        texcoord.format = .float2
        texcoord.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        // Normals.
        let normals = descriptor.attributes[AAPLVertexAttributeNormal.rawValue]
        normals.format = .half4
        normals.offset = 8
        normals.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        // Tangents.
        let tangents = descriptor.attributes[AAPLVertexAttributeTangent.rawValue]
        tangents.format = .half4
        tangents.offset = 16
        tangents.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        // Bitangents.
        let bitangents = descriptor.attributes[AAPLVertexAttributeBitangent.rawValue]
        bitangents.format = .half4
        bitangents.offset = 24
        bitangents.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        // Position Buffer Layout.
        descriptor.layouts[AAPLBufferIndexMeshPositions.rawValue].stride = 12
        
        // Generic Attribute Buffer Layout.
        descriptor.layouts[AAPLBufferIndexMeshGenerics.rawValue].stride = 32
        
        return descriptor
    }()
    
    let skybox: MTLVertexDescriptor = {
        let descriptor = MTLVertexDescriptor()
        
        let position = descriptor.attributes[AAPLVertexAttributePosition.rawValue]
        position.format = .float3
        position.offset = 0
        position.bufferIndex = Int(AAPLBufferIndexMeshPositions.rawValue)
        
        descriptor.layouts[AAPLBufferIndexMeshPositions.rawValue].stride = 12
        
        let normals = descriptor.attributes[AAPLVertexAttributeNormal.rawValue]
        normals.format = .float3
        normals.offset = 0
        normals.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        descriptor.layouts[AAPLBufferIndexMeshGenerics.rawValue].stride = 12
        return descriptor
    }()
    
}
