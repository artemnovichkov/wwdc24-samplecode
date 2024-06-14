/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show the transport control bar.
*/
import Foundation
import SwiftUI
import AVFoundation

struct TransportBarView: View {
    let playerState: PlayerState
    
    let currentTime: Double
    let startTime: Double
    let duration: Double
    
    let pointSegments: [AVPlayerItemSegment]
    let fillSegments: [AVPlayerItemSegment]
    
    let isPlayingLiveStream: Bool
        
    @State var isSeeking: Bool = false
    @State var seekBarPos: Double = 0
    
    // MARK: - Helper functions
    
    func timeSecondsToTimelinePosition(seconds: Double, timeOffset: Double, width timelineWidth: Double) -> Double {
        // Convert from seconds to x-coordinate on timeline.
        let timelinePosition = (seconds + timeOffset) * timelineWidth / duration
        
        // Set the value to be between 0 and the width.
        return min(max(timelinePosition, 0), timelineWidth)
    }

    func timelinePositionToTimeSeconds(position: Double, timeOffset: Double, width timelineWidth: Double) -> Double {
        // Convert from x-coordinate on timeline to seconds.
        return (position * duration / timelineWidth) + timeOffset
    }
    
    func secondsToHoursMinutesSeconds(_ seconds: Int) -> String {
        // Convert the integer seconds value to a string timestamp in "HH:mm:ss" format.
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = (seconds % 3600) % 60
        
        // Show time in string format.
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
    
    // MARK: - View
    
    var body: some View {
        GeometryReader { proxy in
            let viewWidth = proxy.size.width * 0.96
            let viewHeight = proxy.size.height * 0.98
        
            let timelineHeight = 8.0
            let timelineWidth = viewWidth * 0.84
            
            let radius = viewHeight * 0.5
            
            HStack {
                // Current time
                VStack {
                    // Show live text.
                    if isPlayingLiveStream {
                        Text("LIVE")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(RoundedRectangle(cornerRadius: radius).fill(Color.red))
                    } else {
                        // Get time from current time if VOD; get time based on local time if live.
                        Text(secondsToHoursMinutesSeconds(Int(currentTime.isFinite ? ceil(currentTime) : 0)))
                    }
                    
                }
                .font(.caption)
                .minimumScaleFactor(0.5)
                .scaledToFill()
                .foregroundColor(.gray)
                .frame(width: viewWidth * 0.08, alignment: .center)
                
                ZStack(alignment: .leading) {
                    // Background bar
                    Rectangle()
                        .foregroundColor(.gray)
                        .offset(x: 0)
                        .frame(width: timelineWidth, height: timelineHeight)
                        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    
                    // Fill bar
                    ZStack(alignment: .leading) {
                        // Show time progress of asset.
                        HStack {
                            // Show white bar representing progress of asset.
                            Rectangle()
                                .foregroundColor(.white)
                                .offset(x: 0)
                                .frame(
                                    width: isSeeking ?
                                            seekBarPos :
                                            timeSecondsToTimelinePosition(seconds: currentTime,
                                                                          timeOffset: -startTime,
                                                                          width: timelineWidth),
                                    height: timelineHeight
                                )
                            // UI to show flat playhead.
                            if (isPlayingLiveStream ? currentTime - startTime : currentTime) + 1 < duration {
                                Spacer()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    }
                    
                    // Show point or fill occupancy interstitials.
                    
                    // Point occupancy interstitials
                    ForEach(Array(zip(pointSegments.indices, pointSegments)), id: \.0) { index, point in
                        let pointStartTime = CMTimeGetSeconds(point.timeMapping.target.start)
                        
                        // Show yellow circle representing point occupancy interstitial.
                        PointOccupancyView(diameter: timelineHeight * 0.7,
                                           pointXPos: timeSecondsToTimelinePosition(seconds: pointStartTime,
                                                                                    timeOffset: -startTime,
                                                                                    width: timelineWidth))
                    }
                    
                    // Fill occupancy interstitials
                    ForEach(Array(zip(fillSegments.indices, fillSegments)), id: \.0) { index, fill in
                        let fillStartTime = CMTimeGetSeconds(fill.timeMapping.target.start)
                        let fillDuration = CMTimeGetSeconds(fill.timeMapping.target.duration)
                        let fillSupplementsPrimary = fill.interstitialEvent?.supplementsPrimaryContent ?? false
                        
                        // Show filled-in bar representing fill occupancy interstitial.
                        FillOccupancyView(height: timelineHeight,
                                          fillWidth: timeSecondsToTimelinePosition(seconds: fillDuration,
                                                                                   timeOffset: 0,
                                                                                   width: timelineWidth),
                                          fillXStart: timeSecondsToTimelinePosition(seconds: fillStartTime,
                                                                                    timeOffset: -startTime,
                                                                                    width: timelineWidth),
                                          asPrimary: fillSupplementsPrimary)
                    }
                    
                    ZStack(alignment: .leading) {
                        // Slider for scrubbing on the progress bar.
                        Slider(
                            value: isSeeking ? $seekBarPos : .constant(timeSecondsToTimelinePosition(seconds: currentTime,
                                                                                                     timeOffset: -startTime,
                                                                                                     width: timelineWidth)),
                            in: 0...timelineWidth,
                            step: 1,
                            onEditingChanged: { isEditing in
                                if isEditing {
                                    isSeeking = true
                                }
                                if !isEditing {
                                    playerState.seekOnIntegratedTimeline(to: timelinePositionToTimeSeconds(position: seekBarPos,
                                                                                                           timeOffset: startTime,
                                                                                                           width: timelineWidth)) {
                                        _ -> Void in
                                            isSeeking = false
                                    }
                                }
                            }
                        )
                        .offset(x: 0)
                        .accentColor(Color.white.opacity(0))
                    }
                }
                .frame(width: timelineWidth, alignment: .center)
                
                if isPlayingLiveStream {
                    // Live indicator
                    Image(systemName: "record.circle")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.red)
                        .frame(width: viewWidth * 0.06, alignment: .leading)
                } else {
                    // Remaining time
                    Text("-\(secondsToHoursMinutesSeconds(Int(duration) - Int(currentTime.isFinite ? currentTime : 0)))")
                        .font(.caption)
                        .minimumScaleFactor(0.5)
                        .scaledToFill()
                        .foregroundColor(.gray)
                        .frame(width: viewWidth * 0.08, alignment: .center)
                }
            }
        }
    }
}

