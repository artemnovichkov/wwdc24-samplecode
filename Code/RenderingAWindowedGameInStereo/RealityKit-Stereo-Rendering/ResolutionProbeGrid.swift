/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Grid of probes where each probe gets a "pixels per meters" value.
*/

import SwiftUI
import RealityKit

func clamp(_ value: Float, min: Float, max: Float) -> Float {
    if value > max {
        return max
    } else if value < min {
        return min
    } else {
        return value
    }
}

private func samples(from begin: Double, through end: Double, count: Int) -> [Double] {
    var result = Array(stride(from: begin, through: end, by: (end - begin) / Double(count - 1)))

    if result.count < count {
        result.append(end)
    }

    return result
}

private func samples(in interval: ClosedRange<Double>, count: Int) -> [Double] {
    return samples(from: interval.lowerBound, through: interval.upperBound, count: count)
}

private func horizontalLocations(count: Int, textureSize: MTLSize) -> [Double] {
    let magnitude = 0.4 * min(1.0, Double(textureSize.width) / Double(textureSize.height))

    return samples(in: -magnitude...magnitude, count: count)
}

private func verticalLocations(count: Int, textureSize: MTLSize) -> [Double] {
    let magnitude = 0.4 * min(1.0, Double(textureSize.height) / Double(textureSize.width))

    return samples(in: (-magnitude ... magnitude), count: count).reversed()
}

struct ResolutionProbeGrid: RateFactorProviding {
    var probeGridRows = [[ResolutionProbeEntity]]()
    var probeGridRoot = {
        let entity = Entity()
        entity.name = "Resolution Probe Grid"
        entity.components.set(OpacityComponent(opacity: 0.5))
        return entity
    }()

    var textureSize: MTLSize

    var isVisible: Bool = true {
        didSet {
            probeGridRoot.components[OpacityComponent.self]?.opacity = isVisible ? 0.5 : 0.0
        }
    }

    mutating func addGridProbes(vertical: Int, horizontal: Int) {
        let probeScale = simd_float3(0.3, 0.3, 0.3)

        probeGridRows = [[ResolutionProbeEntity]](repeating: [], count: vertical)

        for (indexY, positionY) in verticalLocations(count: vertical, textureSize: textureSize).enumerated() {
            for positionX in horizontalLocations(count: horizontal, textureSize: textureSize) {
                let probe = ResolutionProbeEntity()
                probe.transform.translation = .init(Float(positionX), Float(positionY), 0.0)
                probe.transform.scale = probeScale

                probeGridRows[indexY].append(probe)

                probeGridRoot.addChild(probe)
            }
        }
    }

    func rateFactors(entity: Entity) -> RateFactors? {
        var horizontal = [Float](repeating: 0.1, count: probeGridRows.first!.count)
        var vertical = [Float](repeating: 0.1, count: probeGridRows.count)

        guard let transform = entity.transformMatrix(relativeTo: .scene) else { return nil }
        let maxScale = (transform * simd_float4(1, 1, 1, 0)).max()
        let widthInMeters = entity.visualBounds(relativeTo: entity).extents.x * maxScale
        let widthInPixels = textureSize.width
        let maxPixelsPerMeter = Float(widthInPixels) / widthInMeters

        for (rowIdx, row) in probeGridRows.enumerated() {
            for (colIdx, probe) in row.enumerated() {
                let res = clamp(probe.pixelsPerMeter / maxPixelsPerMeter, min: 0.1, max: 1.0)

                horizontal[colIdx] = max(horizontal[colIdx], res)
                vertical[rowIdx] = max(vertical[rowIdx], res)
            }
        }

        return .init(horizontal: horizontal, vertical: vertical)
    }
}

extension Array where Element == Float {
    func expandedUsingInterpolation() -> Self {
        let elementCount = (count - 1) * 2 + 1

        var result = Self()
        result.reserveCapacity(elementCount)

        for index in 0..<count - 1 {
            result.append(self[index])
            result.append( (self[index] + self[index + 1]) / 2)
        }
        result.append(self.last!)

        return result
    }

    // Smooth the values in this 1D array by using a simple 3 element sliding window
    func smoothed() -> Self {
        var result = Self()
        result.reserveCapacity(self.count)

        for index in 0..<count {
            let average = (
                self[Swift.max(0, index - 1)] +
                self[index] +
                self[Swift.min(count - 1, index + 1)]
            ) / 3.0
            result.append(average)
        }

        return result
    }
}

extension RateFactors {
    func smoothed(_ smoothed: Bool) -> RateFactors {
        return smoothed ? self.smoothed() : self
    }

    func smoothed() -> RateFactors {
        let smoothedHorizontal = horizontal.expandedUsingInterpolation().smoothed()
        let smoothedVertical = vertical.expandedUsingInterpolation().smoothed()

        return RateFactors(horizontal: smoothedHorizontal, vertical: smoothedVertical)
    }
}
