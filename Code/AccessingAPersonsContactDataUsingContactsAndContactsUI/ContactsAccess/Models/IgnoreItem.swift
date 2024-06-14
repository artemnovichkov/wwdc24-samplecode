/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The ignore item model.
*/

import Foundation

struct IgnoreItem: Identifiable, Hashable {
    var id: String
    var type: IgnoreItemType
    var item: String
    
    init(type: IgnoreItemType, item: String) {
        self.id = UUID().uuidString
        self.type = type
        self.item = item
    }
}
