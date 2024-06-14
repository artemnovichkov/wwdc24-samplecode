/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A refinement on top of `CurveExtruder` which facilitates the generation of spherical endcaps for each extruded shape.
*/

import Foundation
import Collections
import RealityKit

struct CurveExtruderWithEndcaps {
    private struct BrushStroke {
        var headEndcapSamples: [CurveSample]
        
        var strokeSamples: [CurveSample]
        
        var tailEndcapSamples: [CurveSample]
    }
    
    var samples: [CurveSample] { strokes.last?.strokeSamples ?? [] }
    
    /// The number of segments to use when generating endcap positions.
    ///
    /// Specifically, this is the number of segments parallel to the sweep curve (see `userCurve` in `pushStroke`).
    /// This isn't the number of radial segments, that is equal to `unitCircle.count`.
    private let endcapSegmentCount: UInt32
    
    /// Points on a circle with radius 1 organized counter-clockwise.
    ///
    /// The size of this array is equal to the `radialSegmentCount` passed in `init()`.
    private let unitCircle: [SIMD2<Float>]
    
    /// The `CurveExtruder` used to generate the mesh geometry.
    private var extruder: CurveExtruder
    
    /// Lookup table used to accelerate generation of endcap positions.
    ///
    /// Defined as `endcapLUT[i] = (cos(theta*i), sin(theta*i))` for `theta = (pi/2)/endcapSegmentCount`.
    /// Above `i` ranges from `1...endcapSegmentCount` inclusive.
    /// So this array has length `endcapSegmentCount`.
    private let endcapLUT: [(Float, Float)]
    
    private var strokes: [BrushStroke] = []
        
    /// Generates the `CurveSample` of the endcap given the first or last sample in a curve.
    ///
    /// - Parameters:
    ///   - sample: Either the first (if `isHeadEndcap` is true) or last (if `isHeadEndcap` is false)
    ///     sample on the curve.
    ///   - isHeadEndcap: Specifies if a head or tail endcap should be generated.
    private func generateEndcap(for sample: CurveSample, isHeadEndcap: Bool) -> [CurveSample] {
        precondition((length_squared(sample.tangent) - 1) <= 1.0e-6)
        
        if isHeadEndcap {
            let startPos = sample.position - sample.tangent * sample.radius
            return endcapLUT.reversed().map { (radius, oneMinusDistance) in
                let distance = 1 - oneMinusDistance
                var endcapSample = sample
                endcapSample.position = startPos + sample.tangent * sample.radius * distance
                endcapSample.radius *= radius
                return endcapSample
            }
        } else {
            return endcapLUT.map { (radius, distance) in
                var endcapSample = sample
                endcapSample.position = sample.position + sample.tangent * sample.radius * distance
                endcapSample.radius *= radius
                return endcapSample
            }
        }
    }
    
    /// Initializes the `CurveExtruderWithEndcaps` with the resolution of the generated geometry.
    ///
    /// - Parameters:
    ///   - radialSegmentCount: The segment count to use radially along the extruded tube.
    ///   - endcapSegmentCount: The segment count to use for endcaps.
    init(radialSegmentCount: UInt32 = 32, endcapSegmentCount: UInt32 = 16) {
        self.endcapSegmentCount = endcapSegmentCount
        
        // Generate a lookup table of the unit circle shape, which is swept along the curve.
        unitCircle = makeCircle(radius: 1, segmentCount: Int(radialSegmentCount))
        
        // Initialize the `CurveExtruder` to extrude the unit circle shape.
        extruder = CurveExtruder(shape: unitCircle)
        
        // Generate a lookup table `endcapLUT[i] = (cos(theta*i), sin(theta*i))`
        // for `theta = (pi/2)/endcapSegmentCount`.
        // This accelerates the generation of endcap positions (see `generateEndcap`).
        let theta = Float.pi / Float(2 * endcapSegmentCount)
        endcapLUT = (1...endcapSegmentCount).map { (cos(theta * Float($0)), sin(theta * Float($0))) }
    }
    
