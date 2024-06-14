/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that provides UI for interacting with the audio IO functions in the main model.
*/

import SwiftUI

struct AudioIOView: View {
    @EnvironmentObject private var model: Model
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text("Record input to file")
                    .font(.headline)
                Button(action: model.startRecording) {
                    Text("Start Recording")
                }
                .disabled(model.recordingActive)
                Button(action: model.stopRecording) {
                    Text("Stop Recording")
                }
                .disabled(!model.recordingActive)
                Button(action: model.openDirectory) {
                    Text("Show Files")
                }
            }
            Divider()
            VStack {
                Text("Loopback Input to Output")
                    .font(.headline)
                if model.loopbackActive {
                    Button(action: model.stopLoopback) {
                        Text("Stop Loopback")
                    }
                } else {
                    Button(action: model.startLoopback) {
                        Text("Start Loopback")
                    }
                }
            }
            Spacer()
        }
    }
}

#Preview {
    AudioIOView()
        .environmentObject(Model())
}
