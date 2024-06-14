/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The particle settings maintain the app's state that controls the
 particle emitter's behavior.
*/

import SwiftUI
import RealityKit

/// Stores the app's state that controls the particle emitter's behavior.
///
/// People can alter the property values with an ``EmitterControls`` view.
@Observable
public class EmitterSettings: ObservableObject {
    typealias ParticleEmitter = ParticleEmitterComponent.ParticleEmitter
    typealias ParticleColor = ParticleEmitter.ParticleColor
    typealias ParticleColorValue = ParticleColor.ColorValue

    /// The entity for the particle emitter.
    let emitterEntity = Entity()

    /// A particle emitter component for the particle emitter, when in edit mode.
    var emitterComponent = ParticleEmitterComponent()

    /// The selected preset.
    var presetSelection: EmitterPresets = .default {
        didSet {
            typealias Presets = ParticleEmitterComponent.Presets

            switch presetSelection {
                case .default:
                    emitterComponent = ParticleEmitterComponent()
                case .fireworks:
                    emitterComponent = Presets.fireworks
                case .impact:
                    emitterComponent = Presets.impact
                case .magic:
                    emitterComponent = Presets.magic
                case .rain:
                    emitterComponent = Presets.rain
                case .snow:
                    emitterComponent = Presets.snow
                case .sparks:
                    emitterComponent = Presets.sparks
            }
            imageName = "default"
            updateColorControls()
        }
    }

    init() {
        emitterComponent.speed = 0.2
        emitterComponent.mainEmitter.birthRate = 150

        emitterEntity.components.set(emitterComponent)
    }

    /// Update the color properties to reflect the current `emitterComponent`.
    func updateColorControls() {
        switch emitterComponent.mainEmitter.color {
            case .constant(let constantColor):
                switch constantColor {
                    case .random(let colorA, let colorB):
                        color1 = SwiftUI.Color(colorA)
                        color2 = SwiftUI.Color(colorB)
                        colorSetting = .random
                    case .single(let color):
                        color1 = SwiftUI.Color(color)
                        colorSetting = .constant
                    @unknown default: return
                }
            case .evolving(let startColor, let endColor):
                switch (startColor, endColor) {
                    case (.single(let colorA), .single(let colorB)):
                        color1 = SwiftUI.Color(colorA)
                        color2 = SwiftUI.Color(colorB)
                        colorSetting = .evolving
                    default: print("complex color cases are not handled in this app")
                }
            @unknown default: return
        }
    }

    /// An enumeration of particle effect presets.
    ///
    /// This enum provides a selection of predefined particle effect presets based on
    /// `ParticleEmitterComponent.Presets`, as well as a `default` case.
    /// These presets apply common particle effects, such as fireworks or rain.
    enum EmitterPresets: String, CaseIterable, Identifiable {
        var id: Self { self }
        case `default`, fireworks, impact, magic, rain, snow, sparks

        /// Retrieves the `ParticleEmitterComponent` associated with the preset.
        ///
        /// This computed property maps each preset case to a corresponding
        /// `ParticleEmitterComponent`, which defines the visual
        /// and behavioral characteristics of the particle effect.
        var component: ParticleEmitterComponent {
            switch self {
                case .default: ParticleEmitterComponent()
                case .fireworks: .Presets.fireworks
                case .impact: .Presets.impact
                case .magic: .Presets.magic
                case .rain: .Presets.rain
                case .snow: .Presets.snow
                case .sparks: .Presets.sparks
            }
        }
    }

    /// A Boolean value that indicates whether a model representing
    /// the emitter's shape is visible, as a visual aid.
    var showEmitter: Bool = false {
        didSet {
            updateEmitter()
        }
    }

