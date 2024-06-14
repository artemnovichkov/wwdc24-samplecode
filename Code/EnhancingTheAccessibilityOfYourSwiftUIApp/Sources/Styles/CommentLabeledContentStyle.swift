/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Styling information for a post's content.
*/

import SwiftUI

/// A `LabeledContentStyle` representing a comment with an author for the comment
/// labeling the content of the comment.
struct CommentLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            HStack {
                configuration.content
            }

            configuration.label
                .textCase(.uppercase)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.leading, 32)
        }
        .padding(.trailing, 10)
        .accessibilityElement(children: .combine)
        // By default, the accessibility combine modifier turns buttons into
        // custom actions and applies an `isButton` trait to the combined element
        // when buttons exist. The semantic context of a comment post does not
        // match a button so we remove the trait while keeping the actions.
        .accessibilityRemoveTraits(.isButton)
    }
}
