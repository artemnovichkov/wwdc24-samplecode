/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The playback coordinator delegate for coordinating SharePlay using the menu item coordination identifier.
*/
import AVFoundation
import Foundation

class PlayerCoordinatorDelegate: NSObject, AVPlayerPlaybackCoordinatorDelegate {
    private let menuItem: MenuItem
    
    init (menuItem: MenuItem) {
        self.menuItem = menuItem
    }
    
    // MARK: - Private
    
    private lazy var coordinationIdentifier: String = menuItem.id.uuidString
    
    // MARK: - AVPlayerPlaybackCoordinatorDelegate
    
    func playbackCoordinator(_ coordinator: AVPlayerPlaybackCoordinator, identifierFor playerItem: AVPlayerItem) -> String {
        coordinationIdentifier
    }
}
