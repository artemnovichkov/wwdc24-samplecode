/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application that creates a scene with a settings view and an immersive interactive view.
*/

import SwiftUI
import CompositorServices

struct ContentStageConfiguration: CompositorLayerConfiguration {
    func makeConfiguration(capabilities: LayerRenderer.Capabilities, configuration: inout LayerRenderer.Configuration) {
        configuration.depthFormat = .depth32Float
        configuration.colorFormat = .rgba16Float
    
        let foveationEnabled = capabilities.supportsFoveation
        configuration.isFoveationEnabled = foveationEnabled
        
        let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = foveationEnabled ? [.foveationEnabled] : []
        let supportedLayouts = capabilities.supportedLayouts(options: options)
        
        configuration.layout = supportedLayouts.contains(.layered) ? .layered : .dedicated
    }
}

@main
struct InteractionApp: App {
    
    @State private var appModel = AppModel()
    
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some Scene {
        WindowGroup {
            InteractionView()
                .environment(appModel)
                .onAppear() {
                    if appModel.isFirstLaunch {
                        appModel.isFirstLaunch = false
                        // Immediately show immersive space on first launch.
                        appModel.showImmersiveSpace = true
                    }
                }
                .onChange(of: appModel.showImmersiveSpace) { _, newValue in
                    // Manage the lifecycle of the immersive space.
                    Task { @MainActor in
                        if newValue {
                            switch await openImmersiveSpace(id: ImmersiveInteractionScene.id) {
                            case .opened:
                                appModel.immersiveSpaceIsShown = true
                            case .error, .userCancelled:
                                fallthrough
                            @unknown default:
                                appModel.immersiveSpaceIsShown = false
                                appModel.showImmersiveSpace = false
                            }
                        } else if appModel.immersiveSpaceIsShown {
                            await dismissImmersiveSpace()
                        }
                    }
                }
        }
        .windowResizability(.contentSize)
        
        ImmersiveInteractionScene()
            .environment(appModel)
    }
}

