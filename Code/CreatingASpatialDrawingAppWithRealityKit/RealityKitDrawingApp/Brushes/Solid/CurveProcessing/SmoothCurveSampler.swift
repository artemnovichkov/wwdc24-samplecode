/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A sampler to interpolate between points to make a smooth curve.
*/

import Collections

/// The `SmoothCurveSampler` ingests "Key Points" of a curve and smooths them into a Catmull-Rom spline.
///
/// These smoothed curve samples are submitted to a `SolidDrawingMeshGenerator` that you provide.
public struct SmoothCurveSampler {
    /// The mesh generator to submit smoothed samples to
    private(set) var curve: SolidDrawingMeshGenerator
    
    /// A parameter that determines how closely the generated samples should conform to the ideal smoothed curve.
    ///
    /// Lower values of flatness will result in more samples but a smoother curve.
    public let flatness: Float
    
    /// True if there are no points on the curve.
    var isEmpty: Bool { return keyPoints.isEmpty }
    
    /// An internal structure that keeps track of how the app samples key points.
    private struct KeyPoint {
        /// The number of samples generated in `keyPoints` between this key and the previous one.
        var sampleCount: Int
        
        /// The styled curve point at this key.
        var point: SolidBrushCurvePoint
    }
    
    /// All of the key points which have been submitted to the `SmoothCurveSampler.`
    private var keyPoints: [KeyPoint] = []
    
    private var positionSpline: LazyMapSequence<[KeyPoint], SIMD3<Float>> {
        keyPoints.lazy.map { $0.point.position }
    }
    
    private func samplePoint(at parameter: Float) -> SolidBrushCurvePoint {
        let radiusSpline = keyPoints.lazy.map { $0.point.radius }
        let colorSpline = keyPoints.lazy.map { $0.point.color }
        let roughnessSpline = keyPoints.lazy.map { $0.point.roughness }
        let metallicSpline = keyPoints.lazy.map { $0.point.metallic }
        
        let position = evaluateCatmullRomSpline(spline: positionSpline, parameter: parameter, derivative: false)
        let radius = evaluateCatmullRomSpline(spline: radiusSpline, parameter: parameter, derivative: false)
        let color = evaluateCatmullRomSpline(spline: colorSpline, parameter: parameter, derivative: false)
        let roughness = evaluateCatmullRomSpline(spline: roughnessSpline, parameter: parameter, derivative: false)
        let metallic = evaluateCatmullRomSpline(spline: metallicSpline, parameter: parameter, derivative: false)
        return SolidBrushCurvePoint(position: position, radius: radius, color: color, roughness: roughness, metallic: metallic)
    }
    
    private func sampleTangent(at parameter: Float) -> SIMD3<Float> {
        let derivative = evaluateCatmullRomSpline(spline: positionSpline, parameter: parameter, derivative: true)
        return approximatelyEqual(derivative, .zero) ? derivative : normalize(derivative)
    }
    
    private mutating func appendCurveSample(parameter: Float, overrideRotationFrame: simd_float3x3? = nil) {
        if curve.samples.isEmpty {
            precondition(approximatelyEqual(parameter, 0), "must add a point at the beginning of the curve first")
        } else {
            precondition(parameter >= curve.samples.last!.parameter, "sample parameter should be strictly increasing")
        }
        
        let point = samplePoint(at: parameter)
        var sample = CurveSample(point: point, parameter: parameter)
        
        if let lastSample = curve.samples.last {
            sample.curveDistance = lastSample.curveDistance + distance(lastSample.position, point.position)
        }
        
        if let overrideRotationFrame {
            sample.rotationFrame = overrideRotationFrame
        } else {
            if let lastSample = curve.samples.last {
                sample.rotationFrame = overrideRotationFrame ?? lastSample.rotationFrame
            }
            
            let derivative = evaluateCatmullRomSpline(
                spline: positionSpline, parameter: parameter, derivative: true
            )
            let tangent = approximatelyEqual(derivative, .zero) ? derivative : normalize(derivative)
            
            if !approximatelyEqual(tangent, .zero) {
                sample.rotationFrame = orthonormalFrame(forward: tangent, up: sample.rotationFrame.columns.1)
            }
        }
        
        curve.pushSamples(curve: [sample])
        
        let keyPointIndex = min(max(0, Int(parameter)), keyPoints.count - 1)
        keyPoints[keyPointIndex].sampleCount += 1
    }
    
    private mutating func appendCurveSamples(range: ClosedRange<Float>) {
        let samples: [Float] = subdivideCatmullRomSpline(spline: positionSpline, range: range, flatness: flatness)
        
        for sample in samples {
            if let lastSample = curve.samples.last {
                let maximumAngleBetweenSamples = Float.pi / 180.0 * 30
                let tangent = sampleTangent(at: sample)
                
                let rotationBetweenSamples = simd_quatf(from: lastSample.tangent, to: tangent)
                let angleBetweenSamples = rotationBetweenSamples.angle
                
                if angleBetweenSamples > maximumAngleBetweenSamples {
                    let rotationAxis = rotationBetweenSamples.axis
                    var frame = lastSample.rotationFrame
                    for angle in stride(from: maximumAngleBetweenSamples / 2, to: angleBetweenSamples, by: maximumAngleBetweenSamples) {
                        let stepRotation = simd_quatf(angle: angle, axis: rotationAxis)
                        let tangent = stepRotation.act(lastSample.tangent)
                        frame = orthonormalFrame(forward: tangent, up: frame.columns.1)
                        
                        let parameter = mix(lastSample.parameter, sample, t: angle / angleBetweenSamples)
                        appendCurveSample(parameter: parameter, overrideRotationFrame: frame)
                    }
                }
            }
            
            appendCurveSample(parameter: sample)
        }
    }
    
    /// Pops the last key point from the curve.
    private mutating func popKeyPoint() -> SolidBrushCurvePoint? {
        guard let lastPoint = keyPoints.popLast() else { return nil }
        curve.removeLast(sampleCount: lastPoint.sampleCount)
        return lastPoint.point
    }
    
    init(flatness: Float, generator: SolidDrawingMeshGenerator) {
        self.flatness = flatness
        curve = generator
    }
    
    /// Replaces the most recently added key point with the provided `point`.
    mutating func replaceHeadKey(point: SolidBrushCurvePoint) {
        // Key point that the app is replacing with `point`.
        _ = popKeyPoint()
        
        trace(point: point)
    }
    
    /// Traces a new key point onto the end of the curve, generating smooth samples as needed.
    mutating func trace(point: SolidBrushCurvePoint) {
        if let previousPoint = popKeyPoint() {
            keyPoints.append(KeyPoint(sampleCount: 0, point: previousPoint))
        }
        keyPoints.append(KeyPoint(sampleCount: 0, point: point))
        
        if curve.samples.isEmpty {
            // Always sample the very beginning of the curve.
            appendCurveSample(parameter: 0)
        }
        
        let lastSampledParameter = curve.samples.last?.parameter ?? 0
        appendCurveSamples(range: lastSampledParameter...Float(keyPoints.count - 1))

        if let lastSampledParameter = curve.samples.last?.parameter,
           !approximatelyEqual(lastSampledParameter, Float(keyPoints.count - 1)) {
            appendCurveSample(parameter: Float(keyPoints.count - 1))
        }
    }
    /// Removes all key points from the currently-generated smooth curve, effectively beginning a new brush stroke.
    mutating func beginNewStroke() {
        keyPoints.removeAll(keepingCapacity: true)
        curve.beginNewStroke()
    }
}
