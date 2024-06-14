/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a button to switch between available cameras.
*/

import SwiftUI

/// A view that displays a button to switch between available cameras.
struct SwitchCameraButton<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    
    var body: some View {
        Button {
            Task {
                await camera.switchVideoDevices()
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .buttonStyle(DefaultButtonStyle(size: .large))
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
        .disabled(camera.captureActivity.isRecording)
        .allowsHitTesting(!camera.isSwitchingVideoDevices)
    }
}
