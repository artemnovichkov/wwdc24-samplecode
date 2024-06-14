/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom integrated timeline player.
*/
import Foundation
import SwiftUI
import AVFoundation

struct IntegratedTimelinePlayingView: UIViewRepresentable {
    let playerState: PlayerState
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<IntegratedTimelinePlayingView>) {
        // No action to take.
    }
    func makeUIView(context: Context) -> UIView {
        return IntegratedTimelinePlayingUIView(frame: .zero, playerState: playerState)
    }
}

class IntegratedTimelinePlayingUIView: UIView {
    let playerState: PlayerState
    private let playerLayer = AVPlayerLayer()
    
    // MARK: - Life cycle

    init(frame: CGRect, playerState: PlayerState) {
        self.playerState = playerState
        
        super.init(frame: frame)
    
        // Set player layer.
        playerLayer.player = self.playerState.player
        layer.addSublayer(playerLayer)
        layer.backgroundColor = UIColor.black.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
