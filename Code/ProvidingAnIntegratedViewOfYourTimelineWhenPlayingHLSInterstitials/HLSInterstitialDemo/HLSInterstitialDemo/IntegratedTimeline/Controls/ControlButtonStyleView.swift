/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The style for the playback control buttons.
*/
import SwiftUI

struct ControlButton: ButtonStyle {
    var fontSize: Double
    var frameSize: Double
    
    // The button style for integrated timeline playback control buttons.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize))
            .minimumScaleFactor(0.2)
            .scaledToFill()
            .foregroundColor(.white)
            .frame(width: frameSize, height: frameSize, alignment: .center)
    }
}
