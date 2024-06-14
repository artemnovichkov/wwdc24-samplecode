/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension of MDLVertexDescriptor to enhance use of shared indices with Metal shaders.
*/

import ModelIO

// MARK: - MDLVertexDescriptor
extension MDLVertexDescriptor {
    
    /// Returns the vertex buffer attribute descriptor at the specified index.
    func attribute(_ index: UInt32) -> MDLVertexAttribute {
        guard let attributes = attributes as? [MDLVertexAttribute] else { fatalError() }
        return attributes[Int(index)]
    }
    
    /// Returns the vertex buffer layout descriptor at the specified index.
    func layout(_ index: UInt32) -> MDLVertexBufferLayout {
        guard let layouts = layouts as? [MDLVertexBufferLayout] else { fatalError() }
        return layouts[Int(index)]
    }
    
}
