/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view for the app's window.
*/
import SwiftUI
import RealityKit

/// The interface of the app.
///
/// This view opens the immersive space and starts room tracking.
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @Environment(AppState.self) var appState
    
    @State private var visualization = "None"
    var modes = ["None", "Occlusion", "Wall"]
    
    var body: some View {
        Group {
            if appState.errorState != .noError {
                errorView
            } else if appState.isImmersive {
                viewWhileImmersed
            } else {
                viewWhileNonImmersed
            }
        }
        .padding()
        .frame(width: 600)
        .onChange(of: scenePhase) {
            if scenePhase != .active && appState.isImmersive {
                Task {
                    await dismissImmersiveSpace()
                    appState.isImmersive = false
                    appState.showPreviewSphere = false
                }
            }
        }
        .onChange(of: appState.errorState) {
            if appState.errorState != .noError && appState.isImmersive {
                Task {
                    await dismissImmersiveSpace()
                    appState.isImmersive = false
                    appState.showPreviewSphere = false
                }
            }
        }
    }
    
    @MainActor var viewWhileNonImmersed: some View {
        VStack {
            Spacer()
            Text("Enter the immersive space to start room tracking.")
            Spacer()
            Button("Enter immersive space") {
                Task {
                    await openImmersiveSpace(id: immersiveSpace)
                    appState.isImmersive = true
                }
            }
        }
    }

    @MainActor var viewWhileImmersed: some View {
        VStack(spacing: 25) {
            Spacer()
            Text("Place spheres in your environment, and observe their colors change when you move between rooms.")
            HStack {
                Button("Add a sphere", systemImage: "circle", action: {
                    appState.showPreviewSphere = true
                })
                
                Button("Remove all spheres", systemImage: "xmark.bin", action: {
                    Task {
                        await appState.removeAllWorldAnchors()
                    }
                })
            }
            visualizationPicker
            Button(appState.isWallSelectionLocked ? "Unlock the wall" : "Lock the wall") {
                if appState.readyToLockWall {
                    appState.isWallSelectionLocked.toggle()
                } else {
                    logger.info("Not ready to lock a wall.")
                }
            }.disabled(visualization != "Wall")

            Spacer()
            Button("Leave immersive space") {
                Task {
                    await dismissImmersiveSpace()
                    appState.isImmersive = false
                }
            }
        }
    }
    
    @MainActor var errorView: some View {
        var message: String
        switch appState.errorState {
        case .noError: message = "" // Empty string, since the app only shows this view in case of an error.
        case .providerNotAuthorized: message = "The app hasn't authorized one or more data providers."
        case .providerNotSupported: message = "This device doesn't support one or more data providers."
        case .sessionError(let error): message = "Running the ARKitSession failed with an error: \(error)."
        }
        return Text(message)
    }
    
    @MainActor var visualizationPicker: some View {
        HStack {
            Text("Room Visualization:")
            Picker("visualization", selection: $visualization) {
                ForEach(modes, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 400)
            .onChange(of: visualization) {
                Task {
                    switch visualization {
                    case "None":
                        appState.visualizationState = .none
                    case "Occlusion":
                        appState.visualizationState = .occlusion
                    case "Wall":
                        appState.visualizationState = .wall
                    default:
                        return
                    }
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
