/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for an object that represents a beach.
*/

import SwiftUI
import SwiftData
import AppIntents

@Model
final class Beach {
    typealias Gradient = CodableGradient

    enum Rating: Codable, CaseIterable, Comparable {
        case none
        case halfStar
        case fullStar

        var imageName: String {
            switch self {
            case .none:
                "star"
            case .halfStar:
                "star.leadinghalf.filled"
            case .fullStar:
                "star.fill"
            }
        }

        var label: String {
            switch self {
            case .none:
                "No Rating"
            case .halfStar:
                "Half Star"
            case .fullStar:
                "Full Star"
            }
        }
    }

    @Attribute(.unique)
    var id: UUID
    var dateCreated: Date
    var name: String
    var rating: Rating
    var gradient: Gradient

    init(
        id: UUID,
        dateCreated: Date,
        name: String,
        rating: Rating,
        gradient: Gradient
    ) {
        self.id = id
        self.dateCreated = dateCreated
        self.name = name
        self.rating = rating
        self.gradient = gradient
    }
}

// MARK: Generator

extension Beach {
    private static let beachGradientMix = 0.25

    private static let beachColors: [Color] = [
        .red,
        .blue,
        .green,
        .purple,
        .indigo
    ]

    static func makeBeach(in environment: EnvironmentValues) -> Beach {
        let color = beachColors.randomElement()!
        let secondColor = color.mix(with: .white, by: beachGradientMix)
        let gradient = Gradient(
            first: color.resolve(in: environment).resolvedCodableColor,
            second: secondColor.resolve(in: environment).resolvedCodableColor)
        return Beach(
            id: UUID(), dateCreated: .init(), name: "", rating: .none,
            gradient: gradient)
    }
}
