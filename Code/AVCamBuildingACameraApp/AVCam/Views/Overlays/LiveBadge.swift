/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that the app presents to indicate that Live Photo capture is active.
*/

import SwiftUI

/// A view that the app presents to indicate that Live Photo capture is active.
struct LiveBadge: View {
    var body: some View {
        Group {
            Text("LIVE")
                .padding(6)
                .foregroundColor(.white)
                .font(.subheadline.bold())
        }
        .background(Color.accentColor.opacity(0.9))
        .clipShape(.buttonBorder)
    }
}

#Preview {
    LiveBadge()
        .padding()
        .background(.black)
}

