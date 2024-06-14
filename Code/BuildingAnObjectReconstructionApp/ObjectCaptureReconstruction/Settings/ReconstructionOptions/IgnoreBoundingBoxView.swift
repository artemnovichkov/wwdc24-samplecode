/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Option to ignore the iOS bounding box during reconstruction.
*/

import SwiftUI
import RealityKit

struct IgnoreBoundingBoxView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel

    var body: some View {
        @Bindable var appDataModel = appDataModel
        
        LabeledContent("Crop:") {
            Toggle("Ignore iOS bounding box", isOn: $appDataModel.sessionConfiguration.ignoreBoundingBox)
        }
        .disabled(!appDataModel.boundingBoxAvailable)
    }
}
