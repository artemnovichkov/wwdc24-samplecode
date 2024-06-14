/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose the image folder, model folder, and the model name.
*/

import SwiftUI
import RealityKit

struct FolderOptionsView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel

    var body: some View {
        Section {
            ImageFolderView()
            
            ModelNameField()
            
            ModelFolderView()
        }
    }
}
