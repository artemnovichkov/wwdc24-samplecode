/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A struct that represents a camera in a scene.
*/

import CoreGraphics

struct Camera {
    var nearPlane: Float
    var farPlane: Float
    var fieldOfView: Float
    var projectionMatrix = simd_float4x4()
    
    mutating func updateProjection(drawableSize: CGSize) {
        let fovyRadians = fieldOfView * Float.pi / 180
        let aspectRatio = Float(drawableSize.width) / Float(drawableSize.height)
        projectionMatrix = Transform.perspectiveProjection(fovyRadians, aspectRatio, nearPlane, farPlane)
    }
}
