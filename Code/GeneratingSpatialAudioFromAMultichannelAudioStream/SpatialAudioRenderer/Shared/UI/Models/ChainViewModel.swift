/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a chain of audio units.
*/
import SwiftUI

struct NodeModel: Identifiable {
    var id: Int = 0
    var name = String()
    var subTitle = String()
}

class ChainViewModel: ObservableObject {
    
    @Published var input = NodeModel()
    @Published var ausm = NodeModel()
    @Published var output = NodeModel()
    let engine = AudioEngine()

    init() {
        // The input node visual representation.
        input.name = "AudioFileReader"
        input.subTitle = "12 Channel PCM - 7.1.4"
        
        // The audio unit spatial mixer visual representation.
        ausm.name = "AUSMRenderer"
        ausm.subTitle = "IN: 12 Channel PCM - 7.1.4\nOUT: 2 Channel"
        
        // The output node visual representation.
        output.name = "OutputAU"
    }
    
}
