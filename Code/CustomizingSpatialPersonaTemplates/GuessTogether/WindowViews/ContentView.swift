/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A top-level content view that presents the app's user interface based on
  the app's current stage.
*/

import GroupActivities
import SwiftUI

/// Guess Together has four stages:
///
/// 1. A welcome stage that is presented when you first launch the app and
///    invites you to create a SharePlay group session with your current
///    FaceTime call.
///
/// 2. A category selection stage where you’ll decide what categories you want
///    to play with. For example, maybe you want to play with phrases pulled
///    from historical events, or with something more simple, like different
///    fruits and vegetables.
///
/// 3. A team selection stage where you’ll decide to join the Blue or Red team.
///
/// 4. A game stage where Guess Together will open an immersive space and
///    present a view with a scoreboard and a timer. An additional view appears
///    in front of the active player with the secret phrase their teammates will
///     need to guess.
///
/// The content view presents a different view based on the app's current stage.
struct ContentView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        Group {
            switch appModel.sessionController?.game.stage {
            case .none:
                WelcomeView()
            case .categorySelection:
                CategorySelectionView()
            case .teamSelection:
                TeamSelectionView()
            case .inGame:
                ScoreBoardView()
            }
        }
        .task(observeGroupSessions)
    }
    
    /// Monitors for new Guess Together group activity sessions.
    @Sendable
    func observeGroupSessions() async {
        for await session in GuessTogetherActivity.sessions() {
            let sessionController = await SessionController(session, appModel: appModel)
            guard let sessionController else {
                continue
            }
            appModel.sessionController = sessionController

            // Create a task to observe the group session state and clear the
            // session controller when the group session invalidates.
            Task {
                for await state in session.$state.values {
                    guard appModel.sessionController?.session.id == session.id else {
                        return
                    }

                    if case .invalidated = state {
                        appModel.sessionController = nil
                        return
                    }
                }
            }
        }
    }
}
