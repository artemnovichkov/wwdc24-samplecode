/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main camera user interface.
*/

import Photos
import SwiftUI

struct CameraView: View {
    // The data model object.
    @State private var model = DataModel()
    
    // A Boolean value that indicates whether constant color is enabled.
    @State private var constantColorEnabled = false
    
    // A Boolean value that indicates whether fallback photo delivery is enabled.
    @State private var fallbackPhotoDeliveryEnabled = false
    
    // A Boolean value that indicates whether flash is enabled.
    @State private var flashEnabled = false
    
    // A Boolean value that indicates whether the user attempted to capture a constant color photo with flash capture disabled.
    @State private var showFlashError = false
    
    // A Boolean value that indicates whether the user attempted fallback photo delivery with constant color disabled.
    @State private var showFallbackPhotoDeliveryError = false
    
    // A environment value to indicate scene phase changes.
    @Environment(\.scenePhase) var scenePhase
    
    // The main camera view.
    var body: some View {
        NavigationStack {
            VStack {
               if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
                    Text("You haven't authorized ConstantColorCam to use the camera. Change these settings in Settings -> Privacy & Security.")
                    Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                        .resizable()
                        .symbolRenderingMode(.multicolor)
                        .aspectRatio(contentMode: .fit)
                } else {
                    ViewFinderView(image: $model.viewfinderImage)
                    bottomBarView
                        .fullScreenCover(isPresented: $model.camera.photosViewVisible) {
                            PhotosTabView(
                                normalPhoto: model.camera.normalPhoto,
                                constantColorImage: model.camera.constantColorPhoto,
                                fallbackPhoto: model.camera.fallbackFrame,
                                confidenceMap: model.camera.confidenceMap,
                                confidenceLevel: model.camera.confidenceLevel
                            )
                        }
                    // Present an alert sheet if the user attempts to capture a constant color photo with flash capture disabled.
                    .alert("Photo Capture Error!", isPresented: $showFlashError) {
                        Button("OK") { }
                    } message: {
                        Text("The constant color algorithm requires flash. Please make sure to set AVCaptureSettings's flashMode to either .on or .auto; otherwise, an exception will be thrown.")
                    }
                    // Present an alert sheet if the user attempts to capture fallback photo delivery enabled with constant color disabled.
                    .alert("Photo Capture Error!", isPresented: $showFallbackPhotoDeliveryError) {
                        Button("OK") { }
                    } message: {
                        Text("The Fallback photo delivery requires Constant Color to be enabled. Please make sure to set AVCaptureSettings's isConstantColorEnabled to enabled; otherwise, an exception will be thrown.")
                    }
                }
            }
            .task {
                await model.camera.start()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    Task { await model.camera.checkCameraAuthorization() }
                }
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .ignoresSafeArea()
            .statusBar(hidden: true)
        }
    }
    
    // The main bottom bar view.
    var bottomBarView: some View {
        VStack {
            VStack {
                if model.camera.constantColorSupported {
                    // The constant color text label and toggle.
                    CameraOptionToggle(textLabel: "Constant Color", toggleValue: $constantColorEnabled)
                    // The fallback photo delivery text label and toggle.
                    CameraOptionToggle(textLabel: "Fallback Photo Delivery", toggleValue: $fallbackPhotoDeliveryEnabled)
                }
                // The flash text label and toggle.
                CameraOptionToggle(textLabel: "Flash", toggleValue: $flashEnabled)
            }
            .padding(.top, 15)
            .padding(.horizontal, 20)
            Spacer().frame(height: 10)
            ShutterButton(action: takePhoto)
        }
        .disabled(!model.camera.shutterButtonAvailable)
        .background(.black)
    }
    
    private func takePhoto() {
        if constantColorEnabled && ( flashEnabled == false ) {
            // Show an error if the user attempts to capture a constant color photo with flash capture disabled.
            self.showFlashError = true
        } else if fallbackPhotoDeliveryEnabled && ( constantColorEnabled == false ) {
            // Show an error if the user attempts fallback photo delivery with constant color disabled.
            self.showFallbackPhotoDeliveryError = true
        } else {
            // Update the camera's settings, and capture the photo.
            model.camera.constantColorEnabled = constantColorEnabled
            model.camera.fallBackPhotoDeliveryEnabled = fallbackPhotoDeliveryEnabled
            model.camera.flashEnabled = flashEnabled
            model.camera.takePhoto()
        }
    }
}

struct ShutterButton: View {
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            Label {
                Text("Take Photo")
            } icon: {
                ZStack {
                    Circle()
                        .strokeBorder(.white, lineWidth: !isEnabled ? 3 : 1)
                        .frame(width: !isEnabled ? 65 : 62, height: !isEnabled ? 65 : 62)
                        .animation(.interpolatingSpring(mass: 2.0, stiffness: 100.0, damping: 10, initialVelocity: 0), value: !isEnabled)
                    Circle()
                        .fill(.white)
                        .frame(width: !isEnabled ? 55 : 50, height: !isEnabled ? 55 : 50)
                        .animation(.interpolatingSpring(mass: 2.0, stiffness: 100.0, damping: 10, initialVelocity: 0), value: !isEnabled)
                }
            }
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
    }
}

struct CameraOptionToggle: View {
    private let textLabel: String
    @Binding private var toggleValue: Bool
    
    init(textLabel: String, toggleValue: Binding<Bool>) {
        self.textLabel = textLabel
        self._toggleValue = toggleValue
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(textLabel).font(.caption).padding(.trailing, 4).foregroundColor(.white)
            Toggle("", isOn: $toggleValue).fixedSize().labelsHidden()
        }
    }
}

#Preview {
    CameraView()
}

