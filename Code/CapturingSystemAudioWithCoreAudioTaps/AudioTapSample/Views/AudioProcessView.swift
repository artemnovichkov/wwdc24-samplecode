/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that provides UI for interacting with the audio process model.
*/

import SwiftUI

struct AudioProcessView: View {
    @ObservedObject var process: AudioProcess
    
    var body: some View {
        VStack {
            Text("Audio Process Details:")
                .font(.headline)
            Text("Object ID: \(process.id)")
            Text("PID: " + String(process.pid))
            Text("Name: " + process.name)
            Text("Bundle ID: " + process.bundleID)
            Text("Running: " + String(process.isRunning))
        }
    }
}

#Preview {
    AudioProcessView(process: AudioProcess(id: 1))
}
