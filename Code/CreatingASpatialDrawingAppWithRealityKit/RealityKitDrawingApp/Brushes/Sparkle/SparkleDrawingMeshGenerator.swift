/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that manages the generation of meshes for the sparkle brush, using `LowLevelMesh` and a GPU particle simulation.
*/

import Foundation
import Collections
import RealityKit
import Metal

final class SparkleDrawingMeshGenerator {
    private static let commandQueue: MTLCommandQueue? = {
        if let metalDevice, let queue = metalDevice.makeCommandQueue() {
            queue.label = "Sparkle Brush Command Queue"
            return queue
        } else {
            return nil
        }
    }()
    
    /// The `LowLevelMesh` currently being written to.  Contains capacity for `particleCapacity` particles.
    private var lowLevelMesh: LowLevelMesh?
    
    /// The particle simulation buffer.  Contains capacity for `particleCapacity` articles.
    private var simulationBuffer: MTLBuffer?
    
    /// The number of particles supported by `lowLevelMesh` and `simulationBuffer` without reallocation.
    private var particleCapacity: Int = 0
    
    /// The number of initialized particles in `lowLevelMesh` and `simulationBuffer`.
    /// Must be less than or equal to `particleCapacity`.
    private var particleCount: Int = 0

    /// The entity which is populated by this mesh generator.
    private var rootEntity: Entity
    
    /// Particles are spawned along the path that a person draws, and there is a random interval in the distance
    /// between particle spawn points. This variable defines the range of that random interval.
    private var distanceBetweenParticles: ClosedRange<Float> = 0.0001...0.0005
    
    /// Keeps track of the distance that a person must draw before spawning another particle.
    private var distanceToNextSample: Float = 0
    
    /// When the next particle is spawned, this value is its `curveDistance`.
    private var curveDistanceForNextSample: Float = 0
    
    /// List of particles that must spawn into the scene when calling `populate`.
    private var particlesToSpawn: ContiguousArray<SparkleBrushParticle> = []
    
    /// If there is an active stroke, contains the most recently-traced point.  Else, contains `nil`.
    private var lastTracedPoint: SparkleBrushCurvePoint?
    
    /// True if a command buffer is currently in flight.  Concurrent updates aren't permitted due to contention
    /// over `lowLevelMesh` and `simulationBuffer`.
    private var isMeshUpdateInFlight: Bool = false
    
    /// True if there is an active stroke.
    var isDrawing: Bool { lastTracedPoint != nil }
    
    /// Errors that could occur during mesh generation.
    enum SparkleBrushGenerationError: Error {
        /// Unable to create the metal compute pipeline.
        case unableToCreateComputePipeline
        
        /// Unable to create the metal compute command encoder.
        case unableToCreateComputeEncoder
        
        /// Unable to create the simulation buffer.
        case unableToCreateBuffer
    }
    
    init(rootEntity: Entity, material: Material) {
        self.rootEntity = rootEntity
        
        rootEntity.position = .zero
        let sparkleBrushComponent = SparkleBrushComponent(generator: self, material: material)
        rootEntity.components.set(sparkleBrushComponent)
    }
    
    /// Call this function to trace the current brush stroke to `nextTracedPoint`.
    ///
    /// Begins a new stroke if there was no currently-active stroke.
    func trace(point nextTracedPoint: SparkleBrushCurvePoint) {
        // This routine marches a point along the line segment `lastTracedPoint` -> `nextTracedPoint`.
        // Particles always spawn at a point on this line segment, and given a random velocity.
        //
        // Particles spawn at a rate relative to the length of the curve (for example every millimeter traced).
        // This rate is slightly randomized --- each time a particle spawns, `distanceToNextSample` is randomized to a
        // number in the range `distanceBetweenParticles`.
        if let lastTracedPoint {
            // Length of the line segment connecting `lastTracedPoint` and `nextTracedPoint`.
            let segmentLength = distance(lastTracedPoint.position, nextTracedPoint.position)
            // Distance along the line segment of the most recent sample.
            var segmentDistance: Float = 0
            
            while segmentDistance < segmentLength {
                // Move along the line segment by `distanceToNextSample` meters.
                segmentDistance += distanceToNextSample
                
                // The distance between samples along the curve is randomized.
                distanceToNextSample = Float.random(in: distanceBetweenParticles)
                
                // Spawn the next particle if there is enough room in the segment.
                if segmentDistance < segmentLength {
                    // Normalized distance of this sample along the line segment.
                    let normalizedSegmentDistance = segmentDistance / segmentLength
                    
                    // Spawn the particle.
                    spawnParticle(at: mix(lastTracedPoint, nextTracedPoint, t: normalizedSegmentDistance))
                        
                    // Account for the distance traced.
                    curveDistanceForNextSample += distanceToNextSample
                }
            }
            
            // Account for the remaining distance to trace before spawning the next particle.
            distanceToNextSample = segmentDistance - segmentLength
        }
        
        lastTracedPoint = nextTracedPoint
    }
    
