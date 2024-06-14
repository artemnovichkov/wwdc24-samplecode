/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that's shown during the app's game stage and displays the score of
  each team next to the end-of-round timer.
*/

import SwiftUI

/// ```
/// ┌────────────────────────────────────┐
/// │ Blue Team                          │
/// │ ────────────                       │
/// │ 3                                  │
/// │                                    │
/// │                        00:27       │
/// │ Red Team                           │
/// │ ────────────                       │
/// │ 4                                  │
/// │                                    │
/// └────────────────────────────────────┘
/// ```
struct ScoreBoardView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    @State var showEndGameConfirmation: Bool = false
    
    var body: some View {
        HStack {
            List {
                if teamHasPlayers(.blue) {
                    TeamStatusView(team: .blue)
                }
                if teamHasPlayers(.red) {
                    TeamStatusView(team: .red)
                }
            }
            .frame(maxWidth: .infinity)
            
            Group {
                if let currentRoundEndTime = appModel.sessionController?.game.currentRoundEndTime {
                    if currentRoundEndTime > .now {
                        Text(timerInterval: .now...currentRoundEndTime)
                    } else {
                        Text("0:00")
                    }
                } else {
                    Text("0:30")
                }
            }
            .font(.system(size: 150, weight: .bold))
            .frame(maxWidth: .infinity)
        }
        .padding()
        .guessTogetherToolbar()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !appModel.isImmersiveSpaceOpen {
                    Button("Open Immersive Space", systemImage: "mountain.2.fill") {
                        Task {
                            await openImmersiveSpace(id: GameSpace.spaceID)
                        }
                    }
                }
                
                Button("End game", systemImage: "xmark") {
                    showEndGameConfirmation = true
                }
            }
        }
        .confirmationDialog("End the game for everyone?", isPresented: $showEndGameConfirmation, titleVisibility: .visible) {
            Button("End game", role: .destructive) {
                appModel.sessionController?.endGame()
            }
        }
    }
    
    func teamHasPlayers(_ team: PlayerModel.Team) -> Bool {
        if let sessionController = appModel.sessionController {
            return sessionController.players.values.contains { player in
                player.team == team
            }
        } else {
            return false
        }
    }
}

struct TeamStatusView: View {
    @Environment(AppModel.self) var appModel
    
    let team: PlayerModel.Team
    
    var score: Int {
        return players.map(\.score).reduce(0, +)
    }
    
    var players: [PlayerModel] {
        guard let sessionController = appModel.sessionController else {
            return []
        }
        
        return sessionController.players.values.filter { player in
            player.team == team
        }
        .sorted(using: KeyPathComparator(\.id))
    }
    
    var body: some View {
        Section(team.name) {
            ForEach(players) { player in
                if player.isPlaying {
                    LabeledContent(player.name, value: player.score.description)
                        .foregroundStyle(.green)
                        .bold()
                } else {
                    LabeledContent(player.name, value: player.score.description)
                }
            }
            
            LabeledContent("Total", value: score.description).bold()
        }
    }
}
