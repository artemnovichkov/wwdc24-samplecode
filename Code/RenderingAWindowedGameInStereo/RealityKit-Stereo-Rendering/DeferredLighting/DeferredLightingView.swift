/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
RealityEntity rendering the Deferred Lighting scene.
*/

import SwiftUI
import RealityKit
import RealityKit_Assets

struct DeferredLightingComponent: TransientComponent {}


/// Adapts the "Deferred Lighting with Swift" Demo to Metal+VRR+visionOS.
class DeferredLightingEntity: MetalVRREntity {
    var deferredRenderer: Renderer!
    var deferredScene: Scene!
    var settings: Settings!
    var lastStereoscopy: Settings.Stereoscopy?
    var headPositionProvider: HeadPositionProvider?
    
    override func setup() async {
        await super.setup()
        self.components.set(DeferredLightingComponent())
    }

    override func createScene(size: CGSize, device: MTLDevice) {
        deferredScene = Scene(device: device)
        deferredRenderer = SinglePassDeferredRenderer(device: device,
                                                      scene: deferredScene,
                                                      renderDestination: self,
                                                      commandQueue: commandQueue) { [weak self] in
            guard let self else {
                return
            }

            let viewMatrix = Transform.look(eye: deferredScene.eyePosition,
                                            target: deferredScene.targetPosition,
                                            up: deferredScene.up)

            self.deferredScene.simulate(deltaTime: Double(settings?.sceneSpeed ?? 1.0) / 90.0)
            self.deferredScene?.update(viewMatrix: viewMatrix,
                                       projectionMatrix: self.deferredScene.camera.projectionMatrix)
        }

        deferredScene.camera.updateProjection(drawableSize: size)
        // Recreate GBuffer textures to match the new drawable size.
        deferredScene.gBufferTextures.makeTextures(device: device, size: size, storageMode: .memoryless)

        deferredRenderer?.drawableSizeWillChange(size: size)
    }

    func update(commandBuffer: MTLCommandBuffer,
                computeEncoder: MTLComputeCommandEncoder) {
        updateRateMap(commandBuffer: commandBuffer,
                      computeEncoder: computeEncoder)

        if settings.stereoscopy != lastStereoscopy {
            lastStereoscopy = settings.stereoscopy

            switch settings.stereoscopy {
            case .mono:
                self.components[ModelComponent.self]?.materials = [monoMaterial]
            case .converging, .parallel, .headtracked:
                self.components[ModelComponent.self]?.materials = [stereoMaterial]
            }
        }

        deferredRenderer.draw(provider: self)
    }
}

extension simd_float4x4 {
    var removingScaleFactor: simd_float4x4 {
        return simd_float4x4(simd_normalize(self.columns.0),
                             simd_normalize(self.columns.1),
                             simd_normalize(self.columns.2),
                             self.columns.3)
    }
}

extension DeferredLightingEntity: DrawableProviding, RenderDestination {
    func headFromEye(viewIndex: Int) -> simd_float4x4 {
        if let transform = settings?.headFromEye?[viewIndex] {
            return transform
        } else {
            // Average EyeOffset of 63 mm IPD.
            var eyeOffset = simd_float3(-0.0315, -0.0265, -0.034)

            if viewIndex == 1 {
                eyeOffset.x *= -1
            }

            return Transform.translationMatrix(eyeOffset)
        }
    }

    var immersiveFromHead: simd_float4x4 {
        if let immersiveFromHead = headPositionProvider?.originFromHead {
            return immersiveFromHead
        } else {
            return matrix_identity_float4x4
        }
    }

    func viewMatrix(viewIndex: Int) -> simd_float4x4 {
        switch settings.stereoscopy {
        case .mono:
            return Transform.look(eye: deferredScene.eyePosition,
                                  target: deferredScene.targetPosition,
                                  up: deferredScene.up)
        case .converging:
            var eyeOffset = headFromEye(viewIndex: viewIndex).columns.3.xyz
            eyeOffset.x *= settings.eyeSeparation
            let target: SIMD3<Float> = settings.convergingCenter * deferredScene.targetPosition
                + (1 - settings.convergingCenter) * deferredScene.eyePosition
            return Transform.look(eye: deferredScene.eyePosition + eyeOffset,
                                  target: target,
                                  up: deferredScene.up)
        case .parallel:
            var eyeOffset = headFromEye(viewIndex: viewIndex).columns.3.xyz
            eyeOffset.x *= settings.eyeSeparation
            return Transform.look(eye: deferredScene.eyePosition + eyeOffset,
                                  target: deferredScene.targetPosition + eyeOffset,
                                  up: deferredScene.up)
        case .headtracked:
            let portalFromModel = Transform.translationMatrix(-deferredScene.eyePosition)
            let immersiveFromEye = immersiveFromHead * headFromEye(viewIndex: viewIndex)
            let eyePosImmersive = immersiveFromEye * SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
            let portalPositionImmersive = immersiveFromPortal * SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
            let portalToObserver = Transform.translationMatrix(eyePosImmersive.xyz - portalPositionImmersive.xyz)
            let modelToObserver = portalToObserver * portalFromModel
            return modelToObserver
        }
    }

