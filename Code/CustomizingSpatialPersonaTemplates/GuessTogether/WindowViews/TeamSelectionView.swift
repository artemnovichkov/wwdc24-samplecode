/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that invites activity participants to join the Blue or Red team.
*/

import SwiftUI

/// ```
/// ┌──────────────────────────────────┐
/// │ Red Team         Blue Team       │
/// │ ───────────────  ─────────────── │
/// │ ...              ...             │
/// │ ...              ...             │
/// │                  ...             │
/// │ Join Team                        │
/// │                  Join Team       │
/// │                                  │
/// │            ┌───────┐             │
/// │            │Ready ▶│             │
/// │            └───────┘             │
/// └──────────────────────────────────┘
/// ```
struct TeamSelectionView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        VStack {
            HStack {
                TeamList(team: .blue)
                TeamList(team: .red)
            }
            
            Button("Ready", systemImage: "checkmark") {
                appModel.sessionController?.startGame()
            }
            .tint(.green)
            .disabled(redAndBlueTeamsAreEmpty)
        }
        .padding()
        .guessTogetherToolbar()
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button("Back", systemImage: "chevron.left") {
                    appModel.sessionController?.endGame()
                }
            }
        }
    }
    
    var redAndBlueTeamsAreEmpty: Bool {
        if let sessionController = appModel.sessionController {
            let containsPlayerWithATeam = sessionController.players.values.contains {
                $0.team != nil
            }
            
            return !containsPlayerWithATeam
        } else {
            return true
        }
    }
}

struct TeamList: View {
    @Environment(AppModel.self) var appModel
    
    let team: PlayerModel.Team
    
    var body: some View {
        List {
            Section(team.name) {
                ForEach(playersOnTeam(team)) { player in
                    Text(player.name)
                }
                
                if appModel.sessionController?.localPlayer.team != team {
                    Button("Join \(team.name)", systemImage: "person.fill.badge.plus") {
                        appModel.sessionController?.joinTeam(team)
                    }
                    .foregroundStyle(team.color.gradient)
                } else {
                    Button("Leave Team", systemImage: "person.fill.badge.minus") {
                        appModel.sessionController?.joinTeam(nil)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    func playersOnTeam(_ team: PlayerModel.Team) -> [PlayerModel] {
        guard let sessionController = appModel.sessionController else {
            return []
        }
        
        return sessionController.players.values.lazy.filter { player in
            player.team == team && !player.name.isEmpty
        }
        .sorted(using: KeyPathComparator(\.id))
    }
}
