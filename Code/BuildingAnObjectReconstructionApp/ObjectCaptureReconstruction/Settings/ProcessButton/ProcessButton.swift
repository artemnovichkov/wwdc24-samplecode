/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provide a button to start the reconstruction.
*/

import SwiftUI

struct ProcessButton: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel

    var body: some View {
        HStack {
            Spacer()
            Button("Process") {
                Task {
                    await appDataModel.startReconstruction()
                }
            }
        }
        .padding(.top, 3)
    }
}