    /// Returns a matrix that converts coordinates (in meters) from the portal's coordinate system
    /// to the origin coordinate system of ARKit.
    var immersiveFromPortal: simd_float4x4 {
        
        if let matrix = transformMatrix(relativeTo: .immersiveSpace) {
            return matrix
        }

        // Get the transform from the immersive space to the RealityKit scene of the WindowGroup instance.
        // The scene is at the center of the volumetric space.
        if let sceneFromImmersive = headPositionProvider?
            .coordinateConverter?
            .transform(from: .immersiveSpace, to: .scene)
            .float4x4
            .removingScaleFactor {

            // The portal is at the origin of the RealityKit scene.
            let immersiveFromPortal = (sceneFromImmersive * simd_float4x4(diagonal: [1, -1, 1, 1])).inverse

            return immersiveFromPortal
        } else {
            let sceneFromPortal = self.transformMatrix(relativeTo: .scene)!

            return sceneFromPortal
        }
    }

    func asymmetricProjection(portalFromEye: simd_float4x4) -> simd_float4x4 {
        // Extract the position component only.
        let eyeInPortalCoordinates = portalFromEye.columns.3.xyz

        // Compute the asymmetric projection matrix by determining the portal origin point coordinates in eye space
        // and offsetting half-width/-height from it to obtain left, right, top, and bottom tangents.
        let size = self.unwrappingMesh.mesh.parts[0].bounds.max - self.unwrappingMesh.mesh.parts[0].bounds.min
        let width = size.x * self.scale.x
        let height = size.y * self.scale.y

        let scaledHeight = tanf(deferredScene.camera.fieldOfView * Float.pi / 180)
        let scale = scaledHeight / height
        
        let halfWidth: Float = width * 0.5
        let halfHeight: Float = height * 0.5

        let distance = abs(eyeInPortalCoordinates.z)
        let zNear = distance
        let zFar = zNear + Float(deferredScene.camera.farPlane)

        let left = (eyeInPortalCoordinates.x - halfWidth) * scale
        let right = (eyeInPortalCoordinates.x + halfWidth) * scale
        let bottom = (eyeInPortalCoordinates.y - halfHeight) * scale
        let top = (eyeInPortalCoordinates.y + halfHeight) * scale

        let asymmetricProjection = Transform.perspectiveProjection(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            near: zNear,
            far: zFar
        )

        return asymmetricProjection
    }

    func projectionMatrix(viewIndex: Int) -> simd_float4x4 {
        switch settings.stereoscopy {
        case .mono:
            return deferredScene.camera.projectionMatrix
        case .converging:
            return deferredScene.camera.projectionMatrix
        case .parallel:
            var matrix = deferredScene.camera.projectionMatrix
            matrix[2].x = (viewIndex == 0 ? -1 : 1) * 0.1 * settings.shiftX
            return matrix
        case .headtracked:
            // Transform the eye to portal coordinates.
            let portalFromImmersive = immersiveFromPortal.inverse
            let portalFromEye = portalFromImmersive * immersiveFromHead * headFromEye(viewIndex: viewIndex)
            let projection = asymmetricProjection(portalFromEye: portalFromEye)
            return projection
        }
    }

    var viewCount: Int {
        if settings.stereoscopy == .mono {
            return 1
        } else {
            return 2
        }
    }

    func renderTarget(for viewIndex: Int) -> RenderTarget {
        switch viewIndex {
        case 0:
            return leftEyeTarget
        case 1:
            return rightEyeTarget
        default:
            return monoTarget
        }
    }

    func rasterizationRateMap(viewIndex: Int) -> MTLRasterizationRateMap? {
        // Same rateMap for both eyes.
        return self.rateMap
    }

    func colorTexture(viewIndex: Int, for commandBuffer: any MTLCommandBuffer) -> (any MTLTexture)? {
        return renderTarget(for: viewIndex).colorTexture.replace(using: commandBuffer)
    }

    func depthStencilTexture(viewIndex: Int, for commandBuffer: any MTLCommandBuffer) -> (any MTLTexture)? {
        return renderTarget(for: viewIndex).depthStencilTexture
    }
}

class DeferredLightingSystem: System {
    required init(scene: RealityKit.Scene) {
    }
    
    static let simulations = EntityQuery(where: .has(DeferredLightingComponent.self))

    func update(context: SceneUpdateContext) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        commandBuffer.enqueue()

        defer {
            computeEncoder.endEncoding()
            commandBuffer.commit()
        }

