/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Runs the `MultiDimensionalImmersiveContent` app.
*/
 
import SwiftUI

@main
struct MultiDimensionalImmersiveContentApp: App {
    var body: some Scene {
        ImmersiveSpace(id: "ImmersiveSpace") {
            RainbowView()
        }
    }
}
