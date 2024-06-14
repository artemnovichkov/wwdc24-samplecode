/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable controller class that manages the active SharePlay
  group session.
*/

import GroupActivities
import Observation

@Observable @MainActor
class SessionController {
    let session: GroupSession<GuessTogetherActivity>
    let messenger: GroupSessionMessenger
    let systemCoordinator: SystemCoordinator
    
    var game: GameModel {
        get {
            gameSyncStore.game
        }
        set {
            if newValue != gameSyncStore.game {
                gameSyncStore.game = newValue
                shareLocalGameState(newValue)
            }
        }
    }
    var gameSyncStore = GameSyncStore() {
        didSet {
            gameStateChanged()
        }
    }

    var players = [Participant: PlayerModel]() {
        didSet {
            if oldValue != players {
                updateCurrentPlayer()
                updateLocalParticipantRole()
            }
        }
    }
    
    var localPlayer: PlayerModel {
        get {
            players[session.localParticipant]!
        }
        set {
            if newValue != players[session.localParticipant] {
                players[session.localParticipant] = newValue
                shareLocalPlayerState(newValue)
            }
        }
    }
    
    init?(_ session: GroupSession<GuessTogetherActivity>, appModel: AppModel) async {
        guard let systemCoordinator = await session.systemCoordinator else {
            return nil
        }
        
        self.session = session
        self.messenger = GroupSessionMessenger(session: session)
        self.systemCoordinator = systemCoordinator

        self.localPlayer = PlayerModel(
            id: session.localParticipant.id,
            name: appModel.playerName
        )
        appModel.showPlayerNameAlert = localPlayer.name.isEmpty
        
        observeRemoteParticipantUpdates()
        configureSystemCoordinator()
        
        self.session.join()
    }
    
    func updateSpatialTemplatePreference() {
        switch game.stage {
        case .categorySelection:
            systemCoordinator.configuration.spatialTemplatePreference = .sideBySide
        case .teamSelection:
            systemCoordinator.configuration.spatialTemplatePreference = .custom(TeamSelectionTemplate())
        case .inGame:
            systemCoordinator.configuration.spatialTemplatePreference = .custom(GameTemplate())
        }
    }
    
    func updateLocalParticipantRole() {
        switch game.stage {
        case .categorySelection:
            systemCoordinator.resignRole()
        case .teamSelection:
            switch localPlayer.team {
            case .none:
                systemCoordinator.resignRole()
            case .blue:
                systemCoordinator.assignRole(TeamSelectionTemplate.Role.blueTeam)
            case .red:
                systemCoordinator.assignRole(TeamSelectionTemplate.Role.redTeam)
            }
        case .inGame:
            if localPlayer.isPlaying {
                systemCoordinator.assignRole(GameTemplate.Role.player)
            } else if let currentPlayer {
                if currentPlayer.team == localPlayer.team {
                    systemCoordinator.assignRole(GameTemplate.Role.activeTeam)
                } else {
                    systemCoordinator.resignRole()
                }
            }
        }
    }
    
    func configureSystemCoordinator() {
        systemCoordinator.configuration.supportsGroupImmersiveSpace = true
        
        Task {
            for await localParticipantState in systemCoordinator.localParticipantStates {
                localPlayer.seatPose = localParticipantState.seat?.pose
            }
        }
    }

    func enterTeamSelection() {
        game.stage = .teamSelection
        game.currentRoundEndTime = nil
        game.turnHistory.removeAll()
    }
    
    func joinTeam(_ team: PlayerModel.Team?) {
        localPlayer.team = team
    }
    
    func startGame() {
        game.stage = .inGame(.beforePlayersTurn)
    }
    
    func beginTurn() {
        nextCard(successful: false)
        
        game.stage = .inGame(.duringPlayersTurn)
        game.currentRoundEndTime = .now.addingTimeInterval(30)
        
        let sleepUntilTime = ContinuousClock.now.advanced(by: .seconds(30))
        Task {
            try await Task.sleep(until: sleepUntilTime)
            if case .inGame(.duringPlayersTurn) = game.stage {
                game.stage = .inGame(.afterPlayersTurn)
            }
        }
    }
    
    func nextCard(successful: Bool) {
        guard localPlayer.isPlaying else {
            return
        }
        
        if successful {
            localPlayer.score += 1
        }
        
        let nextPhrase = PhraseManager.shared.randomPhrase(
            excludedCategories: game.excludedCategories,
            usedPhrases: game.usedPhrases
        )
        
        game.usedPhrases.insert(nextPhrase)
        game.currentPhrase = nextPhrase
    }
    
    func endTurn() {
        guard game.stage.isInGame, localPlayer.isPlaying else {
            return
        }
        
        game.turnHistory.append(session.localParticipant.id)
        game.currentRoundEndTime = nil
        game.stage = .inGame(.beforePlayersTurn)
        
        if playerAfterLocalParticipant != localPlayer {
            localPlayer.isPlaying = false
        }
    }
    
    func endGame() {
        game.stage = .categorySelection
    }
    
    func gameStateChanged() {
        if game.stage == .categorySelection {
            localPlayer.isPlaying = false
            localPlayer.score = 0
        }
        
        updateSpatialTemplatePreference()
        updateCurrentPlayer()
        updateLocalParticipantRole()
    }
}
