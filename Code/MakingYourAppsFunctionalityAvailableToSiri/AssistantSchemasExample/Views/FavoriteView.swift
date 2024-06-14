/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a person's favorite photos and videos.
*/

import SwiftUI

struct FavoriteView: View {

    // MARK: Properties

    var isFavorite: Bool

    // MARK: Lifecycle

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.footnote)
            .foregroundColor(.white)
            .shadow(radius: 4)
            .opacity(isFavorite ? 1 : 0)
            .padding(4)
    }
}

#Preview {
    FavoriteView(isFavorite: true)
}
