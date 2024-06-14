/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays an appropriate capture button for the selected capture mode.
*/

import SwiftUI

/// A view that displays an appropriate capture button for the selected mode.
@MainActor
struct CaptureButton<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    
    private let mainButtonDimension: CGFloat = 68
    
    var body: some View {
        captureButton
            .aspectRatio(1.0, contentMode: .fit)
            .frame(width: mainButtonDimension)
    }
    
    @ViewBuilder
    var captureButton: some View {
        switch camera.captureMode {
        case .photo:
            PhotoCaptureButton {
                Task {
                    await camera.capturePhoto()
                }
            }
        case .video:
            MovieCaptureButton { _ in
                Task {
                    await camera.toggleRecording()
                }
            }
        }
    }
}

#Preview("Photo") {
    CaptureButton(camera: PreviewCameraModel(captureMode: .photo))
}

#Preview("Video") {
    CaptureButton(camera: PreviewCameraModel(captureMode: .video))
}

private struct PhotoCaptureButton: View {
    private let action: () -> Void
    private let lineWidth = CGFloat(4.0)
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .fill(.white)
            Button {
                action()
            } label: {
                Circle()
                    .inset(by: lineWidth * 1.2)
                    .fill(.white)
            }
            .buttonStyle(PhotoButtonStyle())
        }
    }
    
    struct PhotoButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

private struct MovieCaptureButton: View {
    
    private let action: (Bool) -> Void
    private let lineWidth = CGFloat(4.0)
    
    @State private var isRecording = false
    
    init(action: @escaping (Bool) -> Void) {
        self.action = action
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundColor(Color.white)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isRecording.toggle()
                }
                action(isRecording)
            } label: {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: geometry.size.width / (isRecording ? 4.0 : 2.0))
                        .inset(by: lineWidth * 1.2)
                        .fill(.red)
                        .scaleEffect(isRecording ? 0.6 : 1.0)
                }
            }
            .buttonStyle(NoFadeButtonStyle())
        }
    }
    
    struct NoFadeButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }
}
