/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Entity that displays a Metal texture with Variable Rasterization Rates (VRR).
*/

import SwiftUI
import RealityKit
import RealityKit_Assets

#if canImport(ARKit)
import ARKit
#endif

struct RateFactors: Equatable
{
    var horizontal: [Float]
    var vertical: [Float]
}

protocol RateFactorProviding {
    func rateFactors(entity: Entity) -> RateFactors?
}

private func makeSimpleVRRMap(screenSize: MTLSize, device: MTLDevice) -> MTLRasterizationRateMap {
    let descriptor = MTLRasterizationRateMapDescriptor()
    descriptor.label = "Simple VRR Rate Map"
    descriptor.screenSize = MTLSizeMake(screenSize.width, screenSize.height, 0)

    let layerDescriptor = MTLRasterizationRateLayerDescriptor(horizontal: [0.3, 0.6, 1.0, 0.6, 0.3],
                                                              vertical: [0.3, 0.6, 1.0, 0.6, 0.3])
    descriptor.setLayer(layerDescriptor, at: 0)
    return device.makeRasterizationRateMap(descriptor: descriptor)!
}

class RateIndicator: Entity {
    private var displayedRate: Float = 1.0 {
        didSet {
            self.components[TextComponent.self]?.text = rateText
        }
    }

    var rate: Float = 1.0 {
        didSet {
            if abs(rate - displayedRate) > 0.01 {
                displayedRate = rate
            }
        }
    }

    required init() {
        super.init()

        var text = TextComponent()
        text.text = rateText
        text.backgroundColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        text.size = CGSize(width: 200, height: 100)
        text.cornerRadius = 50
        self.components.set(text)
    }

    private var rateText: AttributedString {
        var label = AttributedString(String(format: "%0.1f", displayedRate))
        label.font = .boldSystemFont(ofSize: 60)
        label.foregroundColor = .black
        return label
    }
}

class RateMapIndicators: Entity {
    var horizontalFactors = [Float]()
    var verticalFactors = [Float]()

    private var horizontalIndicators = [RateIndicator]()
    private var verticalIndicators = [RateIndicator]()

    required init() {
    }

    func rebuildIndicators(vertical: Int, horizontal: Int) {
        for indicator in verticalIndicators + horizontalIndicators {
            indicator.removeFromParent()
        }
        verticalIndicators.removeAll()
        horizontalIndicators.removeAll()

        let bounds: BoundingBox = self.parent?.visualBounds(relativeTo: self.parent) ?? .init(center: .zero, extents: .one)

        let stepX = bounds.extents.x / Float(horizontal)
        let stepY = bounds.extents.y / Float(vertical)

        for index in 0..<horizontal {
            let indicator = RateIndicator()
            indicator.position.x = bounds.min.x + stepX * Float(index) + stepX * 0.5
            indicator.position.y = bounds.max.y

            horizontalIndicators.append(indicator)
            self.addChild(indicator)
        }

        for index in 0..<vertical {
            let indicator = RateIndicator()
            indicator.position.x = bounds.min.x
            indicator.position.y = bounds.min.y + stepY * Float(index) + stepY * 0.5

            verticalIndicators.append(indicator)
            self.addChild(indicator)
        }
    }

    func update(vertical: [Float], horizontal: [Float]) {
        if vertical.count != verticalIndicators.count
            || horizontal.count != horizontalIndicators.count {
            rebuildIndicators(vertical: vertical.count, horizontal: horizontal.count)
        }

        for (number, rate) in vertical.enumerated() {
            verticalIndicators[number].rate = rate
        }

        for (number, rate) in horizontal.enumerated() {
            horizontalIndicators[number].rate = rate
        }
    }
}

class PercentageIndicator: Entity {
    private var displayedPercentage: Float = 1.0 {
        didSet {
            self.components[TextComponent.self]?.text = rateText
        }
    }

    var percentage: Float = 1.0 {
        didSet {
            if abs(percentage - displayedPercentage) > 0.01 {
                displayedPercentage = percentage
            }
        }
    }

    required init() {
        super.init()

        var text = TextComponent()
        text.text = rateText
        text.backgroundColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        text.size = CGSize(width: 180, height: 180)
        text.cornerRadius = 90
        self.components.set(text)
    }

    private var rateText: AttributedString {
        var label = AttributedString(String(format: "%0.f%%", displayedPercentage * 100.0))
        label.font = .boldSystemFont(ofSize: 60)
        label.foregroundColor = .black
        return label
    }
}

struct RenderTarget {
    var colorTexture: LowLevelTexture!
    var depthStencilTexture: MTLTexture!
}

let frameBufferShader = LazyAsync {
    return try! await ShaderGraphMaterial(
        named: "/Root/Material",
        from: "FramebufferShader",
        in: assetsBundle
    )
}

@MainActor
func createFramebufferMaterial(leftEyeTexture: LowLevelTexture, rightEyeTexture: LowLevelTexture) async -> ShaderGraphMaterial {
    var material = await frameBufferShader.get()

    await MainActor.run {
        try! material.setParameter(name: "leftEye", value: .textureResource(.init(from: leftEyeTexture)))
        try! material.setParameter(name: "rightEye", value: .textureResource(.init(from: rightEyeTexture)))
    }

    return material
}

class MetalVRREntity: Entity, HasModel {
    var leftEyeTarget = RenderTarget()
    var rightEyeTarget = RenderTarget()
    var monoTarget: RenderTarget {
        leftEyeTarget
    }

