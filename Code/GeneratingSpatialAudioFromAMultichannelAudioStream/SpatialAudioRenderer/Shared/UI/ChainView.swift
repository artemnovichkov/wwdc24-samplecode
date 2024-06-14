/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that represents a chain of audio units.
*/
import SwiftUI

struct ChainView: View {
    
    @EnvironmentObject var model: ChainViewModel
    @State private var selection = 0

    var body: some View {
        HStack(alignment: .center) {
            
            // The visual representation of an input node.
            VStack(alignment: .center, spacing: 10.0) {
                Text(model.input.name)
                Text(model.input.subTitle)
                    .padding(5)
                    .font(.system(size: 8))
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.blue))
                    .frame(maxWidth: .infinity)
                Spacer()
                    .frame(height: 50)
                
                Text("Select an Audio Sample")
                Picker("", selection: $selection) {
                    ForEach(0 ..< AudioEngine.audioSamples().count, id: \.self) { index in
                        let name = AudioEngine.audioSamples()[index]
                        Text(URL(filePath: name).lastPathComponent)
                    }
                }
                .onChange(of: selection) { _ in
                    let name = AudioEngine.audioSamples()[selection]
                    model.engine.loadAudio(name)
                }

            }
            .frame(maxWidth: 150, minHeight: 200, maxHeight: .infinity)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black).opacity(0.75))
                
            // The visual representation of an input node with an audio channel arrow.
            VStack {
                ForEach(0..<12) { _ in
                    Arrow()
                        .fill(Color.blue)
                        .frame(width: 25)
                }
            }
            
            // The visual representation of an audio unit spatial mixer node.
            VStack(alignment: .center, spacing: 10.0) {
                Text(model.ausm.name)
                Text(model.ausm.subTitle)
                    .padding(5.0)
                    .font(.system(size: 8.0))
                    .background(RoundedRectangle(cornerRadius: 5.0).fill(Color.blue))
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: 150, minHeight: 200, maxHeight: .infinity)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color.black)
            .opacity(0.75))

            // The visual representation of a mixer node with an audio channel arrow.
            VStack {
                ForEach(0..<2) { _ in
                    Arrow()
                        .fill(Color.blue)
                        .frame(width: 35)
                }
            }
            
            // The visual representation of the output node.
            VStack(alignment: .center, spacing: 10.0) {
                Text(model.output.name)
                Text(model.output.subTitle)
                    .font(.system(size: 8))
                    .background(RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue))
                    .padding(5.0)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: 150, minHeight: 200, maxHeight: .infinity)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black).opacity(0.75))
            
        }
    }
    
}
