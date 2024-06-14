/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of paths and their life-cycle state and drawing logic.
*/

import CompositorServices
import Spatial
import SwiftUI
import MetalKit

typealias PathID = UUID

@MainActor
private protocol Path {
    var id: PathID { get }
    var buffer: MTLBuffer { get }
    var vertexCount: Int { get }
    var parameters: PathProperties { get set }
}

extension Path {
    static var verticesPerSegment: Int { 20 }
    static var pointsPerSegment: Int { 4 }
}

private struct CompletePath: Path {
    let id: PathID
    let buffer: MTLBuffer
    let vertexCount: Int
    var parameters: PathProperties
}

private class ActivePath: Path, Hashable, Equatable {
    struct Storage {
        let buffer: MTLBuffer
        
        init(device: MTLDevice) {
            let maxPathPoints = 1_000_000
            buffer = device.makeBuffer(length: MemoryLayout<PathPoint>.stride * maxPathPoints)!
        }
    }

    var buffer: MTLBuffer { storage.buffer }
    let storage: Storage
    var pointCount: Int = 0

    fileprivate var vertexCount: Int {
        guard pointCount >= Self.pointsPerSegment else { return 0 }
        // The last points of the segment aren't drawn.
        return (pointCount - (Self.pointsPerSegment - 1)) * Self.verticesPerSegment
    }
    
    var hasContent: Bool { vertexCount > 0 }
    
    // Tracks frames this path renders to.
    fileprivate var renderingFrames: Set<LayerFrameIndex> = []
    
    fileprivate var didFinishEditing: Bool = false
    
    private var points: UnsafeMutablePointer<PathPoint> {
        storage.buffer.contents().assumingMemoryBound(to: PathPoint.self)
    }
    
    var parameters = PathProperties(color: .one,
                                    opacity: 0.0,
                                    radius: 0.01,
                                    verticesPerSegment: Int32(ActivePath.verticesPerSegment))
    let id: PathID
    let eventID: SpatialEventCollection.Event.ID
    
    init(storage: Storage, eventID: SpatialEventCollection.Event.ID) {
        self.storage = storage
        self.id = PathID()
        self.eventID = eventID
    }
    
    fileprivate func addPoint(_ point: SIMD3<Float>, _ cameraPosition: SIMD3<Float>) {
        points[pointCount] = .init(position: point, cameraPosition: cameraPosition)
        pointCount += 1
    }
    
    func createCompletedPath() -> CompletePath {
        let bufferCopy = buffer.device.makeBuffer(bytes: buffer.contents(),
                                                  length: MemoryLayout<PathPoint>.stride * self.pointCount)!
        return CompletePath(id: id,
                            buffer: bufferCopy,
                            vertexCount: vertexCount,
                            parameters: parameters)
    }
    
    static func == (lhs: ActivePath, rhs: ActivePath) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}

@MainActor
class PathCollection {
    enum Error: Swift.Error {
        case tooManyActivePaths
    }
    
    // Complete rendered paths.
    private var completedPaths: [CompletePath] = []
        
    // Paths actively updating with spatial events, or those part of a frame.
    private var activePaths: [SpatialEventCollection.Event.ID: ActivePath] = [:]
    
    private static let maxActivePaths = 2 * Renderer.maxFramesInFlight
    private var pathStoragePool: [ActivePath.Storage] = []
    
    // Don't add the points directly; wait to add them after you have the
    // camera pose to compute the normal, tangents, and bitangent of the point.
    private var pendingNewPoints: [(SpatialEventCollection.Event.ID, Point3D)] = []
    
    private let uniformsBuffer: [MTLBuffer]
    
    var pathColor: Color.Resolved?
    var pathOpacity: Double? = 1.0
    var pathRadius: Double?

    private let pathColorTexture: MTLTexture & Sendable

    private let renderPipelineState: MTLRenderPipelineState & Sendable
    
    init(layerRenderer: LayerRenderer) throws {
        pathStoragePool = (0..<Self.maxActivePaths).map { _ in
                .init(device: layerRenderer.device)
        }
        
        uniformsBuffer = (0..<Renderer.maxFramesInFlight).map { _ in
            layerRenderer.device.makeBuffer(length: MemoryLayout<PathProperties>.uniformStride)!
        }

        pathColorTexture = try Self.loadTexture(device: layerRenderer.device, textureName: "PathColor")
        renderPipelineState = try Self.makePipelineDescriptor(layerRenderer: layerRenderer)
    }
    
    private class func loadTexture(device: MTLDevice,
                                   textureName: String) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: device)

        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]

        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)

    }

    private static func makePipelineDescriptor(layerRenderer: LayerRenderer) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = Renderer.defaultRenderPipelineDescriptor(layerRenderer: layerRenderer)
        
        let library = layerRenderer.device.makeDefaultLibrary()!
        
        let vertexFunction = library.makeFunction(name: "pathVertexFunction")
        let fragmentFunction = library.makeFunction(name: "pathFragmentFunction")
        
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexFunction = vertexFunction
        
        return try layerRenderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

/// Path updates.
extension PathCollection {
    private func startNewPath(id: SpatialEventCollection.Event.ID) throws -> ActivePath {

        guard let pathStorage = pathStoragePool.popLast() else {
            throw Error.tooManyActivePaths
        }
        
        let path = ActivePath(storage: pathStorage, eventID: id)
        
        if let pathColor {
            path.parameters.color.x = pathColor.linearRed
            path.parameters.color.y = pathColor.linearGreen
            path.parameters.color.z = pathColor.linearBlue
        }
        if let pathOpacity {
            path.parameters.opacity = Float(pathOpacity)
        }
        if let pathRadius {
            path.parameters.radius = Float(pathRadius)
        }

        activePaths[id] = path
        
        return path
    }
    
