/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view modifier to affect the opacity of a view when it's in focus.
*/

import SwiftUI

struct VisibleWhenFocusedModifier: ViewModifier {
    @Environment(\.isFocused) var isFocused

    func body(content: Content) -> some View {
        content.opacity(isFocused ? 1 : 0)
    }
}

extension View {
    func visibleWhenFocused() -> some View {
        modifier(VisibleWhenFocusedModifier())
    }
}
