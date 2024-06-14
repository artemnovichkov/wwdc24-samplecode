/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
SwiftUI App, used to define the windows and ImmersiveSpaces of the sample.
*/

import SwiftUI
import RealityKit
import CompositorServices

@main
struct MetalVRRPortalSampleApp: App {
    @Environment(\.openWindow) private var openWindow

    @State var settings = Settings()

    var body: some SwiftUI.Scene {

        WindowGroup(id: "PortalSpaceVolumetric") {
            WindowView(settings: $settings, style: .volumetric)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.6, height: 1.0, depth: 0.5, in: .meters)

        WindowGroup(id: "PortalSpacePlain") {
            WindowView(settings: $settings, style: .plain)
        }
        .windowStyle(.plain)
        .defaultSize(width: 1.6, height: 1.0, depth: 0.5, in: .meters)

        ImmersiveSpace(id: "ImmersiveSpace") {
            OnDismiss {
                settings.stereoscopy = .defaultValue
            }
        }.immersionStyle(selection: .constant(.mixed), in: .mixed)

        ImmersiveSpace(id: "CompositorServicesSpace") {
            CompositorLayer { layerRenderer in
                Task {
                    let frame = layerRenderer.queryNextFrame()
                    let drawable = frame?.queryDrawable()
                    if let views = drawable?.views {
                        settings.headFromEye = [views[0].transform, views[1].transform]
                    }
                    if !settings.windowOpen {
                        openWindow(id: settings.windowID)
                    }
                }
            }
        }

        WindowGroup(id: "Settings") {
            SettingsView(settings: $settings)
        }.defaultSize(width: 600, height: 800)
    }
}

struct WindowView: View {

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @Binding var settings: Settings
    let style: Settings.WindowStyle

    var body: some View {
        DeferredLightingView(settings: $settings)
            .onAppear {
                settings.windowOpen = true
            }
            .onDisappear {
                settings.windowOpen = false

                // Closing the app
                if settings.openImmersiveSpace != .none {
                    Task {
                        await dismissImmersiveSpace()
                    }
                }
            }
            .onChange(of: settings.windowStyle) { oldValue, newValue in
                if newValue != style {
                    openWindow(id: settings.windowID)
                    dismissWindow()
                }
            }
    }
}

extension Settings {

    var windowID: String {
        switch windowStyle {
        case .plain:
            return "PortalSpacePlain"
        case .volumetric:
            return "PortalSpaceVolumetric"
        }
    }
}

struct OnDismiss: View {

    var closure: () -> Void

    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }

    var body: some View {
        EmptyView()
            .onDisappear {
                closure()
            }
    }
}
