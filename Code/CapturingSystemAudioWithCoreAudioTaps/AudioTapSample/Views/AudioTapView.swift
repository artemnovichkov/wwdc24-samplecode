/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that provides UI for interacting with the audio tap model.
*/

import SwiftUI

struct AudioTapView: View {
    @EnvironmentObject private var model: Model
    @ObservedObject var tap: AudioTap
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text("Tap Details:")
                .font(.headline)
            Text("Name: \(tap.config.name)")
            Text("Object ID: \(tap.id)")
            Text("UID: \(tap.uid)")
            Text("Format: \(tap.format)")
            TapConfigView(config: $tap.config)
        }
        .onChange(of: tap.config) {
            tap.setTapDescription()
        }
    }
}

#Preview {
    AudioTapView(tap: AudioTap(id: 1))
        .environmentObject(Model())
}
