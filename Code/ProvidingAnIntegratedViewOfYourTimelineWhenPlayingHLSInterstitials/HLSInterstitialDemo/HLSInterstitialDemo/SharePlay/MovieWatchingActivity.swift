/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The group activity to share in SharePlay.
*/
import Foundation
import GroupActivities

// A type that represents a video to watch with others.
struct VideoMetadata: Hashable, Codable, Sendable {
    var menuItemIdentifier: UUID
    var referenceDate: Date
}

// A group activity to watch a video together.
struct VideoWatchingActivity: GroupActivity {

    // The movie to watch.
    let videoMetadata: VideoMetadata

    // Metadata that the system displays to participants.
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .watchTogether
        metadata.title = "SharePlay Interstitials"
        return metadata
    }
}
