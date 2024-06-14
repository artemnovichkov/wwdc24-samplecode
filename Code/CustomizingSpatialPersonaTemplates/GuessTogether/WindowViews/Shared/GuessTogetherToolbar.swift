/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The toolbar used in every top-level Guess Together view.
*/

import SwiftUI

struct GuessTogetherToolbarModifier: ViewModifier {
    @Environment(AppModel.self) var appModel
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "figure.run.square.stack.fill")
                            .foregroundStyle(.purple.gradient)
                        Text("Guess Together!")
                    }
                    .font(.largeTitle)
                    .italic()
                }
                
            }
            .toolbarRole(.navigationStack)
    }
}

extension View {
    func guessTogetherToolbar() -> some View {
        return modifier(GuessTogetherToolbarModifier())
    }
}
