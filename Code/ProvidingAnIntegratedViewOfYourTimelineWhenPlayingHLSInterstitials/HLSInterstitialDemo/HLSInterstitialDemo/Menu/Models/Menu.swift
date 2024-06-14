/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data structures to represent values from the JSON menu.
*/
import Foundation
import AVFoundation

typealias DataModel = (Codable & Equatable & Sendable)

struct Menu: DataModel {
    let sections: [MenuSection]
}

struct MenuSection: DataModel, Identifiable {
    // Information for creating a section from the JSON menu.
    let id: UUID
    let title: String
    let items: [MenuItem]
}

struct MenuItem: DataModel, Identifiable {
    // Information for creating an item from the JSON menu.
    let id: UUID
    let title: String
    let description: String
    let url: URL
    let playbackBehaviors: PlaybackBehaviors?
    let interstitialEvents: [InterstitialEvent]?
}

struct PlaybackBehaviors: DataModel, OptionSet {
    // Settings for playback behavior.
    let rawValue: Int

    static let insertPeriodicInterstitial = Self(rawValue: 1 << 0) // Periodically insert specified ad.
}

struct InterstitialEvent: DataModel {
    // Information for creating an interstitial event from the JSON menu.
    let urls: [URL]
    let startTime: TimeInterval?
    let plannedDuration: TimeInterval?
    let playoutLimit: TimeInterval?
    let resumptionOffset: TimeInterval?
    @CueType
    var cue: AVPlayerInterstitialEvent.Cue?
    let willPlayOnce: Bool?
    @OccupancyType
    var timelineOccupancy: AVPlayerInterstitialEvent.TimelineOccupancy?
    let supplementsPrimary: Bool?
    let contentMayVary: Bool?
}

// MARK: - Type Extensions

@propertyWrapper
struct CueType {
    var wrappedValue: AVPlayerInterstitialEvent.Cue?
}

extension CueType: DataModel {
    // Make the cue type codable between the integer and AVPlayerInterstitialEvent.Cue type.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let intValue = try container.decode(Int.self)
        var cueValue: AVPlayerInterstitialEvent.Cue
        
        switch intValue {
        case 0:
            cueValue = .noCue
        case 1:
            cueValue = .joinCue
        case 2:
            cueValue = .leaveCue
        default:
            cueValue = .noCue
        }

        self.init(wrappedValue: cueValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var intValue: Int
        switch wrappedValue {
        case .noCue:
            intValue = 0
        case .joinCue:
            intValue = 1
        case .leaveCue:
            intValue = 2
        default:
            intValue = 0
        }
        
        try container.encode(intValue)
    }
}

@propertyWrapper
struct OccupancyType {
    var wrappedValue: AVPlayerInterstitialEvent.TimelineOccupancy?
}

extension OccupancyType: DataModel {
    // Make the occupancy type codable between the integer and AVPlayerInterstitialEvent.TimelineOccupancy type.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let intValue = try container.decode(Int.self)

        self.init(wrappedValue: (intValue == 0) ? .singlePoint : .fill)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode((wrappedValue == .singlePoint) ? 0 : 1)
    }
}
