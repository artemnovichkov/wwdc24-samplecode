/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable class that manages ignore item data.
*/

import SwiftUI

@Observable
final class IgnoreItemModel {
    /// Contains all email addresses and phone numbers the person wants to ignore.
    private var ignoreItems: [IgnoreItem]
    
    /// Contains the email addresses the person wants to ignore.
    var ignoredEmails: [IgnoreItem]
    
    /// Contains the phone numbers the person wants to ignore.
    var ignoredPhoneNumbers: [IgnoreItem]
    
    init() {
        self.ignoreItems = []
        self.ignoredEmails = []
        self.ignoredPhoneNumbers = []
    }
    
    var isEmpty: Bool {
        ignoreItems.isEmpty
    }
    
    /// Adds an ignore item.
    func addIgnoreItem(_ item: IgnoreItem) {
        ignoreItems.append(item)
        
        ignoredEmails = ignoreItems.filter({ $0.type == .email })
        ignoredPhoneNumbers = ignoreItems.filter({ $0.type == .phone })
    }
    
    /// Deletes an email ignore item.
    func removeEmailIgnoreItem(_ item: IgnoreItem) {
        guard let index = ignoreItems.firstIndex(where: { $0.id == item.id }) else { return }
        
        ignoreItems.remove(at: index)
        ignoredEmails = ignoreItems.filter({ $0.type == .email })
    }
    
    /// Deletes a phone number ignore item.
    func removePhoneNumberIgnoreItem(_ item: IgnoreItem) {
        guard let index = ignoreItems.firstIndex(where: { $0.id == item.id }) else { return }
        
        ignoreItems.remove(at: index)
        ignoredPhoneNumbers = ignoreItems.filter({ $0.type == .phone })
    }
}
