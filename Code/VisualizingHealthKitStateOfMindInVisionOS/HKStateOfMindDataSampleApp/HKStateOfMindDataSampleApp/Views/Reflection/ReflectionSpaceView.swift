/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An immersive view for reflecting on a feeling.
*/

import SwiftUI
import RealityKit
import HealthKit
import EventKit

#if os(visionOS)
struct ReflectionScene: SwiftUI.Scene {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    let calendars: Calendars
    
    @State private var selectedEmoji: EmojiType?
    
    var passthroughEffect: SurroundingsEffect {
        if let selectedEmoji {
            return .colorMultiply(selectedEmoji.color)
        } else {
            return .systemDark
        }
    }
    
    var body: some SwiftUI.Scene {
        ImmersiveSpace(id: "reflectionSpace") {
            RealityView { content, attachments in
                if let attachmentEntity = attachments.entity(for: "menu") {
                    attachmentEntity.position = [0.35, 1, -1.5]
                    content.add(attachmentEntity)
                }
            } attachments: {
                Attachment(id: "menu") {
                    VStack {
                        ReflectionCurrentEventView(calendars: calendars,
                                                   selectedEmoji: $selectedEmoji)
                    }
                    .padding(25)
                    .glassBackgroundEffect()
                }
            }
            .preferredSurroundingsEffect(passthroughEffect)
        }
    }
}
#endif
