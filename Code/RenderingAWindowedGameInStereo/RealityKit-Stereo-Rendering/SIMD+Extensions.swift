/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities on SIMD vectors and matrices.
*/

import Foundation
import simd

extension SIMD4 where Scalar == Float {
    init(_ doubles: SIMD4<Double>) {
        self.init(Float(doubles[0]),
                  Float(doubles[1]),
                  Float(doubles[2]),
                  Float(doubles[3]))
    }

    var xyz: SIMD3<Float> {
        get {
            return simd_float3(x, y, z)
        }
        set(newValue) {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
}

extension simd_float4x4 {
    init(_ matrix: simd_double4x4) {
        self.init(SIMD4<Float>(matrix.columns.0),
                  SIMD4<Float>(matrix.columns.1),
                  SIMD4<Float>(matrix.columns.2),
                  SIMD4<Float>(matrix.columns.3))
    }

    func transform(position: SIMD3<Float>) -> SIMD3<Float> {
        (self * SIMD4<Float>(position, 1.0)).xyz
    }
}

