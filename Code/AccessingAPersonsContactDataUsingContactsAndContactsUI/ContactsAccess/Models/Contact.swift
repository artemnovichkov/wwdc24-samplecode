/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Maps the ID, given name, family name, full name, initials, and thumbnail information of a contact's object.
*/

import Contacts
import Foundation

struct Contact: Identifiable {
    var id: String
    var givenName: String
    var familyName: String
    var fullName: String
    var initials: String
    var thumbNail: Data?
    
    init(id: String, givenName: String, familyName: String, fullName: String, initials: String, thumbNail: Data? = nil) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.fullName = fullName
        self.initials = initials
        self.thumbNail = thumbNail
    }
}

extension Contact: Hashable {
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.id == rhs.id &&
        lhs.givenName == rhs.givenName &&
        lhs.familyName == rhs.familyName &&
        lhs.fullName == rhs.fullName &&
        lhs.initials == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(givenName)
        hasher.combine(familyName)
        hasher.combine(fullName)
        hasher.combine(initials)
        hasher.combine(thumbNail)
    }
}

extension Contact {
    static var sample: Contact {
        Contact(id: UUID().uuidString, givenName: "Aga", familyName: "Orlova", fullName: "Aga Orlova", initials: "AO")
    }
}
