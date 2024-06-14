/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Styling information for centered content.
*/

import SwiftUI

struct CenteredListItemModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            Spacer()
            content
            Spacer()
        }
    }
}

