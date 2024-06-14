/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The visualization of `EmojiType`, which is tappable for selection.
*/

import SwiftUI

struct EmojiButton: View {
    let emojiType: EmojiType
    let isSelected: Bool
    
    var body: some View {
        Text("\(emojiType.emoji)")
            .font(.system(size: 50))
            .shadow(color: isSelected ? emojiType.color : .clear, radius: 10)
    }
}
