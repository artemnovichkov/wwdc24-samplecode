/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A renderer that displays a set of color swatches.
*/

import CompositorServices
import Metal
import MetalKit
import simd
import Spatial

let maxFramesInFlight = 3
let numVertices = 6

@MainActor
class TintRenderer {
    private let renderPipelineState: MTLRenderPipelineState & Sendable

    private let uniformsBuffer: [MTLBuffer]
    
    init(layerRenderer: LayerRenderer) throws {
        uniformsBuffer = (0..<Renderer.maxFramesInFlight).map { _ in
            layerRenderer.device.makeBuffer(length: MemoryLayout<PathProperties>.uniformStride)!
        }
        
        renderPipelineState = try Self.makePipelineDescriptor(layerRenderer: layerRenderer)
    }
    
    class func buildMetalVertexDescriptor() -> MTLVertexDescriptor {
        // Create a vertex descriptor specifying how Metal lays out vertices for input into the render pipeline.

        let mtlVertexDescriptor = MTLVertexDescriptor()

        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        let offset = MemoryLayout<SIMD3<Float>>.stride
        mtlVertexDescriptor.attributes[VertexAttribute.color.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.color.rawValue].offset = offset
        mtlVertexDescriptor.attributes[VertexAttribute.color.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue

        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stride = MemoryLayout<Vertex>.stride
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex

        return mtlVertexDescriptor
    }

    private static func makePipelineDescriptor(layerRenderer: LayerRenderer) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = Renderer.defaultRenderPipelineDescriptor(layerRenderer: layerRenderer)

        let library = layerRenderer.device.makeDefaultLibrary()!
        
        let vertexFunction = library.makeFunction(name: "tintVertexShader")
        let fragmentFunction = library.makeFunction(name: "tintFragmentShader")

        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexFunction = vertexFunction

        pipelineDescriptor.label = "TriangleRenderPipeline"
        pipelineDescriptor.vertexDescriptor = TintRenderer.buildMetalVertexDescriptor()

        return try layerRenderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
        
    func drawCommand(frame: LayerRenderer.Frame) throws -> TintDrawCommand {
        return TintDrawCommand(frameIndex: frame.frameIndex,
                               uniforms: self.uniformsBuffer[Int(frame.frameIndex % Renderer.maxFramesInFlight)])
    }
    
    @RendererActor
    func encodeDraw(_ drawCommand: TintDrawCommand,
                    encoder: MTLRenderCommandEncoder,
                    drawable: LayerRenderer.Drawable,
                    device: MTLDevice, tintValue: Float) {
        encoder.setCullMode(.none)

        encoder.setRenderPipelineState(renderPipelineState)
        
        var tintUniform: TintUniforms = TintUniforms(tintOpacity: tintValue)
        encoder.setVertexBytes(&tintUniform,
                               length: MemoryLayout<TintUniforms>.size,
                               index: BufferIndex.tintUniforms.rawValue)

        encoder.setVertexBuffer(drawCommand.uniforms,
                                offset: 0,
                                index: BufferIndex.uniforms.rawValue)
        
        let bufferLength = MemoryLayout<Vertex>.stride * numVertices

        let quadVertexBuffer: MTLBuffer = device.makeBuffer(length: bufferLength)!
        quadVertexBuffer.label = "Quad vertex buffer"
        var quadVertices: UnsafeMutablePointer<Vertex> {
            quadVertexBuffer.contents().assumingMemoryBound(to: Vertex.self)
        }
        
        let roseColor = SIMD3<Float>(1, 0.1, 0.25)
        let horizontalScale: Float = 10.0
        let verticalScale: Float = 10.0
        let depth: Float = -2.0
        
        // Lower triangle
        quadVertices[0] = Vertex(position: SIMD3<Float>(-1 * horizontalScale, (-1 * verticalScale), depth),
                                     color: roseColor)
        quadVertices[1] = Vertex(position: SIMD3<Float>(1 * horizontalScale, (-1 * verticalScale), depth),
                                     color: roseColor)
        quadVertices[2] = Vertex(position: SIMD3<Float>(-1 * horizontalScale, (1 * verticalScale), depth),
                                     color: roseColor)
        // Upper triangle
        quadVertices[3] = Vertex(position: SIMD3<Float>(-1 * horizontalScale, (1 * verticalScale), depth),
                                     color: roseColor)
        quadVertices[4] = Vertex(position: SIMD3<Float>(1 * horizontalScale, (-1 * verticalScale), depth),
                                     color: roseColor)
        quadVertices[5] = Vertex(position: SIMD3<Float>(1 * horizontalScale, (1 * verticalScale), depth),
                                     color: roseColor)
        encoder.setVertexBuffer(quadVertexBuffer,
                                offset: 0,
                                index: BufferIndex.meshPositions.rawValue)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)
    }

    @RendererActor
    func updateUniformBuffers(_ drawCommand: TintDrawCommand,
                              drawable: LayerRenderer.Drawable) {
        drawCommand.uniforms.contents().assumingMemoryBound(to: Uniforms.self).pointee = Uniforms(drawable: drawable)
    }
}

@RendererActor
struct TintDrawCommand {
    @RendererActor
    fileprivate struct DrawCommand {
        let buffer: MTLBuffer
        let vertexCount: Int
    }
    
    fileprivate let drawCommand: DrawCommand
    fileprivate let frameIndex: LayerFrameIndex
    fileprivate let uniforms: MTLBuffer & Sendable
    
    @MainActor
    fileprivate init(frameIndex: LayerFrameIndex, uniforms: MTLBuffer) {
        self.drawCommand = DrawCommand(buffer: uniforms, vertexCount: numVertices)
        self.frameIndex = frameIndex
        self.uniforms = uniforms
    }
}
