/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's primary SwiftUI view.
*/

import SwiftUI
import RealityKit

struct MainView: View {
    /// The entity that physically contains the spheres inside an invisible box.
    @State var containmentCollisionBox = ContainmentCollisionBox()

    var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                addSpheres(content)
                content.add(containmentCollisionBox)
            } update: { content in
                let localFrame = geometry.frame(in: .local)
                let sceneFrame = content.convert(localFrame,
                                                 from: .local, to: .scene)

                containmentCollisionBox.update(sceneFrame)
            }.gesture(ForceDragGesture())
        }
    }

    func addSpheres(_ content: RealityViewContent) {
        for index in 0..<16 {
            let sphereEntity = Entity.metallicSphere()
            sphereEntity.name = "Sphere_\(index)"
            
            // Put the sphere in the scene.
            content.add(sphereEntity)
        }
    }
}
