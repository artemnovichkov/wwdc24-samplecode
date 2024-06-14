/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The ignore item type.
*/

import Foundation

enum IgnoreItemType: String, Identifiable, CaseIterable, Codable {
    case email = "Email"
    case phone = "Phone number"
    
    var id: Self { self }
}
