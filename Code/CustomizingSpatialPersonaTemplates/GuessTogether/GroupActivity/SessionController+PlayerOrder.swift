/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to the session controller that calculates the player order
  in the current game of Guess Together.
*/

import Foundation
import GroupActivities

extension SessionController {
    func updateCurrentPlayer() {
        if game.stage.isInGame, localParticipantShouldBecomeActivePlayer {
            localPlayer.isPlaying = true
        }
    }
    
    var playerOrder: [Participant] {
        let firstPlayer = players.lazy.filter {
            $0.value.team != nil
        }
        .sorted(using: KeyPathComparator(\.key.id))
        .first?
        .value
        
        guard let firstPlayer else {
            return []
        }
        
        let firstTeam = firstPlayer.team!
        
        let secondTeam: PlayerModel.Team = switch firstTeam {
        case .blue: .red
        case .red: .blue
        }
        
        let sortedFirstTeam = players.filter {
            $0.value.team == firstTeam
        }
        .keys
        .sorted(using: KeyPathComparator(\.id))
        
        let sortedSecondTeam = players.filter {
            $0.value.team == secondTeam
        }
        .keys
        .sorted(using: KeyPathComparator(\.id))
        
        return sortedFirstTeam + sortedSecondTeam
    }
    
    var playerBeforeLocalParticipant: Participant? {
        guard let localParticipantIndex = playerOrder.firstIndex(of: session.localParticipant) else {
            return nil
        }
        
        if localParticipantIndex == 0 {
            return playerOrder.last
        } else {
            return playerOrder[localParticipantIndex - 1]
        }
    }
    
    var playerAfterLocalParticipant: PlayerModel? {
        guard let localParticipantIndex = playerOrder.firstIndex(of: session.localParticipant) else {
            return nil
        }
        
        let participant = if playerOrder.indices.contains(localParticipantIndex + 1) {
            playerOrder[localParticipantIndex + 1]
        } else {
            playerOrder.first
        }
        
        guard let participant else {
            return nil
        }
        
        return players[participant]
    }
    
    var currentPlayer: PlayerModel? {
        players.values.first(where: \.isPlaying)
    }
    
    var activeTeam: PlayerModel.Team? {
        return currentPlayer?.team
    }
    
    var localParticipantShouldBecomeActivePlayer: Bool {
        let playerOrder = self.playerOrder
        guard let playerBeforeLocalParticipant = self.playerBeforeLocalParticipant else {
            return false
        }
        
        guard let lastPlayer = game.turnHistory.last else {
            return playerOrder.first == session.localParticipant
        }
        
        let shouldBecomeActive = (lastPlayer == playerBeforeLocalParticipant.id)
        return shouldBecomeActive
    }
}
