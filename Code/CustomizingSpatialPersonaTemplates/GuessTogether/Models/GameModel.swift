/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents the current state of the game
  in the SharePlay group session.
*/

import Foundation
import GroupActivities

struct GameModel: Codable, Hashable, Sendable {
    var stage: ActivityStage = .categorySelection
    
    var excludedCategories = Set<String>()
    
    var turnHistory = [Participant.ID]()
    
    var currentRoundEndTime: Date?
    var currentPhrase: PhraseManager.Phrase?
    
    var usedPhrases = Set<PhraseManager.Phrase>()
}

extension GameModel {
    enum GameStage: Codable, Hashable, Sendable {
        case beforePlayersTurn
        case duringPlayersTurn
        case afterPlayersTurn
    }
    
    enum ActivityStage: Codable, Hashable, Sendable {
        case categorySelection
        case teamSelection
        case inGame(GameStage)
        
        var isInGame: Bool {
            if case .inGame = self {
                true
            } else {
                false
            }
        }
    }
}
