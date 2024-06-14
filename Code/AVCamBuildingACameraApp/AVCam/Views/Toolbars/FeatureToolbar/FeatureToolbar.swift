/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents controls to enable capture features.
*/

import SwiftUI

/// A view that presents controls to enable capture features.
struct FeaturesToolbar<CameraModel: Camera>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    var body: some View {
        @Bindable var features = camera.photoFeatures
        
        HStack(spacing: 30) {
            switch camera.captureMode {
            case .photo:
                
                if isCompactSize {
                    livePhotoButton
                    Spacer()
                    prioritizePicker
                } else {
                    Spacer()
                    livePhotoButton
                    prioritizePicker
                }
                
            case .video:
                Spacer()
                if camera.isHDRVideoSupported {
                    hdrButton
                }
            }
        }
        .buttonStyle(DefaultButtonStyle(size: isRegularSize ? .large : .small))
        .padding([.leading, .trailing])
    }
    
    //  A button to toggle the enabled state of Live Photo capture.
    var livePhotoButton: some View {
        Button {
            camera.photoFeatures.isLivePhotoEnabled.toggle()
        } label: {
            VStack {
                Image(systemName: "livephoto")
                    .foregroundColor(camera.photoFeatures.isLivePhotoEnabled ? .accentColor : .primary)
            }
        }
        .frame(width: smallButtonSize.width, height: smallButtonSize.height)
    }
    
    @ViewBuilder
    var prioritizePicker: some View {
        @Bindable var features = camera.photoFeatures
        Picker("Quality Prioritization", selection: $features.qualityPrioritization) {
            ForEach(QualityPrioritization.allCases) {
                Text($0.description)
                    .font(.body.weight(.bold))
            }
        }
        .frame(width: 120)
        .pickerStyle(.menu)
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
    }

    @ViewBuilder
    var hdrButton: some View {
        if isCompactSize {
            hdrToggleButton
        } else {
            hdrToggleButton
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
    }
    
    var hdrToggleButton: some View {
        Button {
            camera.isHDRVideoEnabled.toggle()
        } label: {
            Text("HDR \(camera.isHDRVideoEnabled ? "On" : "Off")")
                .font(.body.weight(.semibold))
                .foregroundStyle(camera.isHDRVideoEnabled ? .accent : .secondary)
        }
        .disabled(camera.captureActivity.isRecording)
    }
    
    @ViewBuilder
    var compactSpacer: some View {
        if !isRegularSize {
            Spacer()
        }
    }
}