    /// Ends the currently-active stroke, if any.
    func endStroke() {
        distanceToNextSample = 0
        lastTracedPoint = nil
    }
    
    private func spawnParticle(at point: SparkleBrushCurvePoint) {
        // Place a hard limit of 2048 particles per frame, to mitigate frame hitches.
        guard particlesToSpawn.count < 2048 else { return }
        
        let attributes = SparkleBrushAttributes(position: point.position.packed3,
                                                color: SIMD3<Float16>(point.color).packed3,
                                                curveDistance: curveDistanceForNextSample,
                                                size: point.size)
        particlesToSpawn.append(SparkleBrushParticle(attributes: attributes,
                                                     velocity: (randomDirection() * point.initialSpeed).packed3))
    }
    
    /// Reallocates `lowLevelMesh` and `simulationBuffer` to a capacity of at least `newParticleCount`.
    private func reallocateBuffers(newParticleCount: Int) throws {
        guard newParticleCount > particleCapacity else {
            // This particle count is already supported by the current `LowLevelMesh`.
            return
        }
        
        // Double the particle capacity until it exceeds `newParticleCount`, or set to a minimum capacity of 1024.
        var newParticleCapacity = max(1024, particleCapacity)
        while newParticleCapacity < newParticleCount {
            newParticleCapacity *= 2
        }
        
        // Allocate a new simulation buffer with room for `newParticleCapacity` particles.
        let simBufferLength = newParticleCapacity * MemoryLayout<SparkleBrushParticle>.stride
        guard let metalDevice = metalDevice,
              let newBuffer = metalDevice.makeBuffer(length: simBufferLength, options: .storageModePrivate) else {
            throw SparkleBrushGenerationError.unableToCreateBuffer
        }
        
        // Allocate a new `LowLevelMesh` with room for `newParticleCapacity` particles.
        lowLevelMesh = try Self.makeLowLevelMesh(particleCapacity: newParticleCapacity,
                                                      particleCount: particleCount)
        simulationBuffer = newBuffer
        particleCapacity = newParticleCapacity
    }
    
    @MainActor
    func update(deltaTime: Float, _ onCreatedNewMesh: @escaping @MainActor (LowLevelMesh) async -> Void) throws {
        let oldBuffer = simulationBuffer
        
        // Halt if a mesh update is already in flight. Need to wait for a command buffer from a previous frame.
        guard !isMeshUpdateInFlight else { return }
        
        // If there are no particles, and none have been queued for spawning, there is nothing to do.
        guard particleCount > 0 || !particlesToSpawn.isEmpty else { return }
        
        // Buffers need to be reallocated when the number of particles exceeds the current `particleCapacity`.
        let didReallocate: Bool = particleCount + particlesToSpawn.count > particleCapacity
        if didReallocate {
            let newParticleCount = particleCount + particlesToSpawn.count
            try reallocateBuffers(newParticleCount: newParticleCount)
        }
        
        // Create a Metal command buffer and compute command encoder to execute GPU work.
        guard let commandBuffer = Self.commandQueue?.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw SparkleBrushGenerationError.unableToCreateComputeEncoder
        }
        
        // When the Metal command buffer completes, mark the update as no-longer in flight.
        // If a new `LowLevelMesh` was created, notify the caller.
        commandBuffer.addCompletedHandler { [self] commandBuffer in
            Task(priority: .high) { @MainActor in
                if didReallocate {
                    await onCreatedNewMesh(lowLevelMesh!)
                }
                
                precondition(isMeshUpdateInFlight)
                isMeshUpdateInFlight = false
            }
        }
        
        isMeshUpdateInFlight = true
        commandBuffer.enqueue()
        
        defer {
            computeEncoder.endEncoding()
            commandBuffer.commit()
        }
        
        // Simulate the particles that already exist in the simulation buffer.
        if particleCount > 0, let oldBuffer {
            let parameters = SparkleBrushSimulationParams(particleCount: UInt32(particleCount),
                                                          deltaTime: deltaTime, dragCoefficient: 500)
            try Self.simulate(input: oldBuffer, output: simulationBuffer!,
                              particleCount: particleCount, parameters: parameters, encoder: computeEncoder)
        }
        
        // Add any new particles to the simulation.
        if !particlesToSpawn.isEmpty {
            try particlesToSpawn.withUnsafeBufferPointer { bufferPointer in
                try Self.addParticlesToSimulation(input: bufferPointer, output: simulationBuffer!,
                                                  particleOffsetInOutput: particleCount, encoder: computeEncoder)
            }
            particleCount += particlesToSpawn.count
            particlesToSpawn.removeAll()
        }
        
        // Populate the `LowLevelMesh` with the result of the particle simulation.
        try Self.populate(input: simulationBuffer!, output: lowLevelMesh!,
                          particleCount: particleCount, commandBuffer: commandBuffer, encoder: computeEncoder)
    }
}
