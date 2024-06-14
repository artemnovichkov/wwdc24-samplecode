/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Tranform utility functions useful for 3D graphics
  rendering with Metal

  Metal uses column-major matrices and column-vector inputs.

     linearIndex     cr              example with reference elements
      0  4  8 12     00 10 20 30     sx  10  20   tx
      1  5  9 13 --> 01 11 21 31 --> 01  sy  21   ty
      2  6 10 14     02 12 22 32     02  12  sz   tz
      3  7 11 15     03 13 23 33     03  13  1/d  33

   The "cr" names are for <column><row>
*/


// MARK: - Transform Utilities
enum Transform {
    
    /// A 4x4 translation matrix specified by x, y, and z components.
    static func translationMatrix(_ translation: SIMD3<Float>) -> simd_float4x4 {
        let col0 = SIMD4<Float>(1, 0, 0, 0)
        let col1 = SIMD4<Float>(0, 1, 0, 0)
        let col2 = SIMD4<Float>(0, 0, 1, 0)
        let col3 = SIMD4<Float>(translation, 1)
        return .init(col0, col1, col2, col3)
    }

    /// A 4x4 rotation matrix specified by an angle and an axis or rotation.
    static func rotationMatrix(radians: Float, axis: SIMD3<Float>) -> simd_float4x4 {
        let normalizedAxis = simd_normalize(axis)
        
        let ct = cosf(radians)
        let st = sinf(radians)
        let ci = 1 - ct
        let x = normalizedAxis.x
        let y = normalizedAxis.y
        let z = normalizedAxis.z
        
        let col0 = SIMD4<Float>(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0)
        let col1 = SIMD4<Float>(x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0)
        let col2 = SIMD4<Float>(x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0)
        let col3 = SIMD4<Float>(0, 0, 0, 1)
        
        return .init(col0, col1, col2, col3)
    }
    
    /// A 4x4 uniform scale matrix specified by x, y, and z components.
    static func scaleMatrix(_ scale: SIMD3<Float>) -> simd_float4x4 {
        let col0 = SIMD4<Float>(scale.x, 0, 0, 0)
        let col1 = SIMD4<Float>(0, scale.y, 0, 0)
        let col2 = SIMD4<Float>(0, 0, scale.z, 0)
        let col3 = SIMD4<Float>(0, 0, 0, 1)
        
        return .init(col0, col1, col2, col3)
    }
    
    /// Returns a 3x3 normal matrix from a 4x4 model matrix
    static func normalMatrix(from modelMatrix: simd_float4x4) -> simd_float3x3 {
        let col0 = modelMatrix.columns.0.xyz
        let col1 = modelMatrix.columns.1.xyz
        let col2 = modelMatrix.columns.2.xyz
        return .init(col0, col1, col2)
    }
    
    /// A left-handed orthographic projection
    static func orthographicProjection(_ left: Float,
                                       _ right: Float,
                                       _ bottom: Float,
                                       _ top: Float,
                                       _ nearZ: Float,
                                       _ farZ: Float) -> simd_float4x4 {
        
        let col0 = SIMD4<Float>(2 / (right - left), 0, 0, 0)
        let col1 = SIMD4<Float>(0, 2 / (top - bottom), 0, 0)
        let col2 = SIMD4<Float>(0, 0, 1 / (farZ - nearZ), 0)
        let col3 = SIMD4<Float>((left + right) / (left - right), (top + bottom) / (bottom - top), nearZ / (nearZ - farZ), 1)
        return .init(col0, col1, col2, col3)
    }

    /// A left-handed perspective projection
    static func perspectiveProjection(_ fovyRadians: Float,
                                      _ aspectRatio: Float,
                                      _ nearZ: Float,
                                      _ farZ: Float) -> simd_float4x4 {
        let ys = 1 / tanf(fovyRadians * 0.5)
        let xs = ys / aspectRatio
        let zs = farZ / (farZ - nearZ)
        
        let col0 = SIMD4<Float>(xs, 0, 0, 0)
        let col1 = SIMD4<Float>(0, ys, 0, 0)
        let col2 = SIMD4<Float>(0, 0, zs, 1)
        let col3 = SIMD4<Float>(0, 0, -nearZ * zs, 0)
        
        return .init(col0, col1, col2, col3)
    }

    static func perspectiveProjection(left: Float,
                                      right: Float,
                                      top: Float,
                                      bottom: Float,
                                      near: Float,
                                      far: Float) -> simd_float4x4 {
        let xs = 2 * near / (right - left)
        let ys = 2 * near / (top - bottom)
        let zs = far / (far - near)
        
        let col0 = SIMD4<Float>(xs, 0, 0, 0)
        let col1 = SIMD4<Float>(0, ys, 0, 0)
        let col2 = SIMD4<Float>((right + left) / (right - left), (top + bottom) / (top - bottom), zs, 1)
        let col3 = SIMD4<Float>(0, 0, -(far * near) / (far - near), 0)
        
        return .init(col0, col1, col2, col3)
    }

    /// Returns a left-handed matrix which looks from a point (the "eye") at a target point, given the up vector.
    static func look(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
        
        let z = normalize(target - eye)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        let t = SIMD3<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye))
        
        let col0 = SIMD4<Float>(x.x, y.x, z.x, 0)
        let col1 = SIMD4<Float>(x.y, y.y, z.y, 0)
        let col2 = SIMD4<Float>(x.z, y.z, z.z, 0)
        let col3 = SIMD4<Float>(t.x, t.y, t.z, 1)
        
        return .init(col0, col1, col2, col3)
    }
    
}
