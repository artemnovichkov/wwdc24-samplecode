/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose the model name for the created USDZ file.
*/

import SwiftUI

struct ModelNameField: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    @State private var modelName: String = ""

    var body: some View {
        LabeledContent("Model Name:") {
            TextField("", text: $modelName, prompt: Text("Name"))
                .textFieldStyle(.roundedBorder).padding(.leading, -9)
        }
        .onChange(of: modelName) {
            if !modelName.isEmpty {
                appDataModel.modelName = modelName
            } else {
                appDataModel.modelName = nil
            }
        }
        .onAppear {
            guard let appModelName = appDataModel.modelName else { return }
            modelName = appModelName
        }
    }
}
