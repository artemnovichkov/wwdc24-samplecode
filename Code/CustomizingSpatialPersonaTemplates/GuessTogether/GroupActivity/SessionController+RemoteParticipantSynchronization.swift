/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to the session controller that synchronizes the app's state
  across the SharePlay group session.
*/

import GroupActivities

extension SessionController {
    func shareLocalPlayerState(_ newValue: PlayerModel) {
        Task {
            do {
                try await messenger.send(newValue)
            } catch {
                // Failed to send the message.
            }
        }
    }
    
    func shareLocalGameState(_ newValue: GameModel) {
        gameSyncStore.editCount += 1
        gameSyncStore.lastModifiedBy = session.localParticipant
    
        let message = GameMessage(
            game: newValue,
            editCount: gameSyncStore.editCount
        )
        Task {
            do {
                try await messenger.send(message)
            } catch {
                // Failed to send the message.
            }
        }
    }
    
    func observeRemoteParticipantUpdates() {
        observeActiveRemoteParticipants()
        observeRemoteGameModelUpdates()
        observeRemotePlayerModelUpdates()
    }
    
    private func observeRemoteGameModelUpdates() {
        Task {
            for await (message, context) in messenger.messages(of: GameMessage.self) {
                let senderID = context.source.id
                
                let editCount = gameSyncStore.editCount
                let gameLastModifiedBy = self.gameSyncStore.lastModifiedBy ?? self.session.localParticipant
                let shouldAcceptMessage = if message.editCount > editCount {
                    true
                } else if message.editCount == editCount && senderID > gameLastModifiedBy.id {
                    true
                } else {
                    false
                }
                
                guard shouldAcceptMessage else {
                    continue
                }
                
                if message.game != gameSyncStore.game {
                    gameSyncStore.game = message.game
                }
                gameSyncStore.editCount = message.editCount
                gameSyncStore.lastModifiedBy = context.source
            }
        }
    }
    
    private func observeRemotePlayerModelUpdates() {
        Task {
            for await (player, context) in messenger.messages(of: PlayerModel.self) {
                players[context.source] = player
            }
        }
    }
    
    private func observeActiveRemoteParticipants() {
        let activeRemoteParticipants = session.$activeParticipants.map {
            $0.subtracting([self.session.localParticipant])
        }
        .withPrevious()
        .values
        
        Task {
            for await (oldActiveParticipants, currentActiveParticipants) in activeRemoteParticipants {
                let oldActiveParticipants = oldActiveParticipants ?? []
                
                let newParticipants = currentActiveParticipants.subtracting(oldActiveParticipants)
                let removedParticipants = oldActiveParticipants.subtracting(currentActiveParticipants)
                
                if !newParticipants.isEmpty {
                    // Send new participants the current state of the game.
                    do {
                        let gameMessage = GameMessage(
                            game: game,
                            editCount: gameSyncStore.editCount
                        )
                        try await messenger.send(gameMessage, to: .only(newParticipants))
                    } catch {
                        // Failed to send game catchup message.
                    }
                    
                    // Send new participants the player model of the local participant.
                    do {
                        try await messenger.send(localPlayer, to: .only(newParticipants))
                    } catch {
                        // Failed to send player catchup message.
                    }
                }

                // Remove any participants that have left from the active players dictionary.
                for participant in removedParticipants {
                    players[participant] = nil
                }
            }
        }
    }
    
    struct GameSyncStore {
        var editCount: Int = 0
        var lastModifiedBy: Participant?
        var game = GameModel()
    }
}

struct GameMessage: Codable, Sendable {
    let game: GameModel
    let editCount: Int
}
