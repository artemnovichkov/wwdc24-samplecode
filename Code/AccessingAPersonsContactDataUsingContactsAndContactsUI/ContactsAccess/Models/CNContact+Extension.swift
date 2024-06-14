/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extends the contact class.
*/

import Contacts

extension CNContact {
    /// The formatted name of a contact.
    var formattedName: String {
        CNContactFormatter().string(from: self) ?? "Unknown contact"
    }
    
    /// The contact name's initials.
    var initials: String {
        String(self.givenName.prefix(1) + self.familyName.prefix(1))
    }
    
    var contact: Contact {
        Contact(id: self.id.uuidString,
                givenName: self.givenName,
                familyName: self.familyName,
                fullName: self.formattedName,
                initials: self.initials,
                thumbNail: self.thumbnailImageData)
    }
}
