/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Styling information for a comment's label.
*/

import SwiftUI

/// A `View` representing a comment with an unread indicator and a text-based
/// comment value associated with the unread status.
struct CommentMessageView<Icon: View, Title: View>: View {
    struct Configuration {
        var icon: Icon
        var title: Title
    }
    var configuration: Configuration

    init(@ViewBuilder icon: () -> Icon, @ViewBuilder title: () -> Title) {
        configuration = Configuration(icon: icon(), title: title())
    }

    var body: some View {
        HStack {
            configuration.icon
                .frame(width: 10, height: 10)
                .foregroundStyle(.blue)
                .padding(.leading, 10)

            configuration.title
                .modifier(CommentModifier(style: .quaternary))
        }
    }
}

struct CommentModifier<Style: ShapeStyle>: ViewModifier {
    var style: Style

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 3)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(style)
            }
            .frame(width: .infinity, height: .infinity)
            .padding(.top, 3)
            // Clients like VoiceOver can customize the messaging style of the
            // text content indicating to prioritize speech setting for messaging contexts.
            .accessibilityTextContentType(.messaging)
    }
}
