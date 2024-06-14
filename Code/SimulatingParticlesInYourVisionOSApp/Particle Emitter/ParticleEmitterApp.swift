/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main entry point.
*/

import SwiftUI

@main
struct ParticleEmitterApp: App {
    /// Stores settings for the particle emitter.
    @ObservedObject public var emitterSettings = EmitterSettings()

    var body: some Scene {
        WindowGroup {
            MainView()
        }.environment(emitterSettings)
    }
}
