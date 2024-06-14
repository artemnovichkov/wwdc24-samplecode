/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that introduces the Guess Together game, and invites the person to
  create a SharePlay group session with the current FaceTime call.
*/

import GroupActivities
import SwiftUI

/// ```
/// ┌───────────────────────────────────────┐
/// │                                       │
/// │               {   *   }               │
/// │                                       │
/// │            Guess Together!            │
/// │                                       │
/// │                                       │
/// │   Welcome! To play, join a FaceTime   │
/// │                call...                │
/// │              ┌─────────┐              │
/// │              │ Play  ▶ │              │
/// │              └─────────┘              │
/// └───────────────────────────────────────┘
/// ```
struct WelcomeView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        VStack {
            WelcomeBanner().offset(y: 20)
            
            Text("Guess Together!").italic().font(.extraLargeTitle)
            
            Text("""
                Welcome to Guess Together! \
                To play, join a FaceTime call with a handful of friends. \
                You'll join a team and take turns trying to get your teammates \
                to guess your secret phrase.
                """
            )
            .multilineTextAlignment(.center)
            .padding()
            
            Divider()
            
            SharePlayButton().padding(.vertical, 20)
        }
        .padding(.horizontal)
    }
}

struct WelcomeBanner: View {
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "figure.fishing")
                .foregroundStyle(.cyan.gradient)
                .scaleEffect(x: -1)
            Image(systemName: "figure.climbing")
                .foregroundStyle(.yellow.gradient)
            Image(systemName: "figure.badminton")
                .foregroundStyle(.orange.gradient)
                .scaleEffect(x: -1)
            
            Image(systemName: "figure.run.square.stack.fill")
                .font(.system(size: 170))
                .foregroundStyle(.purple.gradient)
                .offset(y: -20)
            
            Image(systemName: "figure.archery")
                .foregroundStyle(.red.gradient)
            Image(systemName: "figure.play")
                .foregroundStyle(.green.gradient)
                .scaleEffect(x: -1)
            Image(systemName: "figure.surfing")
                .foregroundStyle(.blue.gradient)
        }
        .font(.system(size: 50))
        .frame(maxHeight: .infinity)
    }
}

struct SharePlayButton: View {
    @StateObject
    var groupStateObserver = GroupStateObserver()
    
    var body: some View {
        ZStack {
            ShareLink(
                item: GuessTogetherActivity(),
                preview: SharePreview("Guess Together!")
            ).hidden()
            
            Button("Play Guess Together", systemImage: "shareplay") {
                Task.detached {
                    try await GuessTogetherActivity().activate()
                }
            }
            .disabled(!groupStateObserver.isEligibleForGroupSession)
            .tint(.green)
        }
    }
}
