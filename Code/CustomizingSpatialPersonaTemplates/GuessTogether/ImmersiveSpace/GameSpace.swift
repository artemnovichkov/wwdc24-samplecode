/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The immersive space presented during the game stage of Guess Together.
*/

import SwiftUI

struct GameSpace: Scene {
    @Environment(AppModel.self) var appModel
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    static let spaceID = "GameSpace"
    
    var body: some Scene {
        ImmersiveSpace(id: Self.spaceID) {
            ZStack {
                PhraseDeckPodiumView()
                SeatScoresView()
            }
            .onAppear {
                appModel.isImmersiveSpaceOpen = true
            }
            .onDisappear {
                appModel.isImmersiveSpaceOpen = false
            }
        }
        .onChange(of: appModel.sessionController?.game.stage, updateImmersiveSpaceState)
    }
    
    func updateImmersiveSpaceState(
        oldActivityStage: GameModel.ActivityStage?,
        newActivityStage: GameModel.ActivityStage?
    ) {
        let wasInGame = oldActivityStage?.isInGame ?? false
        let isInGame = newActivityStage?.isInGame ?? false
        
        guard wasInGame != isInGame else {
            return
        }
        
        Task {
            if isInGame && !appModel.isImmersiveSpaceOpen {
                await openImmersiveSpace(id: Self.spaceID)
            } else if appModel.isImmersiveSpaceOpen {
                await dismissImmersiveSpace()
            }
        }
    }
}
