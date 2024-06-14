/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Emoji representing how someone feels that you can use to derive an `HKStateOfMind`.
*/

import Foundation
import HealthKit
import SwiftUI
import Charts

/// Represents an option to log an emotion associated with a particular emoji.
enum EmojiType: CaseIterable, Identifiable {
    var id: Self { self }
    
    case angry
    case sad
    case indifferent
    case satisfied
    case happy
    
    var emoji: String {
        switch self {
        case .angry: return "😡"
        case .sad: return "😢"
        case .indifferent: return "😐"
        case .satisfied: return "😌"
        case .happy: return "😊"
        }
    }
    
    var valence: Double {
        switch self {
        case .angry: return -1
        case .sad: return -0.5
        case .indifferent: return 0.0
        case .satisfied: return 0.5
        case .happy: return 1
        }
    }
    
    var label: HKStateOfMind.Label {
        switch self {
        case .angry: return .angry
        case .sad: return .sad
        case .indifferent: return .indifferent
        case .satisfied: return .satisfied
        case .happy: return .happy
        }
    }
    
    var color: Color {
        switch self {
        case .angry: Color.red
        case .sad: Color.indigo
        case .indifferent: Color.teal
        case .satisfied: Color.green
        case .happy: Color.yellow
        }
    }
}

extension EmojiType: Plottable {
    var primitivePlottable: Double { valence }
    
    init?(primitivePlottable: Double) {
        switch primitivePlottable {
        case (EmojiType.angry.valence)..<(EmojiType.sad.valence): self = .angry // Exclusive of `sad`
        case (EmojiType.sad.valence)..<(EmojiType.indifferent.valence): self = .sad // Exclusive of `indifferent`
        case EmojiType.indifferent.valence: self = .indifferent // Indifferent is exact
        case (EmojiType.indifferent.valence)...(EmojiType.satisfied.valence): self = .satisfied // Inclusive of `satisfied`
        case (EmojiType.satisfied.valence)...(EmojiType.happy.valence): self = .happy // Inclusive of `happy`
        default: return nil
        }
    }
}

// MARK: - Save Details

extension EmojiType {
    /// Represents a failure to save a logged emoji emotion.
    struct SaveDetails: Identifiable, Equatable {
        let id = UUID()
        var errorString: String
    }
}
