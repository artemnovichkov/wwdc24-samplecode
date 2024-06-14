/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to display a preview of a brush preset, and a view to display a collection of these presets.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct PresetBrushView: View {
    /// The current state of the brush.
    @Binding var brushState: BrushState
    
    /// Settings of a given preset.
    let preset: BrushPreset

    /// Function to represent deleting a preset.
    let deleteAction: () -> Void
    
    /// Whether the delete button is visible.
    @State var isDeletePopoverPresented: Bool = false
    
    /// The brush entity.
    private let entity = Entity()
    
    var body: some View {
        RealityView { content in
            SolidBrushSystem.registerSystem()
          
            entity.name = "Brush Preset"
            entity.position.z += 0.005
            content.add(entity)
            
            let simulatedBounds: Float = 0.1
            let displayBounds: Float = 0.025
            let selectionShape = ShapeResource.generateBox(size: SIMD3<Float>(repeating: simulatedBounds))
            
            let shaderInputs = HoverEffectComponent.ShaderHoverEffectInputs.default
            let hoverEffect = HoverEffectComponent.HoverEffect.shader(shaderInputs)
            let hoverEffectComponent = HoverEffectComponent(hoverEffect)
            
            let inputTargetComponent = InputTargetComponent()
            let collisionComponent = CollisionComponent(shapes: [selectionShape], isStatic: true)

            entity.components.set([hoverEffectComponent, inputTargetComponent, collisionComponent])
            
            let presetBrushState = BrushState(preset: preset)
            
            let solidMaterial = try? await ShaderGraphMaterial(named: "/Root/SolidPresetBrushMaterial",
                                                               from: "PresetBrushMaterial",
                                                               in: realityKitContentBundle)
            
            var sparkleMaterial = try? await ShaderGraphMaterial(named: "/Root/SparklePresetBrushMaterial",
                                                                 from: "PresetBrushMaterial",
                                                                 in: realityKitContentBundle)
            sparkleMaterial?.writesDepth = false
            try? sparkleMaterial?.setParameter(name: "ParticleUVScale", value: .float(8))
            
            var source = await DrawingSource(rootEntity: entity, solidMaterial: solidMaterial, sparkleMaterial: sparkleMaterial)
            
            let samples = PresetBrushStroke.samples
            for (index, sample) in samples.enumerated() {
                let brushTip = sample * simulatedBounds
                
                let sampleFraction = powf(Float(index) / Float(samples.count), 1.3)
                let speed = mix(0.5, 1.5, t: sampleFraction)
                
                source.receiveSynthetic(position: brushTip,
                                        speed: speed,
                                        state: presetBrushState)
            }
            
            // As generated the stroke fills a 1 x 1 x 1 meter box. Scale down the entity to fit.
            entity.scale = SIMD3<Float>(repeating: displayBounds / simulatedBounds)
        }
            .frame(depth: 0)
            .simultaneousGesture(
                LongPressGesture()
                    .targetedToAnyEntity()
                    .onEnded { _ in isDeletePopoverPresented = true }
            )
            .highPriorityGesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { _ in brushState.apply(preset: preset) }
            )
            .popover(isPresented: $isDeletePopoverPresented) {
                VStack(spacing: 10) {
                    Button {
                        brushState.apply(preset: preset)
                        isDeletePopoverPresented = false
                    } label: {
                        Text("Apply")
                    }
                    
                    Button(role: .destructive) {
                        deleteAction()
                        isDeletePopoverPresented = false
                    } label: {
                        Text("Delete")
                    }
                }
                .padding(10)
            }
    }
}

struct PresetBrushSelectorView: View {
    private static let defaultPresets: [BrushPreset] = [
        .solid(settings: .init(thicknessType: .calligraphic())),
        .solid(settings: .init(thicknessType: .uniform)),
        .sparkle(settings: .init())
    ]
    
    /// Represents a distinct entry in the brush preset list.
    ///
    /// It wraps `BrushPreset` as an `Identifiable` structure so that different entries are recognized as distinct,
    /// even if the presets contained within are the same.
    private struct BrushPresetEntry: Identifiable {
        let id: UUID = UUID()
        var preset: BrushPreset
    }
    
    @Binding var brushState: BrushState
    
    @State private var presets: [BrushPresetEntry] = defaultPresets.map { BrushPresetEntry(preset: $0) }

    var body: some View {
        VStack {
            Text("Presets").font(.title3)
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach($presets) { presetEntry in
                        ZStack {
                            Circle()
                                .fill(BackgroundStyle.background)
                                .frame(width: 75, height: 75)
                            
                            PresetBrushView(brushState: $brushState,
                                            preset: presetEntry.preset.wrappedValue,
                                            deleteAction: {
                                withAnimation {
                                    presets.removeAll(where: { $0.id == presetEntry.id })
                                }
                            })
                        }
                        .frame(width: 75, height: 75)
                    }
                    
                    Button {
                        withAnimation {
                            presets.append(BrushPresetEntry(preset: brushState.asPreset))
                        }
                    } label: {
                        Image(systemName: "plus").padding()
                    }
                    .frame(width: 75, height: 75)
                        .buttonStyle(.plain)
                        .background(.background, in: Circle())
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity).frame(height: 75).defaultScrollAnchor(.center)
        }
    }
}
