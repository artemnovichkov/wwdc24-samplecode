/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shared MTLDevice and MTLCommandQueue.
*/

import Foundation
import simd
import Metal

let mtlDevice = MTLCreateSystemDefaultDevice()!

let commandQueue: MTLCommandQueue! = {
    let queue = mtlDevice.makeCommandQueue()
    queue?.label = "Metal VRR Queue"
    return queue
}()

func mtlComputePipeline(named name: String) -> MTLComputePipelineState? {
    guard let function = mtlDevice.makeDefaultLibrary()?.makeFunction(name: name) else {
        return nil
    }

    return try? mtlDevice.makeComputePipelineState(function: function)
}

