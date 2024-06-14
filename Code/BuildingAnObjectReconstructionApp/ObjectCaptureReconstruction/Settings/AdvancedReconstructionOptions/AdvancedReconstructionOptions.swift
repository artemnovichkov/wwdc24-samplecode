/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose customizable options on the reconstructed model and textures and process multiple detail levels.
*/

import SwiftUI
import RealityKit

struct AdvancedReconstructionOptions: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    @State private var processingMultipleDetailLevelEnabled = false
    @State private var isPreviewDetailLevelSelected = false
    @State private var isReducedDetailLevelSelected = false
    @State private var isMediumDetailLevelSelected = false
    @State private var isFullDetailLevelSelected = false
    @State private var isRawDetailLevelSelected = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Advanced Reconstruction Options")
            Divider()
            Form {
                PolygonCountView()
                
                TextureMapsView()
                
                TextureFormatView()
                
                TextureResolutionView()
                
                Divider()
                
                LabeledContent("Processing") {
                    Toggle("Process multiple detail levels", isOn: $processingMultipleDetailLevelEnabled)
                }
                
                Menu("Choose detail levels") {
                    Toggle("Preview", isOn: $isPreviewDetailLevelSelected)
                    
                    Toggle("Reduced", isOn: $isReducedDetailLevelSelected)
                    
                    Toggle("Medium", isOn: $isMediumDetailLevelSelected)
                    
                    Toggle("Full", isOn: $isFullDetailLevelSelected)
                    
                    Toggle("Raw", isOn: $isRawDetailLevelSelected)
                        
                }
                .disabled(!processingMultipleDetailLevelEnabled)
                .onChange(of: processingMultipleDetailLevelEnabled) {
                    appDataModel.detailLevelOptionsUnderAdvancedMenu.removeAll()
                }
                .onChange(of: isPreviewDetailLevelSelected) {
                    if isPreviewDetailLevelSelected {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.insert(.preview)
                    } else {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.remove(.preview)
                    }
                }
                .onChange(of: isReducedDetailLevelSelected) {
                    if isReducedDetailLevelSelected {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.insert(.reduced)
                    } else {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.remove(.reduced)
                    }
                }
                .onChange(of: isMediumDetailLevelSelected) {
                    if isMediumDetailLevelSelected {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.insert(.medium)
                    } else {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.remove(.medium)
                    }
                }
                .onChange(of: isFullDetailLevelSelected) {
                    if isFullDetailLevelSelected {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.insert(.full)
                    } else {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.remove(.full)
                    }
                }
                .onChange(of: isRawDetailLevelSelected) {
                    if isRawDetailLevelSelected {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.insert(.raw)
                    } else {
                        appDataModel.detailLevelOptionsUnderAdvancedMenu.remove(.raw)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            if !appDataModel.detailLevelOptionsUnderAdvancedMenu.isEmpty {
                processingMultipleDetailLevelEnabled = true
                if appDataModel.detailLevelOptionsUnderAdvancedMenu.contains(.preview) { isPreviewDetailLevelSelected = true }
                if appDataModel.detailLevelOptionsUnderAdvancedMenu.contains(.reduced) { isReducedDetailLevelSelected = true }
                if appDataModel.detailLevelOptionsUnderAdvancedMenu.contains(.medium) { isMediumDetailLevelSelected = true }
                if appDataModel.detailLevelOptionsUnderAdvancedMenu.contains(.full) { isFullDetailLevelSelected = true }
                if appDataModel.detailLevelOptionsUnderAdvancedMenu.contains(.raw) { isRawDetailLevelSelected = true }
            }
        }
    }
}
