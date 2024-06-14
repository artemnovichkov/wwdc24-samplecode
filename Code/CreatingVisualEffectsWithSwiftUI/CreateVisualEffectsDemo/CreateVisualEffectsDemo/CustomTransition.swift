/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Examples for using custom transitions and composing built-in transition
 modifiers.
*/

import SwiftUI

#Preview("Custom Transition") {
    @Previewable @State var isVisible: Bool = true

    VStack {
        GroupBox {
            Toggle("Visible", isOn: $isVisible.animation())
        }

        Spacer()

        if isVisible {
            Avatar()
                .transition(Twirl())
        }

        Spacer()
    }
    .padding()
}

#Preview("Composing existing transitions") {
    @Previewable @State var isVisible: Bool = true

    VStack {
        GroupBox {
            Toggle("Visible", isOn: $isVisible.animation())
        }

        Spacer()

        if isVisible {
            Avatar()
                .transition(.scale.combined(with: .opacity))
        }

        Spacer()
    }
    .padding()
}

struct Twirl: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(phase.isIdentity ? 1 : 0.5)
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : 10)
            .rotationEffect(
                .degrees(
                    phase == .willAppear ? 360 :
                        phase == .didDisappear ? -360 : .zero
                )
            )
            .brightness(phase == .willAppear ? 1 : 0)
    }
}

struct Avatar: View {
    var body: some View {
        Circle()
            .fill(.blue)
            .overlay {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.5)
                    .foregroundStyle(.white)
            }
            .frame(width: 80, height: 80)
            .compositingGroup()
    }
}