        for entity in context.entities(matching: Self.simulations, updatingSystemWhen: .rendering) {
            (entity as? DeferredLightingEntity)?.update(commandBuffer: commandBuffer,
                                                        computeEncoder: computeEncoder)
        }
    }
}

struct DeferredLightingView: View {
    @Binding var settings: Settings
    @State var renderEntity: MetalVRREntity?
    @StateObject var headTracker = HeadPositionProvider()

    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    func updateSpaces() async {
        switch settings.stereoscopy {
        case .headtracked:
            if settings.headFromEye == nil {
                settings.openImmersiveSpace = .compositorServices
                switch await openImmersiveSpace(id: "CompositorServicesSpace") {
                case .opened: break
                default:
                    print("Failed to open CompositorServices Space to get the headFromEye transform")
                    settings.stereoscopy = .defaultValue
                }
            } else {
                if settings.openImmersiveSpace == .compositorServices {
                    await dismissImmersiveSpace()
                }
                if settings.openImmersiveSpace != .headTracker {
                    settings.openImmersiveSpace = .headTracker
                    await openImmersiveSpace(id: "ImmersiveSpace")
                }
            }
        default:
            if settings.openImmersiveSpace != .none {
                settings.openImmersiveSpace = .none
                await dismissImmersiveSpace()
            }
        }
    }

    @State var root3DFrame = Entity()
    @State var root = Entity()

    func applyViewportTransform() {
        root.scale = .init(repeating: settings.viewportScale)
        root.position.z = settings.viewportOffsetZ
    }

    var body: some View {
        ViewableAreaReader { area in
            RealityView { content in
                ResolutionProbeSystem.registerSystem()
                DeferredLightingSystem.registerSystem()

                content.add(root)

                // Starting the background loading of the 3D frame.
                async let frame = try! Entity(named: "Scene", in: assetsBundle)

                headTracker.start()
                headTracker.coordinateConverter = content

                let screenSize = min(area.widthInMeters, area.heightInMeters)

                let entity = DeferredLightingEntity()
                await entity.setup()
                renderEntity = entity
                entity.settings = settings
                entity.headPositionProvider = headTracker
                renderEntity!.position = .zero
                renderEntity!.scale = .init(repeating: screenSize)
                root.addChild(renderEntity!)

                // Setting up the frame.
                do {
                    let frame = await frame
                    let rectangle = frame.findEntity(named: "Rectangle")!
                    var bounds = rectangle.visualBounds(relativeTo: nil)
                    frame.scale *= 0.55 * screenSize / min(bounds.extents.x, bounds.extents.y)
                    bounds = rectangle.visualBounds(relativeTo: nil)
                    frame.position -= bounds.center
                    rectangle.isEnabled = false
                    root3DFrame.addChild(frame)
                    root.addChild(root3DFrame)

                    applyViewportTransform()
                }
            }.task {
                await updateSpaces()
            }
            .onChange(of: settings.stereoscopy) {
                Task {
                    await updateSpaces()
                }
            }
            .onChange(of: settings.hasDebugGrid) {
                renderEntity?.probeGrid?.isVisible = settings.hasDebugGrid
            }
            .onChange(of: settings.isWireframe) {
                renderEntity?.unwrappingMesh.mesh.parts[0].topology = settings.isWireframe ? .lineStrip : .triangle
            }
            .onChange(of: settings.hasRateFactors) {
                renderEntity?.rateMapIndicators?.isEnabled = settings.hasRateFactors
                renderEntity?.percentageIndicator?.isEnabled = settings.hasRateFactors
            }
            .onChange(of: settings.isSmoothed) {
                renderEntity?.smoothRateMap = settings.isSmoothed
            }
            .onChange(of: settings.showPhysical) {
                renderEntity?.unwrappingMesh.unwarp = !settings.showPhysical
                renderEntity?.unwrappingMesh.update(renderEntity!.rateMap)
            }
            .onChange(of: settings.show3DFrame, { oldValue, newValue in
                root3DFrame.isEnabled = newValue
            })
            .onChange(of: settings.viewportScale, { oldValue, newValue in
                applyViewportTransform()
            })
            .onChange(of: settings.viewportOffsetZ, { _, value in
                applyViewportTransform()
            })
            .onChange(of: settings.sceneScale) { _, newValue in
                (renderEntity as? DeferredLightingEntity)?.deferredScene.sceneScale = newValue
            }
            .onChange(of: settings.sceneTranslation) { _, newValue in
                (renderEntity as? DeferredLightingEntity)?.deferredScene.sceneTranslation = newValue
            }
            .ornament(attachmentAnchor: .scene(.topTrailingFront)) {
                if !settings.settingsVisible {
                    Button(action: {
                        openWindow(id: "Settings")
                    }, label: { Image(systemName: "gear") })
                    .glassBackgroundEffect()
                }
            }
        }
    }
}
