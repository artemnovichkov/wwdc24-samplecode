/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose the folder for storing the created models.
*/

import SwiftUI

struct ModelFolderView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    @State private var showFileImporter = false

    var body: some View {
        LabeledContent("Where:") {
            Button {
                showFileImporter.toggle()
            } label: {
                HStack {
                    if let selectedFolder = appDataModel.modelFolder {
                        HStack {
                            Image(nsImage: NSWorkspace.shared.icon(for: .folder))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            
                            Text("\(selectedFolder.lastPathComponent)")
                        }
                    } else {
                        Text("Choose...")
                    }
                    Spacer()
                }
            }
            .fileImporter(isPresented: $showFileImporter,
                          allowedContentTypes: [.folder]) { result in
                switch result {
                case .success(let directory):
                    let gotAccess = directory.startAccessingSecurityScopedResource()
                    if !gotAccess { return }
                    appDataModel.modelFolder = directory
                case .failure(let error):
                    appDataModel.alertMessage = "\(error)"
                    appDataModel.state = .error
                }
            }
        }
    }
}
