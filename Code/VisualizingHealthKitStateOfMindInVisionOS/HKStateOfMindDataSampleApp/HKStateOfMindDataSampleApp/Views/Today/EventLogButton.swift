/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button on a calendar event, indicating whether a person has already logged it.
*/

import SwiftUI

struct EventLogButton: View {
    let isLogged: Bool
    
    var loggedStateSymbolName: String {
        isLogged ? "checkmark.circle.fill" : "circle"
    }
    
    var symbolColor: Color {
        isLogged ? .secondary.opacity(0.6) : .secondary
    }
    
    var body: some View {
        Image(systemName: loggedStateSymbolName)
            .animation(.easeInOut(duration: 0.25), value: isLogged)
            .font(.title2)
            .foregroundStyle(symbolColor)
    }
}
