/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose the output format to use for all textures.
*/

import SwiftUI
import RealityKit

struct TextureFormatView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel

    var body: some View {
        @Bindable var appDataModel = appDataModel
        
        Picker("Texture Format:", selection: $appDataModel.sessionConfiguration.customDetailSpecification.textureFormat) {
            Text("PNG")
                .tag(PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureFormat.png)
            
            Text("JPEG")
                .tag(PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureFormat.jpeg(compressionQuality: 0.8))
        }
        .onChange(of: appDataModel.sessionConfiguration.customDetailSpecification.textureFormat) {
            appDataModel.detailLevelOptionsUnderQualityMenu = .custom
        }
    }
}
