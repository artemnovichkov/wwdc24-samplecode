/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Evaluates and stores information about strokes based on someone's inputs and style parameters.
*/

import Algorithms
import Collections
import Foundation
import RealityKit

private extension Collection where Element: FloatingPoint {
    
    /// Computes the average over this collection, omitting a number of the largest and smallest values.
    ///
    /// - Parameter truncation: The number or largest and smallest values to omit.
    /// - Returns: The mean value of the collection, after the truncated values are omitted.
    func truncatedMean(truncation: Int) -> Element {
        guard !isEmpty else { return .zero }
        
        var sortedSelf = Deque(sorted())
        let truncationLimit = (count - 1) / 2
        sortedSelf.removeFirst(Swift.min(truncationLimit, truncation))
        sortedSelf.removeLast(Swift.min(truncationLimit, truncation))
        return sortedSelf.reduce(Element.zero) { $0 + $1 } / Element(sortedSelf.count)
    }
}

public struct DrawingSource {
    private let rootEntity: Entity
    private var solidMaterial: RealityKit.Material
    private var sparkleMaterial: RealityKit.Material
    
    private var solidMeshGenerator: SolidDrawingMeshGenerator
    private var smoothCurveSampler: SmoothCurveSampler
    
    private var sparkleMeshGenerator: SparkleDrawingMeshGenerator
    
    private var inputsOverTime: Deque<(SIMD3<Float>, TimeInterval)> = []
    
    private var solidProvider = SolidBrushStyleProvider()
    private var sparkleProvider = SparkleBrushStyleProvider()
    
    private mutating func trace(position: SIMD3<Float>, speed: Float, state: BrushState) {
        switch state.brushType {
        case .uniform:
            let styled = solidProvider.styleInput(position: position, speed: speed,
                                                  settings: state.uniformStyleSettings)
            smoothCurveSampler.trace(point: styled)
        case .calligraphic:
            let styled = solidProvider.styleInput(position: position, speed: speed,
                                                  settings: state.calligraphicStyleSettings)
            smoothCurveSampler.trace(point: styled)
        case .sparkle:
            let styled = sparkleProvider.styleInput(position: position, speed: speed,
                                                    settings: state.sparkleStyleSettings)
            sparkleMeshGenerator.trace(point: styled)
        }
    }
    
    @MainActor
    init(rootEntity: Entity, solidMaterial: Material? = nil, sparkleMaterial: Material? = nil) async {
        self.rootEntity = rootEntity
        
        let solidMeshEntity = Entity()
        rootEntity.addChild(solidMeshEntity)
        self.solidMaterial = solidMaterial ?? SimpleMaterial()
        solidMeshGenerator = SolidDrawingMeshGenerator(rootEntity: solidMeshEntity,
                                                       material: self.solidMaterial)
        smoothCurveSampler = SmoothCurveSampler(flatness: 0.001, generator: self.solidMeshGenerator)
        
        let sparkleMeshEntity = Entity()
        rootEntity.addChild(sparkleMeshEntity)
        self.sparkleMaterial = sparkleMaterial ?? SimpleMaterial()
        sparkleMeshGenerator = SparkleDrawingMeshGenerator(rootEntity: sparkleMeshEntity,
                                                           material: self.sparkleMaterial)
    }
    
    @MainActor
    mutating func receiveSynthetic(position: SIMD3<Float>, speed: Float, state: BrushState) {
        trace(position: position, speed: speed, state: state)
    }
    
    @MainActor
    mutating func receive(input: InputData?, time: TimeInterval, state: BrushState) {
        while let (_, headTime) = inputsOverTime.first, time - headTime > 0.1 {
            inputsOverTime.removeFirst()
        }
        
        if let brushTip = input?.brushTip {
            let lastInputPosition = inputsOverTime.last?.0
            inputsOverTime.append((brushTip, time))
            
            if let lastInputPosition, lastInputPosition == brushTip {
                return
            }
        }
        
        let speedsOverTime = inputsOverTime.adjacentPairs().map { input0, input1 in
            let (point0, time0) = input0
            let (point1, time1) = input1
            let distance = distance(point0, point1)
            let time = abs(time0 - time1)
            return distance / Float(time)
        }
        
        let smoothSpeed = speedsOverTime.truncatedMean(truncation: 2)
        
        if let input, input.isDrawing {
            trace(position: input.brushTip, speed: smoothSpeed, state: state)
        } else {
            if !smoothCurveSampler.isEmpty {
                inputsOverTime.removeAll()
                smoothCurveSampler.beginNewStroke()
            }
            
            if sparkleMeshGenerator.isDrawing {
                sparkleMeshGenerator.endStroke()
            }
        }
    }
}

