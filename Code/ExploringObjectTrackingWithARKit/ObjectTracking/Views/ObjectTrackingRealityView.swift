/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view shown inside the immersive space.
*/

import RealityKit
import ARKit
import SwiftUI

@MainActor
struct ObjectTrackingRealityView: View {
    var appState: AppState
    
    var root = Entity()
    
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]

    var body: some View {
        RealityView { content in
            content.add(root)

            Task {
                let objectTracking = await appState.startTracking()
                guard let objectTracking else {
                    return
                }
                
                // Wait for object anchor updates and maintain a dictionary of visualizations
                // that are attached to those anchors.
                for await anchorUpdate in objectTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    let id = anchor.id
                    
                    switch anchorUpdate.event {
                    case .added:
                        // Create a new visualization for the reference object that ARKit just detected.
                        // The app displays the USDZ file that the reference object was trained on as
                        // a wireframe on top of the real-world object, if the .referenceobject file contains
                        // that USDZ file. If the original USDZ isn't available, the app displays a bounding box instead.
                        let model = appState.referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]
                        let visualization = ObjectAnchorVisualization(for: anchor, withModel: model)
                        self.objectVisualizations[id] = visualization
                        root.addChild(visualization.entity)
                    case .updated:
                        objectVisualizations[id]?.update(with: anchor)
                    case .removed:
                        objectVisualizations[id]?.entity.removeFromParent()
                        objectVisualizations.removeValue(forKey: id)
                    }
                }
            }
        }
        .onAppear() {
            print("Entering immersive space.")
            appState.isImmersiveSpaceOpened = true
        }
        .onDisappear() {
            print("Leaving immersive space.")
            
            for (_, visualization) in objectVisualizations {
                root.removeChild(visualization.entity)
            }
            objectVisualizations.removeAll()
            
            appState.didLeaveImmersiveSpace()
        }
    }
}
