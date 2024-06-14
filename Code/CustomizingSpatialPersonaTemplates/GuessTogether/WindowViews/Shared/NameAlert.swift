/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view modifier that presents an alert that asks for the participant's name.
*/

import SwiftUI

struct NameAlertModifier: ViewModifier {
    @Environment(AppModel.self) var appModel
    @State var playerName = ""
    
    func body(content: Content) -> some View {
        @Bindable var appModel = appModel
        
        content
            .alert("What's your name?", isPresented: $appModel.showPlayerNameAlert) {
                TextField("Name", text: $playerName).textContentType(.givenName)
                Button("Play!") {
                    appModel.playerName = playerName
                }
            } message: {
                Text("This name is shown to the other participants in your SharePlay session.")
            }
    }
}

extension View {
    func nameAlert() -> some View {
        modifier(NameAlertModifier())
    }
}
