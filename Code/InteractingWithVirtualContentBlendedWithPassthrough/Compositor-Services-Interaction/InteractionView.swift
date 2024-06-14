/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for changing app state.
*/

import SwiftUI

private enum VisibilityState: String, CaseIterable, Identifiable {
    case visibleState, hiddenState, automaticState
    var id: Self { self }
    var state: Visibility {
        switch self {
        case .visibleState:
            return .visible
        case .hiddenState:
            return .hidden
        case .automaticState:
            return .automatic
        }
    }
}

private enum IStyle: String, CaseIterable, Identifiable {
    case mixedStyle, fullStyle
    var id: Self { self }
    var style: ImmersionStyle {
        switch self {
        case .mixedStyle:
            return .mixed
        case .fullStyle:
            return .full
        }
    }
}

struct InteractionView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(AppModel.self) var appModel

    @State private var selectedLVState: VisibilityState = .visibleState
    @State private var selectedIStyle: IStyle = .mixedStyle
    
    @State private var tintOpacity = 0.0

    var body: some View {
        VStack {
            if appModel.showImmersiveSpace {
                VStack {
                    Slider(value: $tintOpacity, in: 0...1) {
                        Text("Tint Opacity")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("1")
                    }
                    Text("Tint Opacity \(tintOpacity)")
                        .fontWeight(.semibold)
                        .padding(20)

                    HStack {
                        Text("Immersion Style")
                        Picker("Immersion Style", selection: $selectedIStyle) {
                            Text("Mixed").tag(IStyle.mixedStyle)
                            Text("Full").tag(IStyle.fullStyle)
                        }
                    }
                    HStack {
                        Text("Upper Limbs")
                        Picker("Upper Limb Visibility", selection: $selectedLVState) {
                            Text("Visible").tag(VisibilityState.visibleState)
                            Text("Hidden").tag(VisibilityState.hiddenState)
                            Text("Automatic").tag(VisibilityState.automaticState)
                        }
                    }
                }
            }
            Button {
                appModel.showImmersiveSpace.toggle()
            } label: {
                Text(appModel.showImmersiveSpace ? "Hide Immersive Space" : "Show Immersive Space")
            }
            .animation(.none, value: 0)
            .fontWeight(.semibold)
        }
        .padding()
        .frame(width: 400, height: appModel.showImmersiveSpace ? 400 : 100)
        .onChange(of: scenePhase) { _, newPhase in
            Task { @MainActor in
                if newPhase == .background {
                    appModel.showImmersiveSpace = false
                }
            }
        }
        .onChange(of: selectedLVState) { _, newState in
            appModel.upperLimbVisibility = newState.state
        }
        .onChange(of: tintOpacity) {_, newState in
            appModel.tintOpacity = Float(tintOpacity)
        }
        .onChange(of: selectedIStyle) { _, newStyle in
            appModel.immersionStyle = newStyle.style
        }
    }
}

#Preview(windowStyle: .automatic) {
    InteractionView()
        .environment(AppModel())
}
