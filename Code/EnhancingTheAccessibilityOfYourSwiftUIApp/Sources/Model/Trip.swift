/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for an object that represents a trip.
*/

import Foundation
import SwiftData
import SwiftUI

@Model
final class Trip {
    typealias Color = CodableColor

    struct Location: Codable {
        var lat: Double
        var long: Double
    }

    @Attribute(.unique)
    var id: UUID

    var title: String
    var date: Date
    var icon: String
    var message: String
    var image: String
    var color: Color

    var website: String?
    var location: Location?
    var rating: Beach.Rating?

    @Relationship(inverse: \Comment.trip)
    var comments: [Comment]

    init(
        id: UUID,
        title: String,
        date: Date,
        icon: String,
        message: String,
        image: String,
        color: Color,
        comments: [Comment],
        website: String?,
        location: Location?,
        rating: Beach.Rating?
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.icon = icon
        self.message = message
        self.image = image
        self.color = color
        self.comments = comments
        self.website = website
        self.location = location
        self.rating = rating
    }

    func makeAttachments(
        with configuration: TripAttachmentConfiguration
    ) -> [any TripAttachment] {
        var attachments = [any TripAttachment]()
        if let location {
            attachments.append(LocationAttachment(
                configuration: configuration, location: location))
        }
        if let website {
            attachments.append(WebsiteAttachment(
                configuration: configuration, website: website))
        }
        return attachments
    }
}

// MARK: Attachments

struct TripAttachmentConfiguration {
    var urlAction: OpenURLAction
}

protocol TripAttachment {
    var imageName: String { get }
    var label: String { get }
    var color: Color { get }
    var configuration: TripAttachmentConfiguration { get }

    @MainActor
    func performAction()
}

extension TripAttachment {
    var id: ObjectIdentifier { ObjectIdentifier(Self.self) }
}

struct LocationAttachment: TripAttachment {
    let imageName: String = "mappin"
    let label: String = "Location"
    let color: Color = Color.blue
    var configuration: TripAttachmentConfiguration

    var location: Trip.Location

    func performAction() {
        URL(string: "maps://?saddr=&daddr=\(location.lat),\(location.long)").map {
            configuration.urlAction($0)
        }
    }
}

struct WebsiteAttachment: TripAttachment {
    let imageName: String = "safari"
    let label: String = "Website"
    let color: Color = Color.green
    var configuration: TripAttachmentConfiguration

    var website: String

    func performAction() {
        URL(string: website).map {
            configuration.urlAction($0)
        }
    }
}

// MARK: Generator

extension Trip {
    private static let tripWebsite = "https://example.com/beach"

    private static let tripLocations = [
        (37.793_109, -122.483_900),
        (37.773_089, -122.512_281)
    ]

    private static let tripNames = [
        "Weekend Adventure",
        "Morning Excursion",
        "Afternoon Expedition",
        "Summer Day Trip",
        "Outing With Friends"
    ]

    private static let tripIcons = [
        "beach.umbrella.fill",
        "water.waves",
        "drop.fill",
        "sailboat.fill",
        "sun.max.fill"
    ]

    private static let tripColors: [SwiftUI.Color] = [
        .red,
        .blue,
        .green,
        .purple,
        .indigo
    ]

    private static let tripMessages = [
        """
It was a beautiful weekend. The boats were even out and sailing across the harbor
""",
        """
What a great day out with friends. The sun was shining and the waves were so calm.
"""
    ]

    private static let tripImages = [
        "beach_1",
        "beach_2",
        "beach_3",
        "beach_4",
        "beach_5",
        "beach_6",
        "beach_7",
        "beach_8",
        "beach_9"
    ]

    static func makeTrip(
        in environment: EnvironmentValues
    ) -> Trip {
        let name = tripNames.randomElement()!
        let icon = tripIcons.randomElement()!
        let color = tripColors.randomElement()!.resolve(
            in: environment).resolvedCodableColor
        let message = tripMessages.randomElement()!
        let image = tripImages.randomElement()!
        let location = tripLocations.randomElement()!
        let rating = Beach.Rating.allCases.randomElement()!
        let trip = Trip(
            id: UUID(), title: name, date: Date(), icon: icon,
            message: message, image: image, color: color, comments: [],
            website: tripWebsite, location: .init(
                lat: location.0, long: location.1), rating: rating)
        trip.comments.append(contentsOf: Comment.makeComments(for: trip))
        return trip
    }
}
