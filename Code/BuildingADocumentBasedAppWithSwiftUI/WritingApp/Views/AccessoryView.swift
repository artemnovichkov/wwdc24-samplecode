/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for the accessories.
*/

import SwiftUI

struct AccessoryView: View {
    @Environment(\.horizontalSizeClass) private var horizontal
    @State private var size: CGSize = CGSize()

    var body: some View {
        ZStack {
            Image(.robot)
                .resizable()
                .offset(x: size.width / 2 - 450, y: size.height / 2 - 300)
                .scaledToFit()
                .frame(width: 200)
                .opacity(horizontal == .compact ? 0 : 1)
            Image(.plant)
                .resizable()
                .offset(x: size.width / 2 + 250, y: size.height / 2 - 250)
                .scaledToFit()
                .frame(width: 200)
                .opacity(horizontal == .compact ? 0 : 1)
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { proxySize in
            size = proxySize
        }
    }
}

#Preview {
    AccessoryView()
}
