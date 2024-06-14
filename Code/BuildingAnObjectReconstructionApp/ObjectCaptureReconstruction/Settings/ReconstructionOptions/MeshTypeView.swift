/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Select the mesh type of the created model.
*/

import SwiftUI
import RealityKit

struct MeshTypeView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel

    var body: some View {
        @Bindable var appDataModel = appDataModel
        
        Picker("Mesh Type:", selection: $appDataModel.sessionConfiguration.meshPrimitive) {
            Text("Triangular Mesh")
                .tag(PhotogrammetrySession.Configuration.MeshPrimitive.triangle)
            
            Text("Quad Mesh")
                .tag(PhotogrammetrySession.Configuration.MeshPrimitive.quad)
        }
        .pickerStyle(.menu)
    }
}
