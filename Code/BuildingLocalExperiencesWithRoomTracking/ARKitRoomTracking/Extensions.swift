/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Helper functions for converting types.
*/
import ARKit
import RealityKit

extension SIMD4 {
    /// Retrieves first 3 elements
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension ModelEntity {
    /// The geometry center of this model's faces.
    var centroid: SIMD3<Float>? {
        guard let vertices = self.model?.mesh.contents.models[0].parts[0].positions.elements else {
            return nil
        }
        guard let faces = self.model?.mesh.contents.models[0].parts[0].triangleIndices?.elements else {
            return nil
        }
        
        // Create a set of all vertices of the entity's faces.
        let uniqueFaces = Set(faces)
        
        var centroid = SIMD3<Float>()
        for vertexInFace in uniqueFaces {
            centroid += vertices[Int(vertexInFace)]
        }
        centroid /= Float(uniqueFaces.count)
        return centroid
    }
}

extension GeometrySource {
    /// converts between ARKit and RealityKit types.
    func asArray<T>(ofType: T.Type) -> [T] {
        let bContents = self.buffer.contents()
        let offset = self.offset
        let stride = self.stride
        let count = self.count
        
        var result: [T] = Array()
        result.reserveCapacity(count)
        
        for index in 0..<count {
            result.append(bContents.advanced(by: offset + stride * index).assumingMemoryBound(to: T.self).pointee)
        }
        return result
    }
    
    func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
        return asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
    }
}

extension GeometryElement {
    func asIndexArray() -> [UInt32] {
        return (0..<self.count * self.primitive.indexCount).map {
            self.buffer.contents()
                .advanced(by: $0 * self.bytesPerIndex)
                .assumingMemoryBound(to: UInt32.self).pointee
        }
    }
}

extension MeshAnchor.Geometry {
    /// Creates MeshResource from geometry.
    @MainActor func asMeshResource() -> MeshResource? {
        let vertices = self.vertices.asSIMD3(ofType: Float.self)
        guard !vertices.isEmpty else {
            return nil
        }
        let faceIndexArray = self.faces.asIndexArray()
        
        var descriptor = MeshDescriptor()
        
        descriptor.positions = .init(vertices)
        descriptor.materials = .allFaces(0)
        descriptor.primitives = MeshDescriptor.Primitives.triangles(faceIndexArray)
        
        do {
            let mesh = try MeshResource.generate(from: [descriptor])
            return mesh
        } catch {
            logger.error("Error creating MeshResource with error:\(error)")
        }
        
        return nil
    }
}
