/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show the custom integrated timeline player.
*/
import Foundation
import SwiftUI
import AVFAudio

struct IntegratedTimelinePlayerView: View {
    let playerState: PlayerState
    
    @State var isControlsHidden: Bool = false
    
    @Environment(\.dismiss) var dismiss
        
    fileprivate struct IgnoreSafeAreaModifier: ViewModifier {
        func body(content: Content) -> some View {
            // Show full-screen content.
            content.ignoresSafeArea(.all)
        }
    }
    
    @ViewBuilder
    private var dismissControl: some View {
        HStack {
            VStack(alignment: .leading) {
                // Dismiss view control.
                Button {
                    dismiss()
                    isControlsHidden = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(20)
                }
                
                Spacer()
            }

            Spacer()
        }
    }
    
    func validPlayerTime() -> Bool {
        // Ensure player time is valid before showing controls.
        return playerState.integratedTimelineCurrentTime >= 0 && playerState.integratedTimelineDuration > 0
    }
    
    var body: some View {

        VStack {
            ZStack {
                IntegratedTimelinePlayingView(playerState: playerState)
                    .modifier(IgnoreSafeAreaModifier())
                    .onAppear {
                        // Begin playback when view appears.
                        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                        playerState.play()
                    }
                    .onTapGesture {
                        // Show/hide player controls.
                        self.isControlsHidden = !self.isControlsHidden
                    }
                
                if !isControlsHidden {
                    // Show playback controls layer.
                    ZStack {
                        
                        Color.black.opacity(0.2)
                            .onTapGesture {
                                self.isControlsHidden = !self.isControlsHidden
                            }
                        
                        dismissControl
                        
                        if validPlayerTime() {
                            PlayerControlsView(playerState: playerState)
                        }
                    }
                    
                }
                
            }
        }

    }
}
