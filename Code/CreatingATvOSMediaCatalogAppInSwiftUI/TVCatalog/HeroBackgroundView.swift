/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows the background for a hero view.
*/

import SwiftUI

struct HeroBackgroundView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("tvOS with SwiftUI")
                .font(.largeTitle).bold()

            HStack {
                Button("Button 1") {}
                Button("Button 2") {}
                Spacer()
            }

            Spacer()
        }
        .background {
            Image("beach_landscape")
                .resizable()
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.25),
                            .init(color: .black.opacity(0), location: 0.7)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
        }
    }
}

#Preview {
    HeroBackgroundView()
}
