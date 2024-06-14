/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility wrapper on GeometryReader3D that works on all platforms.
*/

import SwiftUI

struct ViewableAreaBounds {
    let widthInMeters: Float
    let heightInMeters: Float
    let worldFromScene: () -> simd_float4x4
}

#if os(visionOS)

/// View helper that provides the viewable bounds, in meters, for a model placed in a RealityView.
///
/// In visionOS, it provides the width and height of a window or volumetric window.
///
/// In iOS, iPadOS, and macOS, it provides the viewable width and height for a model placed at the origin,
/// assuming the default camera position.
struct ViewableAreaReader<Content: View>: View {
    public var content: (ViewableAreaBounds) -> Content

    public init(@ViewBuilder content: @escaping (ViewableAreaBounds) -> Content) {
        self.content = content
    }

    @Environment(\.physicalMetrics) var physicalMetrics

    var body: some View {
        GeometryReader3D { proxy in
            let convert: (Double) -> Float = { value in
                return Float(physicalMetrics.convert(value, to: .meters))
            }
            content(ViewableAreaBounds(widthInMeters: convert(proxy.size.width),
                                       heightInMeters: convert(proxy.size.height),
                                       worldFromScene: { proxy.transform(in: .immersiveSpace)?.float4x4 ?? matrix_identity_float4x4 }))
        }
    }
}

#else

/// View helper that provides the viewable bounds, in meters, for a model placed in a RealityView.
///
/// In visionOS, it provides the width and height of a window or volumetric window.
///
/// In iOS, iPadOS, and macOS, it provides the viewable width and height for a model placed at the origin,
/// assuming the default camera position.
struct ViewableAreaReader<Content: View>: View {
    public var content: (ViewableAreaBounds) -> Content

    public init(@ViewBuilder content: @escaping (ViewableAreaBounds) -> Content) {
        self.content = content
    }

    var body: some View {
        content(ViewableAreaBounds(widthInMeters: 2.0, heightInMeters: 2.0))
    }
}

#endif

