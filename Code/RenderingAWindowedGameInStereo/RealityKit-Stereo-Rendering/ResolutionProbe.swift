/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Probe entity holding an AdaptiveResolutionComponent.
*/

import RealityKit
import SwiftUI
import Combine
import CoreGraphics

class ResolutionProbeEntity: Entity {
    var lastPixelsPerMeter: Float? = nil
    var pixelsPerMeter: Float {
#if os(macOS)
        return 512
#else
        return components[AdaptiveResolutionComponent.self]!.pixelsPerMeter
#endif
    }

    required init() {
        super.init()

        var label = AttributedString("???")
        label.font = .boldSystemFont(ofSize: 140)
        label.foregroundColor = .black

        var text = TextComponent()
        text.text = label
        text.backgroundColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        text.size = CGSize(width: 600, height: 200)
        text.cornerRadius = 100
        self.components.set(text)
        self.components.set(AdaptiveResolutionComponent())
    }

    func intensity(forPpm ppm: Float) -> CGFloat {
        if ppm <= 513.0 {
            return 0.2
        } else if ppm <= 1025.0 {
            return 0.5
        } else {
            return 1.0
        }
    }

    func update() {
        if let ppm = self.components[AdaptiveResolutionComponent.self]?.pixelsPerMeter,
           var text = self.components[TextComponent.self],
           ppm != lastPixelsPerMeter {
            self.lastPixelsPerMeter = ppm

            var label = AttributedString(String(Int(ppm)))
            label.font = .boldSystemFont(ofSize: 140)
            label.foregroundColor = .black

            text.text = label
            text.backgroundColor = CGColor(gray: intensity(forPpm: ppm), alpha: 1.0)

            self.components.set(text)
        }
    }
}

class ResolutionProbeSystem: System {
    required init(scene: RealityKit.Scene) {}

    static let query = EntityQuery(where: .has(AdaptiveResolutionComponent.self))

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            (entity as? ResolutionProbeEntity)?.update()
        }
    }
}
