/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Debug settings that can be configured in the app,
 and that affect the rendering or toggle features.
*/

import SwiftUI

@Observable
class Settings {
    enum Stereoscopy: String, CaseIterable, Identifiable {
        var id: Self { self }

        case mono
        case converging
        case parallel
        case headtracked

        static var defaultValue: Self { .parallel }
    }

    var eyeSeparation: Float = 10.0
    var stereoscopy: Stereoscopy = .defaultValue
    var sceneSpeed: Float = 20.0

    var headFromEye: [simd_float4x4]?
    var windowOpen = false

    var isWireframe = false
    var isSmoothed = true
    var hasDebugGrid = false
    var hasRateFactors = false
    var showPhysical = false

    var settingsVisible = false

    var show3DFrame = true

    var viewportScale: Float = 1.2
    var viewportOffsetZ: Float = -0.1

    var convergingCenter: Float = 1.0
    var shiftX: Float = 0.3

    var sceneScale: Float = 1.0
    var sceneTranslation: SIMD3<Float> = .init()

    enum OpenImmersiveSpace {
        case none
        case compositorServices
        case headTracker
    }

    var openImmersiveSpace: OpenImmersiveSpace = .none

    enum WindowStyle: String, CaseIterable, Identifiable {
        case plain
        case volumetric

        var id: Self { self }
    }

    var windowStyle: WindowStyle = .volumetric
}

struct SettingsView: View {

    @Binding var settings: Settings

    struct Parameter<T: View>: View {
        var value: Binding<Float>
        let range: ClosedRange<Float>
        @ViewBuilder var label: () -> T

        init(value: Binding<Float>, range: ClosedRange<Float>, _ label: @escaping () -> T) {
            self.value = value
            self.range = range
            self.label = label
        }

        var body: some View {
            VStack {
                HStack {
                    label()
                    Spacer()
                    Text("\(value.wrappedValue)")
                }
                Slider(value: value, in: range)
            }.padding()
        }
    }

    var body: some View {
        VStack {
            Picker("Stereo", selection: $settings.stereoscopy) {
                ForEach(Settings.Stereoscopy.allCases) { stereoscopy in
                    Text(stereoscopy.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)
            List {
                Section("Window") {
                    Picker("Style", selection: $settings.windowStyle) {
                        ForEach(Settings.WindowStyle.allCases) { style in
                            Text(style.rawValue.capitalized)
                        }
                    }.pickerStyle(.segmented)

                    Parameter(
                        value: $settings.viewportScale,
                        range: 0...2.0
                    ) {
                        Label("Window scale", systemImage: "square.resize")
                    }

                    Parameter(
                        value: $settings.viewportOffsetZ,
                        range: -0.3...0.3
                    ) {
                        Label("Window offset Z", systemImage: "lines.measurement.horizontal")
                    }

                    Toggle(
                        isOn: $settings.show3DFrame,
                        label: { Label("Show 3D frame", systemImage: "photo.artframe") }
                    )
                }

                Section("VRR") {
                    Button("Wireframe", systemImage: settings.isWireframe ? "rectangle.grid.2x2.fill" : "squareshape.split.2x2") {
                        settings.isWireframe.toggle()
                    }
                    .help("Toggle display of wireframe")

                    Button("Debug", systemImage: settings.hasDebugGrid ? "ant.circle.fill" : "ant.circle") {
                        settings.hasDebugGrid.toggle()
                    }
                    .help("Toggle display of 2D grid of samples")

                    Button("Rates", systemImage: settings.hasRateFactors ? "number.circle.fill" : "number.circle") {
                        settings.hasRateFactors.toggle()
                    }
                    .help("Toggle display of 1D rate factors")

                    Button("Physical", systemImage: settings.showPhysical ? "square.resize.up" : "square.resize.down") {
                        settings.showPhysical.toggle()
                    }
                    .help("Toggle between physical and logical views of the texture")

                    Button(
                        "Smoothing",
                        systemImage: settings.isSmoothed ?
                            "chart.line.uptrend.xyaxis.circle.fill" :
                            "chart.line.uptrend.xyaxis.circle"
                    ) {
                        settings.isSmoothed.toggle()
                    }
                    .help("Toggle smoothing of VRR factors")
                }

                switch settings.stereoscopy {
                case .converging, .parallel:
                    Section("Stereo") {
                        Parameter(
                            value: $settings.eyeSeparation,
                            range: 0...50
                        ) {
                            Label("Eye separation", systemImage: "eyes")
                        }

                        switch settings.stereoscopy {
                        case .converging:
                            Parameter(
                                value: $settings.convergingCenter,
                                range: 0.0001...1
                            ) {
                                Label("Converging center", systemImage: "lines.measurement.horizontal")
                            }
                        case .parallel:
                            Parameter(
                                value: $settings.shiftX,
                                range: -1...1
                            ) {
                                Label("Horizontal shift", systemImage: "lines.measurement.horizontal")
                            }
                        default:
                            EmptyView()
                        }
                    }
                case .mono, .headtracked:
                    EmptyView()
                }

                Section("Scene") {
                    Parameter(
                        value: $settings.sceneSpeed,
                        range: 0...50.0
                    ) {
                        Label("Speed", systemImage: "play.square")
                    }

                    Parameter(
                        value: $settings.sceneScale,
                        range: 0...1.0
                    ) {
                        Label("Scale", systemImage: "square.resize")
                    }

                    Parameter(
                        value: $settings.sceneTranslation.x,
                        range: -100...100
                    ) {
                        Label("Translation X", systemImage: "rectangle.portrait.and.arrow.forward")
                    }

                    Parameter(
                        value: $settings.sceneTranslation.y,
                        range: -100...100
                    ) {
                        Label("Translation Y", systemImage: "rectangle.portrait.and.arrow.forward")
                    }

                    Parameter(
                        value: $settings.sceneTranslation.z,
                        range: -100...100
                    ) {
                        Label("Translation Z", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                }
            }
        }.padding()
            .onAppear {
                settings.settingsVisible = true
            }
            .onDisappear {
                settings.settingsVisible = false
            }
    }
}