    /// Finalizes the brush stroke that is currently at the end of the list of strokes.
    ///
    /// This is necessary before rendering, and also before adding new brush strokes.
    /// Concretely, this adds a tail endcap if one does not yet exist on the last stroke.
    private mutating func finalizeLastStroke() {
        guard var last = strokes.last, !last.strokeSamples.isEmpty, last.tailEndcapSamples.isEmpty else {
            return
        }
        precondition(!last.headEndcapSamples.isEmpty,
                     "expected head endcap to exist because strokeSamples is nonempty.")
        last.tailEndcapSamples = generateEndcap(for: last.strokeSamples.last!, isHeadEndcap: false)
        extruder.append(samples: last.tailEndcapSamples)
        strokes[strokes.count - 1] = last
    }
    
    /// Updates the low level mesh that this curve extruder maintains.
    ///
    /// This applies pending calls to `append` or `removeLast` to the `LowLevelMesh`.
    ///
    /// - Returns: A `LowLevelMesh` if a new mesh had to be allocated (that is, the number of samples exceeded the capacity
    ///     of the previous mesh).  Returns `nil` if no new `LowLevelMesh` was allocated.
    @MainActor
    mutating func update() throws -> LowLevelMesh? {
        // Finalize the stroke which is currently at the tail of the curve.
        // This generates the tail endcap of this last stroke if it hasn't yet been generated.
        finalizeLastStroke()
        
        // Update the underlying `CurveExtruder` and return a `LowLevelMesh` if a new one was allocated.
        return try extruder.update()
    }
    
    /// Removes a number of samples from the end of the curve.
    mutating func removeLast(sampleCount strokeSamplesToRemove: Int) {
        var strokeSamplesToRemove = strokeSamplesToRemove
        while strokeSamplesToRemove > 0 {
            guard var stroke = strokes.popLast() else {
                preconditionFailure("attempted to remove more samples from the curve were added")
            }
            
            if !stroke.tailEndcapSamples.isEmpty {
                // Remove the tail endcap.
                extruder.removeLast(sampleCount: stroke.tailEndcapSamples.count)
                stroke.tailEndcapSamples.removeAll()
            }
            
            let strokeSamplesToRemoveNow = min(strokeSamplesToRemove, stroke.strokeSamples.count)
            stroke.strokeSamples.removeLast(strokeSamplesToRemoveNow)
            extruder.removeLast(sampleCount: strokeSamplesToRemoveNow)
            
            if stroke.strokeSamples.isEmpty && !stroke.headEndcapSamples.isEmpty {
                // Remove the head endcap.
                extruder.removeLast(sampleCount: stroke.headEndcapSamples.count)
                stroke.headEndcapSamples.removeAll()
            }
            
            strokeSamplesToRemove -= strokeSamplesToRemoveNow
            
            if strokeSamplesToRemove == 0 {
                // If there are no more samples to remove,
                // re-append `stroke` to the list of strokes.
                strokes.append(stroke)
            }
        }
    }
    
    /// Appends the provided curve samples to the extrusion.
    mutating func append(samples: [CurveSample]) {
        guard !samples.isEmpty else { return }
        if strokes.isEmpty { beginNewStroke() }
        
        var stroke = strokes.popLast()!
        precondition(stroke.headEndcapSamples.isEmpty == stroke.strokeSamples.isEmpty,
                     "expected to have generated head endcap samples if and only if there are already stroke samples")
        
        if !stroke.tailEndcapSamples.isEmpty {
            // Remove the tail endcap.
            extruder.removeLast(sampleCount: stroke.tailEndcapSamples.count)
            stroke.tailEndcapSamples.removeAll()
        }
        
        // Generate the head endcap if these are the first samples in the curve.
        if stroke.headEndcapSamples.isEmpty {
            stroke.headEndcapSamples = generateEndcap(for: samples.first!, isHeadEndcap: true)
            extruder.append(samples: stroke.headEndcapSamples)
        }
        
        // Append `samples` to this stroke.
        stroke.strokeSamples += samples
        extruder.append(samples: samples)
        
        strokes.append(stroke)
    }
    
    /// Begins a new stroke.
    ///
    /// This generates a tail endcap at the end of the previous extrusion (if needed),
    /// and generates a new head endcap when the next sample is added.
    mutating func beginNewStroke() {
        // Finalize the stroke currently at the tail of the curve.
        // This generates the tail endcap of this last stroke if it hasn't been generated yet.
        finalizeLastStroke()
        
        // Push a new stroke if the most recent stroke is not already empty.
        if strokes.isEmpty || !strokes.last!.strokeSamples.isEmpty {
            strokes.append(BrushStroke(headEndcapSamples: [], strokeSamples: [], tailEndcapSamples: []))
        }
    }
}
