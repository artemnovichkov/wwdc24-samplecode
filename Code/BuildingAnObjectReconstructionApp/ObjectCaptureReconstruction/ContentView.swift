/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top-level view.
*/

import SwiftUI

struct ContentView: View {
    @State private var appDataModel = AppDataModel()
    @State private var showErrorAlert = false

    var body: some View {
        VStack {
            switch appDataModel.state {
            case .ready:
                SettingsView()
                    .padding()
                
                Spacer()
                
            case .reconstructing, .viewing:
                ProcessingView()
 
            case .error:
                EmptyView()
            }
        }
        .environment(appDataModel)
        .navigationTitle("Create 3D Model")
        .onChange(of: appDataModel.state) {
            if appDataModel.state == .error {
                showErrorAlert = true
            }
        }
        .alert(appDataModel.alertMessage, isPresented: $showErrorAlert) {
            Button("OK") {
                appDataModel.state = .ready
            }
        }
    }
}