    /// Update the emitter's visual representation.
    func updateEmitter() {
        guard showEmitter else {
            emitterEntity.components.remove(ModelComponent.self)
            return
        }

        let eSize = emitterSize
        let modelMesh: MeshResource = switch emitterComponent.emitterShape {
        case .sphere: MeshResource.generateSphere(radius: eSize)
        case .box: MeshResource.generateBox(size: eSize * 2)
        case .plane: MeshResource.generateBox(size: [eSize * 2, eSize * 0.1, eSize * 2])
        case .cone: MeshResource.generateCone(height: eSize * 1.6, radius: eSize)
        case .cylinder: .generateCylinder(height: eSize * 2, radius: eSize)
        case .point: .generateSphere(radius: 0.01)
        default: MeshResource.generateSphere(radius: eSize / 2)
        }
        emitterEntity.components.set(ModelComponent(
            mesh: modelMesh,
            materials: [UnlitMaterial(color: .white.withAlphaComponent(0.1))]
        ))
    }

    /// The size of the emitter's shape, in meters.
    var emitterSize: Float = 0.1 {
        didSet {
            emitterComponent.emitterShapeSize = .init(repeating: emitterSize)
            updateEmitter()
        }
    }

    /// The first of up to two colors in the particle editor.
    var color1 = SwiftUI.Color.red

    /// The second of two colors in the particle editor.
    var color2 = SwiftUI.Color.purple

    /// Represents the state of the color setting.
    enum ColorSetting: String, CaseIterable, Identifiable {
        public var id: Self { self }
        case constant
        case random
        case evolving
    }

    /// A setting that indicates whether the particles' color is constant or
    /// evolving.
    var colorSetting: ColorSetting = .evolving

    /// A list of image names that change the shape of each particle.
    ///
    /// The first entry of `"default"` assigns `nil` to the emitter's image.
    /// The other names refer to images of SF Symbols.
    var particleImages: [String] = [
        "default", "sparkles", "heart.fill", "exclamationmark.triangle.fill"
    ]

    /// A setting that indicates which image the emitter applies to the particles.
    var imageName = "default" {
        didSet { updateImage() }
    }

    /// Updates the particles' appearance with the current image.
    func updateImage() {

        let textureResource: TextureResource?

        if imageName == "default" {
            typealias Presets = ParticleEmitterComponent.Presets
            textureResource = switch presetSelection {
                case .fireworks: Presets.fireworks.mainEmitter.image
                case .impact: Presets.impact.mainEmitter.image
                case .magic: Presets.magic.mainEmitter.image
                case .rain: Presets.rain.mainEmitter.image
                case .snow: Presets.snow.mainEmitter.image
                case .sparks: Presets.sparks.mainEmitter.image
                case .default: nil
            }
        } else {
            textureResource = generateTextureFromSystemName(imageName)
        }

        emitterComponent.mainEmitter.image = textureResource
    }

    /// Creates a new white texture resource from an SF Symbol image.
    ///
    /// - Parameter systemName: The name of a system symbol image.
    ///
    /// The method applies the symbol's transparency to the texture.
    func generateTextureFromSystemName( _ name: String) -> TextureResource? {
        let imageSize = CGSize(width: 128, height: 128)
        
        // Create a UIImage from a symbol name.
        guard var symbolImage = UIImage(systemName: name) else {
            return nil
        }

        // Create a new version that always uses the template rendering mode.
        symbolImage = symbolImage.withRenderingMode(.alwaysTemplate)

        // Start the graphics context.
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)

        // Set the color's texture to white so that the app can apply a color
        // on top of the image.
        UIColor.white.set()

        // Draw the image with the context.
        let rectangle = CGRect(origin: CGPoint.zero, size: imageSize)
        symbolImage.draw(in: rectangle, blendMode: .normal, alpha: 1.0)

        // Retrieve the image from the context.
        let contextImage = UIGraphicsGetImageFromCurrentImageContext()

        // End the graphics context.
        UIGraphicsEndImageContext()

        // Retrieve the Core Graphics version of the image.
        guard let coreGraphicsImage = contextImage?.cgImage else {
            return nil
        }

