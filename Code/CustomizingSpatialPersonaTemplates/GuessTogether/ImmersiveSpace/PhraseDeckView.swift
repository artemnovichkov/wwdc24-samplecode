/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the current secret phrase "card" to the active player
   along with buttons to go to the next card.
*/

import Spatial
import SwiftUI

struct PhraseDeckView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.physicalMetrics) var converter
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .glassBackgroundEffect()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            switch appModel.sessionController?.game.stage {
            case .none, .categorySelection, .teamSelection, .inGame(.beforePlayersTurn):
                Button("Begin Turn", systemImage: "play.circle") {
                    appModel.sessionController?.beginTurn()
                }
                .controlSize(.extraLarge)
                .font(.largeTitle)
            case .inGame(.duringPlayersTurn):
                ZStack {
                    PhraseCardView(phrase: appModel.sessionController?.game.currentPhrase)
                    PhraseDeckButton(kind: .skipCurrentCard)
                    PhraseDeckButton(kind: .nextCard)
                }
            case .inGame(.afterPlayersTurn):
                Button("End Round", systemImage: "stop.circle") {
                    appModel.sessionController?.endTurn()
                }
                .controlSize(.extraLarge)
                .font(.largeTitle)
            }
        }
        .frame(width: 650, height: 400)
        .rotation3DEffect(Rotation3D(angle: .degrees(20), axis: .x), anchor: .center)
        .rotation3DEffect(Rotation3D(angle: .degrees(270), axis: .y), anchor: .center)
        .offset(y: -converter.convert(1.1, from: .meters))
    }
}

struct PhraseDeckButton: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.physicalMetrics) var converter
    
    var kind: Kind
    
    enum Kind {
        case nextCard
        case skipCurrentCard
    }
    
    var body: some View {
        Button {
            appModel.sessionController?.nextCard(successful: kind == .nextCard)
        } label: {
            Group {
                switch kind {
                case .nextCard:
                    Label("Got it!", systemImage: "checkmark.circle")
                case .skipCurrentCard:
                    Label("Skip", systemImage: "forward.circle")
                }
            }
            .padding()
        }
        .tint(color)
        .font(.system(size: 100))
        .labelStyle(.iconOnly)
        .rotation3DEffect(Rotation3D(angle: .degrees(-xOffsetDirection * 35), axis: .y))
        .offset(x: xOffsetDirection * 435)
        .offset(z: converter.convert(0.15, from: .meters))
        .disabled(!localParticipantIsPlaying)
    }
    
    var xOffsetDirection: CGFloat {
        switch kind {
        case .nextCard: 1
        case .skipCurrentCard: -1
        }
    }
    
    var color: Color {
        switch kind {
        case .nextCard: .green
        case .skipCurrentCard: .red
        }
    }
    
    var localParticipantIsPlaying: Bool {
        appModel.sessionController?.localPlayer.isPlaying ?? false
    }
}

struct PhraseCardView: View {
    let phrase: PhraseManager.Phrase?
    
    var body: some View {
        VStack {
            Text(phrase?.description ?? "")
                .font(.extraLargeTitle)
                .multilineTextAlignment(.center)
                .frame(maxHeight: .infinity)
            
            Divider()
            
            Text(phrase?.category.description ?? "")
                .font(.title)
                .italic()
                .padding()
        }
        .padding()
    }
}
