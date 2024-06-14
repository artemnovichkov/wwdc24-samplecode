/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Set the upper limit on polygons in the model mesh.
*/

import SwiftUI
import RealityKit

struct PolygonCountView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel

    var body: some View {
        @Bindable var appDataModel = appDataModel
        LabeledContent("Max Polygon Count:") {
            TextField("", value: $appDataModel.sessionConfiguration.customDetailSpecification.maximumPolygonCount, formatter: NumberFormatter())
                .textFieldStyle(.roundedBorder)
        }
        .onChange(of: appDataModel.sessionConfiguration.customDetailSpecification.maximumPolygonCount, initial: false) {
            appDataModel.detailLevelOptionsUnderQualityMenu = .custom
        }
    }
}
