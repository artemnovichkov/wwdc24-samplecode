/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Object that gets the head position from ARKit.
*/

import SwiftUI
import RealityKit
import ARKit
import Spatial

extension AffineTransform3D {
    var float4x4: simd_float4x4 {
        return simd_float4x4(matrix4x4)
    }
}

@MainActor
class HeadPositionProvider: ObservableObject {
    let arSession = ARKitSession()
    let worldTracking = WorldTrackingProvider()
    var coordinateConverter: RealityCoordinateSpaceConverting?

    init() {
    }

    func start() {
        Task {
            do {
                if WorldTrackingProvider.isSupported {
                    try await arSession.run([worldTracking])
                }
            } catch let error as ARKitSession.Error {
                print("Encountered an error while running providers: \(error.localizedDescription)")
            } catch let error {
                print("Encountered an unexpected error: \(error.localizedDescription)")
            }
        }
    }

    func stop() {

    }

    var presentationTime: CFTimeInterval {
        // Estimate for presentation time. This sample renders at 90 Hz, so estimate
        // two additional frames in the future.
        return CACurrentMediaTime() + 0.033
    }

    var originFromHead: simd_float4x4? {
        self.originFromDeviceTransform(presentationTime)
    }

    private func originFromDeviceTransform(_ time: CFTimeInterval) -> simd_float4x4? {
        guard let devicePose = worldTracking.queryDeviceAnchor(atTimestamp: time) ??
                worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return nil
        }

        return devicePose.originFromAnchorTransform
    }
}
