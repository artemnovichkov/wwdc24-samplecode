/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Navigate to the model folder in Finder.
*/

import SwiftUI

struct TopBarView: View {
    let processedRequestsDetailLevel: [String]

    @Environment(AppDataModel.self) private var appDataModel: AppDataModel

    var body: some View {
        if appDataModel.state == .viewing {
            VStack(alignment: .leading) {
                Text("\(detailLevels)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                HStack {
                    Image(nsImage: NSWorkspace.shared.icon(for: .folder))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)
                    
                    Text("\(appDataModel.modelFolder!.lastPathComponent)")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Button("Open in Finder") {
                        DispatchQueue.global().async {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: appDataModel.modelFolder!.path)
                        }
                    }
                }
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 8)
        }
    }

    private var detailLevels: String {
        var message = ""
        for (index, detailLevel) in processedRequestsDetailLevel.enumerated() {
            message.append(detailLevel.capitalized)
            if index == processedRequestsDetailLevel.count - 1 {
                processedRequestsDetailLevel.count > 1 ?  message.append(" models ") :  message.append(" model ")
            } else {
                message.append(", ")
            }
        }
        message.append("saved to:")
        return message
    }
}
