/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Styling information for a post's content.
*/

import SwiftUI

/// A `LabeledContentStyle` for configuring a view that represents a post.
/// Posts contain a primary visual content (such as an image) as well as a description.
/// The view also is configured to provide a data and background color provided
/// through a `PostConfiguration` value.
struct PostLabeledContentStyle: LabeledContentStyle {
    var postConfiguration: PostConfiguration

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.content
                .aspectRatio(contentMode: .fill)
                .frame(width: .infinity)
                .frame(maxHeight: 350)
                .padding(.bottom, 5)
                .clipShape(.rect(
                    topLeadingRadius: 10,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 10
                ))

            VStack(alignment: .leading) {
                Text(postConfiguration.date, format: .dateTime.weekday(.wide))
                    .textCase(.uppercase)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .padding(.top, 3)
                configuration.label
                    .padding(.bottom)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 15)
        }
        .accessibilityElement(children: .combine)
        .contentShape(.accessibility, RoundedRectangle(cornerRadius: 10))
        .background {
            RoundedRectangle(cornerRadius: 10)
                .shadow(radius: 10)
                .foregroundStyle(
                    postConfiguration.color.primaryMix)
        }
    }
}

extension PostLabeledContentStyle {
    struct PostConfiguration {
        var date: Date
        var color: Color
    }
}