        // Generate the texture resource from the Core Graphics image.
        let creationOptions = TextureResource.CreateOptions(semantic: .raw)
        return try? TextureResource.generate(from: coreGraphicsImage,
                                             options: creationOptions)
    }

    /// Updates the color of the particles with the current color settings.
    func updateColors() {
        switch colorSetting {
            case .constant: setConstantColor(color1)
            case .random: setRandomColor(color1, color2)
            case .evolving: setEvolvingColor(color1, color2)
        }
    }

    /// Configures a constant color for the emitter's particles.
    ///
    /// - Parameter swiftUIColor: A SwiftUI color instance.
    func setConstantColor(_ swiftUIColor: SwiftUI.Color) {
        // Create a single color value instance.
        let color1 = ParticleEmitter.Color(swiftUIColor)
        let singleColorValue = ParticleColorValue.single(color1)

        // Create a constant color from the single color value.
        let constantColor = ParticleColor.constant(singleColorValue)

        // Change the particle color for the emitter.
        emitterComponent.mainEmitter.color = constantColor

        // Replace the entity's emitter component with the current configuration.
        emitterEntity.components.set(emitterComponent)
    }

    /// Configures a constant color for the emitter's particles, which the
    /// method randomly selects from a interpolation range between two colors.
    ///
    /// - Parameters:
    ///   - swiftUIColor1: A color instance that represents one end of the range
    ///   of possible colors for the emitter's particles.
    ///   - swiftUIColor2: Another color instance that represents the other end
    ///   of the range of possible colors for the emitter's particles.
    func setRandomColor(_ swiftUIColor1: SwiftUI.Color,
                        _ swiftUIColor2: SwiftUI.Color) {
        // Create a random color value instance between two colors.
        let color1 = ParticleEmitter.Color(swiftUIColor1)
        let color2 = ParticleEmitter.Color(swiftUIColor2)
        let randomColor = ParticleColorValue.random(a: color1, b: color2)

        // Create a constant color from the random color value.
        let constantColor = ParticleColor.constant(randomColor)

        // Change the particle color for the emitter.
        emitterComponent.mainEmitter.color = constantColor

        // Replace the entity's emitter component with the current configuration.
        emitterEntity.components.set(emitterComponent)
    }

    /// Configures the color of the emitter's particles to an evolving color
    /// that gradually shifts from one color to another over time.
    ///
    /// - Parameters:
    ///   - swiftUIColor1: The initial color for the emitter's particles.
    ///   - swiftUIColor2: The final color for the emitter's particles.
    func setEvolvingColor(_ swiftUIColor1: SwiftUI.Color,
                          _ swiftUIColor2: SwiftUI.Color) {

        // Create two single color value instances.
        let color1 = ParticleEmitter.Color(swiftUIColor1)
        let color2 = ParticleEmitter.Color(swiftUIColor2)
        let singleColorValue1 = ParticleColorValue.single(color1)
        let singleColorValue2 = ParticleColorValue.single(color2)

        // Create an evolving color that shifts from one color value to another.
        let evolvingColor = ParticleColor.evolving(start: singleColorValue1,
                                                   end: singleColorValue2)

        // Change the particle color for the emitter.
        emitterComponent.mainEmitter.color = evolvingColor

        // Replace the entity's emitter component with the current configuration.
        emitterEntity.components.set(emitterComponent)
    }
}

extension ParticleEmitterComponent.EmitterShape: CaseIterable, Identifiable {
    public var id: Self { self }
    public static var allCases: [ParticleEmitterComponent.EmitterShape] = [
        .plane, .cylinder, .point
    ]
    var description: String {
        switch self {
            case .box: "box"
            case .point: "point"
            case .plane: "plane"
            case .sphere: "sphere"
            case .cone: "cone"
            case .cylinder: "cylinder"
            case .torus: "torus"
            @unknown default: "default"
        }
    }
}
