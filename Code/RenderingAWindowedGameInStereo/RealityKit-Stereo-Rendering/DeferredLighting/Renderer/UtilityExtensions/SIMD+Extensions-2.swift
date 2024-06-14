/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience extensions for numeric types.
*/

// MARK: - SIMD4
//extension SIMD4 {
//    // Convenience getter for the first 3 components of a SIMD4 vector.
//    var xyz: SIMD3<Scalar> {
//        self[SIMD3(0, 1, 2)]
//    }
//}

extension Float {
    static var randomSign: Float {
        if Bool.random() {
            return 1
        } else {
            return -1
        }
    }
}
