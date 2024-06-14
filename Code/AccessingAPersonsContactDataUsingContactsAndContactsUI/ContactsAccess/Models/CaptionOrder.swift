/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The caption order enumeration.
*/

import ContactsUI

enum CaptionOrder: String, Identifiable, CaseIterable, Codable {
    case email = "Email address"
    case phone = "Phone number"
    case defaultText = "Default"
    
    var id: Self { self }
}

extension CaptionOrder {
    var bottomCaption: ContactAccessButton.Caption {
        switch self {
        case .email: .email
        case .phone: .phone
        case .defaultText: .defaultText
        }
    }
}
