/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that contains controls to a particle emitter.
*/

import SwiftUI
import RealityKit

/// A view that provides the controls for a particle emitter.
///
/// The controls include sliders, steppers, toggles, and color pickers that
/// alter the particles the emitter produces.
public struct EmitterControls: View {
    /// Stores the particle emitter's current configuration.
    ///
    /// A person can change the particle emitter's behavior
    /// by changing the settings in a ``EmitterControls`` view.
    @EnvironmentObject var emitterSettings: EmitterSettings

    /// The main view for the controls.
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                presetSection
                particleSection
                colorSection
                imageSection
                emitterSection
                burstSection
            }.padding()
        }
    }

    /// The preset picker selector.
    ///
    /// Shown only if ``emitterSettings/showPresets`` is true; a person can
    /// choose a specific preset from the ParticleEmitterComponent presets.
    var presetSection: some View {
        Picker("Preset", selection: $emitterSettings.presetSelection) {
            ForEach(EmitterSettings.EmitterPresets.allCases) { opt in
                Text(opt.rawValue).tag(opt)
            }
        }.pickerStyle(.navigationLink)
            .help("Choose particles preset, or default initializer")
            .onChange(of: emitterSettings.presetSelection, emitterSettings.updateEmitter)
    }

    /// The emitter's main settings.
    ///
    /// The settings control the particles' appearance, speed, lifespan, and so on.
    var particleSection: some View {
        Section {
            LabelSlider(
                label: "Speed \(round(emitterSettings.emitterComponent.speed * 100) / 100)",
                value: $emitterSettings.emitterComponent.speed,
                range: 0...1.5
            ).help("Initial speed of the particles")
            LabelSlider(
                label: "Birth Rate \(Int(emitterSettings.emitterComponent.mainEmitter.birthRate))",
                value: $emitterSettings.emitterComponent.mainEmitter.birthRate,
                range: Float(20)...3000
            ).help("Number of particles spawned per second")
            let angleVariation = emitterSettings.emitterComponent.mainEmitter.angleVariation
            LabelSlider(
                label: "Angle Variation: \(Int(Angle2D(radians: angleVariation).degrees.rounded())) Degrees",
                value: $emitterSettings.emitterComponent.mainEmitter.angleVariation,
                range: Float(0)...(.pi)
            ).help("Randomized variation range of the angle")
            if let spawnedEmitter = emitterSettings.emitterComponent.spawnedEmitter {
                Group {
                    Text("Spawned emitter values:")
                    Text("""
                Birth Rate: \(Int(spawnedEmitter.birthRate))
                Angle Variation: \(Int(Angle2D(radians: spawnedEmitter.angleVariation).degrees.rounded()))
                """).font(.footnote)
                }.help("Some spawned emitter values")
            }
        }

    }

    /// The particle color settings, and the option for a single color
    /// or a transition from one color to another.
    var colorSection: some View {
        Section {
            Text("Color").font(.headline)
            Picker("Color Setting", selection: $emitterSettings.colorSetting) {
                ForEach(EmitterSettings.ColorSetting.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }.pickerStyle(.segmented)
            switch emitterSettings.colorSetting {
                case .constant:
                    ColorPicker("Color", selection: $emitterSettings.color1)
                        .help("Defines the particles color")
                case .random:
                    VStack {
                        ColorPicker("First", selection: $emitterSettings.color1)
                            .help("Defines the start of the color spectrum")
                        ColorPicker("Second", selection: $emitterSettings.color2)
                            .help("Defines the end of the color spectrum")
                    }
                case .evolving:
                    VStack {
                        ColorPicker("Start Color", selection: $emitterSettings.color1)
                            .help("Defines a starting color")
                        ColorPicker("End Color", selection: $emitterSettings.color2)
                            .help("Defines an ending color")
                    }
            }
        }
        .onChange(of: emitterSettings.colorSetting, emitterSettings.updateColors)
        .onChange(of: emitterSettings.color1, emitterSettings.updateColors)
        .onChange(of: emitterSettings.color2, emitterSettings.updateColors)
    }

    /// The particle images, with a choice between several SF Symbol images, and the default particle image.
    var imageSection: some View {
        VStack {
            HStack {
                Text("Image").font(.headline)
                Spacer()
            }
            HStack {
                Spacer()
                ForEach(emitterSettings.particleImages, id: \.self) { imageName in
                    Button(action: {
                        emitterSettings.imageName = imageName
                    }, label: {
                        let isSelected = emitterSettings.imageName == imageName
                        if imageName == "default" {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .frame(depth: isSelected ? 5 : 0)
                                .opacity(isSelected ? 1 : 0.5)
                        } else {
                            Image(systemName: imageName)
                                .frame(depth: isSelected ? 5 : 0)
                                .opacity(isSelected ? 1 : 0.5)
                        }
                    }).help("Update the particles image")
                }
                Spacer()
            }
        }
    }

    /// Settings for emitter visibility, whether it is emitting particles,
    /// and a button to emit a burst of particles.
    var emitterSection: some View {
        Section {
            HStack {
                // Change the shape of the region of space where the system
                // spawns new particles.
                Toggle(isOn: $emitterSettings.showEmitter, label: {
                    Text("Show Emitter").font(.headline)
                }).help("Toggles the visibility of a ModelComponent representing the particle emitter shape and size")
            }
            HStack {
                Spacer()
                // Enable/disable particle emission.
                Toggle(isOn: $emitterSettings.emitterComponent.isEmitting, label: {
                    Text("Emitting").font(.headline)
                }).toggleStyle(.button)
                    .help("Enables the particle emission")
                // Emit `burstCount` particles on the next update call.
                Button(action: {
                    emitterSettings.emitterEntity.components[
                        ParticleEmitterComponent.self
                    ]?.burst()
                }, label: {
                    Text("Burst 🎉")
                }).help("Trigger a burst of particles")
                Spacer()
            }
        }
    }
    @State var emitterShape = "plane"

    /// The settings that control and invoke a transient burst of particles
    /// from the emitter.
    ///
    /// The view has settings that control the number of particles in a burst
    /// and a button that starts a burst.
    var burstSection: some View {
        Section {
        }
    }
}

#Preview {
    HStack {
        EmitterControls()
        EmitterView().ignoresSafeArea()
    }.environment(EmitterSettings())
        .padding()
        .glassBackgroundEffect()
}
