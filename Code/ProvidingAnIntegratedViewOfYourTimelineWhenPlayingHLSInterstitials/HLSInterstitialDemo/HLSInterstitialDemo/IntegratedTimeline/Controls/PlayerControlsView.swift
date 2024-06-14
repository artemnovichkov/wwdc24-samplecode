/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show the playback controls and transport control bar.
*/
import Foundation
import SwiftUI
import AVFoundation

struct PlayerControlsView: View {
    let playerState: PlayerState

    var body: some View {
        GeometryReader { proxy in
            let viewWidth = proxy.size.width
            let viewHeight = proxy.size.height
            
            ZStack {
                // Show playback controls.
                PlaybackControlsView(playerState: playerState)
                
                VStack {
                    Spacer()
                }
                .safeAreaInset(edge: .bottom) {
                    VStack {
                        // Show transport bar with point and fill segments.
                        TransportBarView(playerState: playerState,
                                        currentTime: playerState.integratedTimelineCurrentTime,
                                        startTime: playerState.integratedTimelineStartTime,
                                        duration: playerState.integratedTimelineDuration,
                                        pointSegments: playerState.integratedTimelinePointSegments,
                                        fillSegments: playerState.integratedTimelineFillSegments,
                                        isPlayingLiveStream: playerState.isPlayingLiveStream)
                            .frame(width: viewWidth, height: 10)
                            .padding([.bottom], viewHeight * 0.07)
                    }
                    
                }
            }

        }
    }
}
