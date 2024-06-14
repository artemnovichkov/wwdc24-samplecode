/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that toggles the camera's capture mode.
*/

import SwiftUI

/// A view that toggles the camera's capture mode.
struct CaptureModeView<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    @Binding private var direction: SwipeDirection
    
    init(camera: CameraModel, direction: Binding<SwipeDirection>) {
        self.camera = camera
        _direction = direction
    }
    
    var body: some View {
        Picker("Capture Mode", selection: $camera.captureMode) {
            ForEach(CaptureMode.allCases) {
                Image(systemName: $0.systemName)
                    .tag($0.rawValue)
            }
        }
        .frame(width: 180)
        .pickerStyle(.segmented)
        .disabled(camera.captureActivity.isRecording)
        .onChange(of: direction) { _, _ in
            let modes = CaptureMode.allCases
            let selectedIndex = modes.firstIndex(of: camera.captureMode) ?? -1
            // Increment the selected index when swiping right.
            let increment = direction == .right
            let newIndex = selectedIndex + (increment ? 1 : -1)
            
            guard newIndex >= 0, newIndex < modes.count else { return }
            camera.captureMode = modes[newIndex]
        }
    }
}

#Preview {
    CaptureModeView(camera: PreviewCameraModel(), direction: .constant(.left))
}
