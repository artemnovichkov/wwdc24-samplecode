/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The caption order picker.
*/

import SwiftUI

struct CaptionOrderPicker: View {
    @Binding var caption: CaptionOrder
    
    var body: some View {
        Picker("Select ", selection: $caption) {
            ForEach(CaptionOrder.allCases) { order in
                Text(order.rawValue)
            }
        }
    }
}

#Preview("Default text") {
    CaptionOrderPicker(caption: .constant(.defaultText))
}

#Preview("Email") {
    CaptionOrderPicker(caption: .constant(.email))
}

#Preview("Phone number") {
    CaptionOrderPicker(caption: .constant(.phone))
}
