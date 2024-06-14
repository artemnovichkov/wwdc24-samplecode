/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for an object that represents a comment on a photo.
*/

import Foundation
import SwiftData

@Model
final class Comment: Identifiable {
    enum Reaction: Codable {
        case none
        case favorite
        case superFavorite

        var image: String {
            switch self {
            case .none:
                "star"
            case .favorite:
                "star.fill"
            case .superFavorite:
                "sparkles"
            }
        }

        var label: String? {
            switch self {
            case .superFavorite:
                "Super Favorite"
            default:
                nil
            }
        }
    }

    struct Reply: Identifiable, Codable {
        var id = UUID()
        var message: String
    }

    @Attribute(.unique)
    var id: UUID

    var contact: String
    var message: String
    var isUnread: Bool
    var reaction: Reaction
    var replies: [Reply]
    var trip: Trip?

    init(
        id: UUID,
        contact: String,
        message: String,
        isUnread: Bool,
        reaction: Reaction,
        replies: [Reply],
        trip: Trip
    ) {
        self.id = id
        self.contact = contact
        self.message = message
        self.isUnread = isUnread
        self.reaction = reaction
        self.replies = replies
        self.trip = trip
    }
}

// MARK: Generator

extension Comment {
    private static let commentMessages: [String: String] = [
        """
Looks like a wonderful time.
""": """
Thanks!
""",
        """
Absolutely beautiful!
""": """
It was, I had so much fun.
""",
        """
Hope you wore sunscreen.
""": """
You know it!
"""
    ]

    static func makeComments(for trip: Trip) -> [Comment] {
        commentMessages.keys.shuffled().map {
            let contact = Contact.names.randomElement()!
            return Comment(
                id: UUID(), contact: contact, message: $0, isUnread: true,
                reaction: .none, replies: [], trip: trip)
        }
    }

    static func makeReply(for comment: Comment) -> Reply? {
        commentMessages[comment.message].map { .init(message: $0) }
    }
}
