/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose the output texture maps to include in the output model.
*/

import SwiftUI
import RealityKit

struct TextureMapsView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    @State private var selectedTextureMap = PhotogrammetrySession.Configuration.CustomDetailSpecification().outputTextureMaps.rawValue

    var body: some View {
        Picker("Texture Maps:", selection: $selectedTextureMap) {
            Text("Diffuse Color")
                .tag(PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureMapOutputs.diffuseColor.rawValue)
            
            Text("Normal")
                .tag(PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureMapOutputs.normal.rawValue)
            
            Text("Roughness")
                .tag(PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureMapOutputs.roughness.rawValue)
            
            Text("Displacement")
                .tag(PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureMapOutputs.displacement.rawValue)
            
            Text("Ambient Occlusion")
                .tag(PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureMapOutputs.ambientOcclusion.rawValue)
            
            Text("All")
                .tag(PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureMapOutputs.all.rawValue)
        }
        .onChange(of: selectedTextureMap, initial: false) {
            let newValue = PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureMapOutputs(rawValue: selectedTextureMap)
            appDataModel.sessionConfiguration.customDetailSpecification.outputTextureMaps = newValue
            appDataModel.detailLevelOptionsUnderQualityMenu = .custom
        }
        .onAppear {
            selectedTextureMap = appDataModel.sessionConfiguration.customDetailSpecification.outputTextureMaps.rawValue
        }
    }
}
