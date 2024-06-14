/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that represents a beach in the widget.
*/

import SwiftUI

/// Provides a single element representing a beach, as well as actions associated
/// with the beach, including rating it and posting content about it.
struct BeachView: View {
    let beach: Beach

    var body: some View {
        HStack {
            Text(beach.name)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                // The combined element will transform buttons into actions labeled
                // by their title. To retain the favorite status on the element, append
                // it to the name label.
                .accessibilityLabel { label in
                    label
                    Text(beach.rating.label)
                }
            Spacer()
            Group {
                Button(intent: ToggleRatingIntent(beach: beach)) {
                    Image(systemName: beach.rating.imageName)
                }
                .foregroundStyle(.yellow)
                .accessibilityLabel(beach.rating.label)

                Button(intent: ComposeIntent(type: .photo)) {
                    Image(systemName: "camera.fill")
                }
                .accessibilityLabel("Capture Photo")

                Button(intent: ComposeIntent(type: .message)) {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("New Post")
            }
            .foregroundStyle(.white)
        }
        // Combining this element provides a single button with three custom
        // actions for each intent. To make it easier to mark as a top favorite, add a custom action,
        // and for adding a double tap action on iOS, add a magic tap action.
        .accessibilityElement(children: .combine)
        .accessibilityAction(
            named: "Favorite",
            intent: ToggleRatingIntent(beach: beach, rating: .fullStar))
        #if os(iOS)
        .accessibilityAction(.magicTap, intent: ComposeIntent(type: .photo))
        #endif
    }
}
