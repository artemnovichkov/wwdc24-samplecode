/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to be used for the background of the app's splash screen.
  The splash screen background is a RealityKit entity that updates a
  `LowLevelTexture` every frame and displays it using a `ShaderGraphMaterial`.
*/

import SwiftUI
import RealityKit

struct SplashScreenBackgroundView: View {
    @State var pixelsPerMeter: Int = 2048
    private let textureEntity = Entity()
    
    var body: some View {
        GeometryReader3D { proxy in
            RealityView { content in
                SplashScreenBackgroundSystem.registerSystem()
                
                let frame = proxy.frame(in: .local)
                let frameCenter = content.convert(frame.center, from: .local, to: .scene)
                let frameSize = abs(content.convert(frame.size, from: .local, to: .scene))
                
                let textureSize = SIMD2<Int>(SIMD2<Float>(frameSize.x, frameSize.y) * Float(pixelsPerMeter))
                
                guard let background = try? await SplashScreenBackgroundComponent(textureSize: textureSize) else {
                    return
                }
                
                textureEntity.position = SIMD3<Float>(0, 0, frameCenter.z - frameSize.z / 2)
                textureEntity.components.set(background)
                
                let backgroundMesh = MeshResource.generatePlane(width: frameSize.x, height: frameSize.y)
                textureEntity.components.set(ModelComponent(mesh: backgroundMesh, materials: [background.material]))
                content.add(textureEntity)
            } update: { content in
                let splashScreen = content.entities.filter { $0.components.has(SplashScreenBackgroundComponent.self) }
                
                let frameSize = abs(content.convert(proxy.frame(in: .local).size, from: .local, to: .scene))
                let textureSize = SIMD2<Int>(SIMD2<Float>(frameSize.x, frameSize.y) * Float(pixelsPerMeter))
                
                for entity in splashScreen {
                    var background = entity.components[SplashScreenBackgroundComponent.self]!
                    do { try background.setTextureSize(textureSize) } catch { continue }
                    
                    let backgroundMesh = MeshResource.generatePlane(width: frameSize.x, height: frameSize.y)
                    let modelComponent = ModelComponent(mesh: backgroundMesh, materials: [background.material])
                    
                    entity.components.set([modelComponent, background])
                }
            }
            .frame(depth: 0)
        }
        .frame(minHeight: 300)
    }
}
