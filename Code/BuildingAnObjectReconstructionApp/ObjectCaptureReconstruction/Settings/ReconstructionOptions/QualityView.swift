/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose the level of detail for the created model.
*/

import SwiftUI
import RealityKit

struct QualityView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    @State private var showAdvancedOptions = false

    var body: some View {
        @Bindable var appDataModel = appDataModel
        
        HStack {
            Picker("Quality:", selection: $appDataModel.detailLevelOptionsUnderQualityMenu) {
                Text("Preview")
                    .tag(RealityFoundation.PhotogrammetrySession.Request.Detail.preview)
                
                Text("Reduced")
                    .tag(RealityFoundation.PhotogrammetrySession.Request.Detail.reduced)
                
                Text("Medium")
                    .tag(RealityFoundation.PhotogrammetrySession.Request.Detail.medium)
                
                Text("Full")
                    .tag(RealityFoundation.PhotogrammetrySession.Request.Detail.full)
                
                Text("Raw")
                    .tag(RealityFoundation.PhotogrammetrySession.Request.Detail.raw)
                
                Text("Custom")
                    .tag(RealityFoundation.PhotogrammetrySession.Request.Detail.custom)
            }
            .pickerStyle(.menu)
            
            Button {
                showAdvancedOptions = true
            } label: {
                Text("Advanced...")
            }
        }
        .popover(isPresented: $showAdvancedOptions) {
            AdvancedReconstructionOptions()
        }
        .onChange(of: appDataModel.detailLevelOptionsUnderQualityMenu) {
            if appDataModel.detailLevelOptionsUnderQualityMenu != .custom {
                appDataModel.sessionConfiguration.customDetailSpecification = PhotogrammetrySession.Configuration.CustomDetailSpecification()
            }
        }
    }
}