    var unwrappingMesh: VRRUnwrappingMesh!

    var unlitMaterial: UnlitMaterial! = nil
    let textureSize = MTLSizeMake(3840, 2160, 1)
    var aspectRatio: Double {
        Double(textureSize.width) / Double(textureSize.height)
    }

    var device: MTLDevice!
    var rateMap: MTLRasterizationRateMap!
    var colorPixelFormat: MTLPixelFormat = .bgra8Unorm_srgb
    var depthStencilPixelFormat: MTLPixelFormat = .depth32Float_stencil8

    func makeRenderTarget() -> RenderTarget {
        let colorTexture = try! LowLevelTexture(descriptor: .init(pixelFormat: .bgra8Unorm_srgb,
                                                                    width: textureSize.width,
                                                                    height: textureSize.height,
                                                                    depth: textureSize.depth,
                                                                    mipmapLevelCount: 1,
                                                                    textureUsage: [.shaderWrite, .shaderRead, .renderTarget]))

        let depthStencilDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: depthStencilPixelFormat,
                                                                              width: textureSize.width,
                                                                              height: textureSize.height,
                                                                              mipmapped: false)
        depthStencilDescriptor.storageMode = .memoryless
        depthStencilDescriptor.usage = [.renderTarget]

        let depthStencilTexture = device.makeTexture(descriptor: depthStencilDescriptor)

        return RenderTarget(colorTexture: colorTexture,
                            depthStencilTexture: depthStencilTexture)
    }

    var monoMaterial: ShaderGraphMaterial!
    var stereoMaterial: ShaderGraphMaterial!

    @MainActor
    func setup() async {

        self.device = MTLCreateSystemDefaultDevice()!
        self.leftEyeTarget = makeRenderTarget()
        self.rightEyeTarget = makeRenderTarget()

        self.rateMap = makeSimpleVRRMap(screenSize: textureSize, device: device)

        self.unwrappingMesh = VRRUnwrappingMesh(maxTextureSize: textureSize)
        self.unwrappingMesh.update(self.rateMap)

        self.monoMaterial = await createFramebufferMaterial(leftEyeTexture: monoTarget.colorTexture,
                                                            rightEyeTexture: monoTarget.colorTexture)

        self.stereoMaterial = await createFramebufferMaterial(leftEyeTexture: leftEyeTarget.colorTexture,
                                                              rightEyeTexture: rightEyeTarget.colorTexture)

        self.components.set(ModelComponent(mesh: try! await MeshResource(from: unwrappingMesh.mesh),
                                           materials: [monoMaterial]))

        let size = CGSize(width: textureSize.width, height: textureSize.height)

        self.createScene(size: size, device: device)

        self.probeGrid = .init(textureSize: textureSize)
        self.probeGrid!.addGridProbes(vertical: 5, horizontal: 7)
        self.addChild(probeGrid!.probeGridRoot)
        probeGrid?.isVisible = false

        let indicators = RateMapIndicators()
        indicators.update(vertical: [1.0, 2.0, 3.0], horizontal: [0.1, 0.2, 0.3, 0.4, 0.5])
        indicators.isEnabled = false
        self.addChild(indicators)
        self.rateMapIndicators = indicators

        let bounds: BoundingBox = self.visualBounds(relativeTo: self)

        self.percentageIndicator = PercentageIndicator()
        self.percentageIndicator!.position = .init(bounds.max.x, bounds.min.y, 0)
        self.percentageIndicator!.isEnabled = false
        self.addChild(percentageIndicator!)
    }

    func createScene(size: CGSize, device: MTLDevice) {}

    var smoothRateMap: Bool = true
    var probeGrid: ResolutionProbeGrid?
    var rateMapIndicators: RateMapIndicators?
    var percentageIndicator: PercentageIndicator?

    private var cycleMaps = true
    private var cycleInterval = 10
    private var updateCount = 0
    private var rateFactors: RateFactors? {
        didSet {
            if let rateFactors {
                rateMapIndicators?.update(vertical: rateFactors.vertical,
                                          horizontal: rateFactors.horizontal)
            }
        }
    }

    func updateRateMap(commandBuffer: MTLCommandBuffer,
                       computeEncoder: MTLComputeCommandEncoder) {
        updateCount += 1

        if cycleMaps && updateCount % cycleInterval == 0 {
            if let factors = probeGrid?.rateFactors(entity: self)?.smoothed(smoothRateMap),
               factors != rateFactors {
                self.rateFactors = factors

                self.rateMap = rateMap(horizontal: factors.horizontal, vertical: factors.vertical)
                self.unwrappingMesh.update(self.rateMap)

                let physical = self.rateMap.physicalSize(layer: 0)
                let screen = self.rateMap.screenSize

                let screenPx = screen.width * screen.height
                let physicalPx = physical.width * physical.height

                self.percentageIndicator?.percentage = Float(physicalPx) / Float(screenPx)
            }
        }
    }

    private func rateMap(horizontal: [Float], vertical: [Float]) -> MTLRasterizationRateMap {
        let descriptor = MTLRasterizationRateMapDescriptor()
        descriptor.label = "Adaptive Rate Map"
        descriptor.screenSize = textureSize

        let layerDescriptor = MTLRasterizationRateLayerDescriptor(horizontal: horizontal,
                                                                  vertical: vertical)
        descriptor.setLayer(layerDescriptor, at: 0)

        return device.makeRasterizationRateMap(descriptor: descriptor)!
    }
}

