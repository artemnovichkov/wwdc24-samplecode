/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that holds the 3D content for the app's immersive space
*/
import ARKit
import SwiftUI
import RealityKit

// A view that lets people interact with RoomAnchors and visualize their behavior, including:
// 1. Placing world anchors as spheres whose color changes based on their relationship to the current room.
// 2. Rendering meshes and planes associated with the current room.
// 3. Rendering the room boundary as an occluder, which hides virtual content outside the current room.
struct WorldAndRoomView: View {
    @Environment(AppState.self) var appState
    
    @State var previewSphere: Entity?
    
    @State private var updateFacingWallTask: Task<Void, Never>? = nil
    
    private func createPreviewSphere() -> ModelEntity {
        let sphereMesh = MeshResource.generateSphere(radius: 0.1)
        let sphereMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.5), roughness: 0.2, isMetallic: false)
        let sphere = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
        
        // Enables gestures on the preview sphere.
        // Looking at the preview and using a pinch gesture causes a world anchored sphere to appear.
        sphere.generateCollisionShapes(recursive: false, static: true)
        // Ensures the preview only accepts indirect input (for tap gestures).
        sphere.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
        
        // The preview sphere only becomes visible once someone clicks the Add a sphere button.
        sphere.isEnabled = false
        
        return sphere
    }

    var body: some View {
        RealityView { content in
            content.add(appState.setupContentEntity())
            
            // Creates a preview sphere that's attached to the head.
            let sphere = createPreviewSphere()
            // Places the preview one meter in front of the head.
            sphere.position = [0, 0, -1]
            
            // Creates a head anchor and attaches the preview sphere.
            let headAnchor = AnchorEntity(.head)
            content.add(headAnchor)
            headAnchor.addChild(sphere)
            
            previewSphere = sphere
            // Updates and renders the wall in front of the person at 10 Hz.
            updateFacingWallTask = run(appState.updateFacingWall, withFrequency: 10)
        }
        .onAppear {
            appState.isImmersive = true
        }
        .onDisappear {
            appState.isImmersive = false
            updateFacingWallTask?.cancel()
        }
        .task {
            await appState.runSession()
        }
        .task {
            await appState.monitorSessionUpdates()
        }
        .task {
            await appState.processRoomTrackingUpdates()
        }
        .task {
            await appState.processWorldTrackingUpdates()
        }
        .onChange(of: appState.showPreviewSphere) {
            previewSphere?.isEnabled = appState.showPreviewSphere
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { event in
            if event.entity == previewSphere {
                Task {
                    // To place a sphere you need to:
                    // 1. Create a world anchor with the translation of that offset transform and add the anchor to the world tracking provider.
                    // 2. Create the sphere's geometry in `processWorldTrackingUpdates()` after you have successfully added the world anchor.
                    await appState.addWorldAnchor(at: event.entity.transformMatrix(relativeTo: nil))
                    appState.showPreviewSphere = false
                }
            }
        })
    }
}

extension WorldAndRoomView {
    /// Runs a given function at an approximate frequency.
    func run(_ function: @escaping () -> Void, withFrequency freqHz: UInt64) -> Task<Void, Never> {
        return Task {
            while true {
                if Task.isCancelled {
                    return
                }
                
                // Sleeps for 1 s / Hz before calling the function.
                let nanoSecondsToSleep: UInt64 = NSEC_PER_SEC / freqHz
                do {
                    try await Task.sleep(nanoseconds: nanoSecondsToSleep)
                } catch {
                    // Sleep fails when the Task is in a canceled state. Exit the loop.
                    return
                }
                
                function()
            }
        }
    }
}

