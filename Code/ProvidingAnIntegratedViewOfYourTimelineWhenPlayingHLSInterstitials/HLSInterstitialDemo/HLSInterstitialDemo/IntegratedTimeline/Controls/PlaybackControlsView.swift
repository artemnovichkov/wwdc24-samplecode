/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show the playback control buttons overlay.
*/
import Foundation
import SwiftUI
import AVFoundation

struct PlaybackControlsView: View {
    let playerState: PlayerState
        
    var body: some View {
        GeometryReader { proxy in
            let viewWidth = proxy.size.width * 0.9
    
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    // Seek backwards by 10s on the integrated timeline.
                    Button {
                        playerState.seekOnIntegratedTimeline(by: -10.0, completion: { _ in })
                    } label: {
                        Image(systemName: "gobackward.10")
                    }
                    .buttonStyle(ControlButton(fontSize: 40, frameSize: viewWidth * 0.2))
                    
                    // Play or pause the player.
                    if playerState.playerRate > 0 {
                        // Pause
                        Button {
                            playerState.setRate(rate: 0.0)
                        } label: {
                            Image(systemName: "pause.fill")
                        }
                        .buttonStyle(ControlButton(fontSize: 60, frameSize: viewWidth * 0.2))
                    } else {
                        // Play
                        Button {
                            playerState.play()
                        } label: {
                            Image(systemName: "play.fill")
                        }
                        .buttonStyle(ControlButton(fontSize: 60, frameSize: viewWidth * 0.2))
                    }
                    
                    // Seek forwards by 10s on the integrated timeline.
                    Button {
                        playerState.seekOnIntegratedTimeline(by: 10.0, completion: { _ in })
                    } label: {
                        Image(systemName: "goforward.10")
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ControlButton(fontSize: 40, frameSize: viewWidth * 0.2))
                    
                    Spacer()
                }
                Spacer()
            }
        }
    }
            
}
