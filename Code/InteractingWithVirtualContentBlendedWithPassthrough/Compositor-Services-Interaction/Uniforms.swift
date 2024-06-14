/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Non-varying shader parameters for presenting content.
*/

import CompositorServices

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        .init(x, y, z)
    }
}

extension Uniforms {
    init(drawable: LayerRenderer.Drawable) {
        let simdDeviceAnchor = drawable.deviceAnchor?.originFromAnchorTransform ?? matrix_identity_float4x4

        func createUniforms(forViewIndex viewIndex: Int) -> UniformsPerView {
            let view = drawable.views[viewIndex]
            let viewMatrix = (simdDeviceAnchor * view.transform).inverse
            let projection = drawable.computeProjection(normalizedDeviceCoordinatesConvention: .rightUpBack,
                                                        viewIndex: viewIndex)
            
            return UniformsPerView(modelViewProjectionMatrix: projection * viewMatrix)
        }
        
        let cameraPos = simdDeviceAnchor.columns.3.xyz
        
        let firstView = createUniforms(forViewIndex: 0)
        let views: (UniformsPerView, UniformsPerView)
        if drawable.views.count == 1 {
            views = (firstView, firstView)
        } else {
            views = (firstView, createUniforms(forViewIndex: 1))
        }
        
        self.init(perView: views,
                  cameraPos: cameraPos)
    }
}
