/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main SwiftUI view.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    let displayTextLeft = """
Yellow:
Orange:
Beige:
Red:
Pink:
Cyan:
Green:
Blue:
"""
    
    let displayTextRight = """
Pivot Drag, Scale, or Rotate
Orientation Preserving Pivot Drag, Scale, or Rotate
Straight Drag, Scale, or Rotate
Pivot Drag Only
Orientation Preserving Pivot Drag only
Straight Drag Only
Scale Only
Rotate Only
"""
    
    var body: some View {
        VStack {
            HStack {
                Text(displayTextLeft)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 100))
                Spacer()
                Text(displayTextRight)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 100))
            }
            .frame(width: 2600)
            
            Spacer()
            RealityView { content in
                // Add the initial RealityKit content
                if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                    content.add(scene)
                }
            } update: { content in

            }
            .installGestures()
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