    private func endPath(id: SpatialEventCollection.Event.ID, keep: Bool) {
        guard let path = activePaths[id] else {
            fatalError("Invalid path ID")
        }
        
        if keep, path.hasContent {
            completedPaths.append(path.createCompletedPath())
        }
        
        path.didFinishEditing = true

        self.returnPathStorageIfPossible(path: path)
    }
    
    func addEvents(eventCollection: SpatialEventCollection) {
        for event in eventCollection {
            switch event.phase {
            case .active:
                pendingNewPoints.append((event.id, event.inputDevicePose!.pose3D.position))
            case .ended:
                endPath(id: event.id, keep: true)
            case .cancelled:
                endPath(id: event.id, keep: false)
            @unknown default:
                fatalError("Invalid event phase")
            }
        }
    }
        
    private func returnPathStorageIfPossible(path: ActivePath) {
        // Reclaim path storage when the path is both complete and no longer rendering frames
        // in any one of the three frames in flight of the triple-buffered renderer.
        // Otherwise reclaim storage if the path is not visible.
        if (path.didFinishEditing &&
            path.renderingFrames.isEmpty) ||
            path.parameters.opacity <= 0.0 {
            activePaths[path.eventID] = nil
            pathStoragePool.append(path.storage)
        }
    }
}

/// Path rendering.
extension PathCollection {
    func update(withTiming timing: LayerRenderer.Frame.Timing, worldTracking: WorldTrackingProvider) throws {
        let time = LayerRenderer.Clock.Instant.epoch.duration(to: timing.presentationTime).timeInterval
        let cameraPosition = worldTracking.queryDeviceAnchor(atTimestamp: time)?.originFromAnchorTransform.columns.3.xyz ?? .zero

        for (pathID, point) in pendingNewPoints {
            let path = try activePaths[pathID] ?? (try startNewPath(id: pathID))
            path.addPoint(.init(point.vector), cameraPosition)
        }
        
        pendingNewPoints.removeAll()
    }
    
    func drawCommand(frame: LayerRenderer.Frame) throws -> PathCollectionDrawCommand {
                        
        for index in 0..<completedPaths.count {
            if completedPaths[index].parameters.opacity > 0 {
                completedPaths[index].parameters.opacity -= 0.01
            } else {
                completedPaths[index].parameters.opacity = 0
            }
        }

        var renderedPaths: [Path] = completedPaths
        
        // Render active paths under construction.
        for path in activePaths.values where !path.didFinishEditing {
            path.renderingFrames.insert(frame.frameIndex)
            renderedPaths.append(path)
        }
        
        return PathCollectionDrawCommand(paths: renderedPaths,
                                         frameIndex: frame.frameIndex,
                                         uniforms: self.uniformsBuffer[Int(frame.frameIndex % Renderer.maxFramesInFlight)])
    }
    
    @RendererActor
    func encodeDraw(_ drawCommand: PathCollectionDrawCommand, encoder: MTLRenderCommandEncoder, commandBuffer: MTLCommandBuffer) {
        
        encoder.setCullMode(.none)
        
        for pathCommand in drawCommand.pathCommands {
            encoder.setRenderPipelineState(renderPipelineState)
            
            encoder.setVertexBuffer(pathCommand.buffer, offset: 0,
                                    index: PathPropertiesBufferIndex.positions.rawValue)
            
            var parameters = pathCommand.parameters
            
            encoder.setFragmentBuffer(drawCommand.uniforms, offset: 0,
                                      index: BufferIndex.uniforms.rawValue)
            encoder.setVertexBuffer(drawCommand.uniforms, offset: 0,
                                    index: BufferIndex.uniforms.rawValue)
            encoder.setVertexBytes(&parameters, length: MemoryLayout<PathProperties>.uniformStride,
                                   index: PathPropertiesBufferIndex.parameters.rawValue)
            encoder.setFragmentBytes(&parameters, length: MemoryLayout<PathProperties>.uniformStride,
                                     index: PathPropertiesBufferIndex.parameters.rawValue)
            
            encoder.setFragmentTexture(pathColorTexture,
                                       index: PathPropertiesTextureIndex.color.rawValue)
            
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: pathCommand.vertexCount)
        }
        
        commandBuffer.addCompletedHandler { _ in Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                for (_, path) in self.activePaths where path.renderingFrames.contains(drawCommand.frameIndex) {
                    path.renderingFrames.remove(drawCommand.frameIndex)
                    self.returnPathStorageIfPossible(path: path)
                }
        }
        }
    }
    
    @RendererActor
    func updateUniformBuffers(_ drawCommand: PathCollectionDrawCommand,
                              drawable: LayerRenderer.Drawable) {
        drawCommand.uniforms.contents().assumingMemoryBound(to: Uniforms.self).pointee = Uniforms(drawable: drawable)
    }
}

@RendererActor
struct PathCollectionDrawCommand {
    @RendererActor
    fileprivate struct PathDrawCommand {
        let activePath: ActivePath?
        let buffer: MTLBuffer
        let vertexCount: Int
        let parameters: PathProperties
    }
    
    fileprivate let pathCommands: [PathDrawCommand]
    fileprivate let frameIndex: LayerFrameIndex
    fileprivate let uniforms: MTLBuffer & Sendable
    
    @MainActor
    fileprivate init(paths: [Path], frameIndex: LayerFrameIndex, uniforms: MTLBuffer) {
        self.pathCommands = paths.map { .init(activePath: $0 as? ActivePath,
                                              buffer: $0.buffer,
                                              vertexCount: $0.vertexCount,
                                              parameters: $0.parameters)
        }
        self.frameIndex = frameIndex
        self.uniforms = uniforms
    }
}
