/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import RealityKit

/// The app's main view.
///
/// Displays ``EmitterControls`` in a sidebar and ``EmitterView`` in the detail.
public struct MainView: View {
    /// Stores settings for the particle emitter.
    @EnvironmentObject var emitterSettings: EmitterSettings

    public var body: some View {
        NavigationSplitView {
            // Add the control panel for the particle emitter.
            EmitterControls()
        } detail: {
            // Emit the particles from this view.
            EmitterView()
        }.navigationTitle("Particle Emitter")
    }
}

#Preview(windowStyle: .automatic) {
    MainView()
}

