/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a shelf of cards.
*/

import SwiftUI

struct CardShelf: View {
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 40) {
                ForEach(Asset.allCases) { asset in
                    Button {} label: {
                        CardContentView(asset: asset)
                            .padding([.leading, .top, .bottom], 12)
                            .padding(.trailing, 20)
                            .frame(maxWidth: .infinity)
                    }
                    .containerRelativeFrame(.horizontal, count: 3, spacing: 40)
                }
            }
        }
        .scrollClipDisabled()
        .buttonStyle(.card)
    }
}

#Preview {
    CardShelf()
}
