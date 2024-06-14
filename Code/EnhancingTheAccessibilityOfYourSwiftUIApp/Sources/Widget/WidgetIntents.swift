/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Integration with App Intents.
*/

import SwiftData
import AppIntents

enum ComposeType: String, AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "ComposeType"

    static let caseDisplayRepresentations: [ComposeType: DisplayRepresentation] = [
        .photo: .init(stringLiteral: "photo"),
        .message: .init(stringLiteral: "message")
    ]

    case photo
    case message
}

struct ComposeIntent: AppIntent {
    static let title: LocalizedStringResource = "Compose Post"
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Type")
    var type: ComposeType
    
    init() {
        self.type = .message
    }

    init(type: ComposeType) {
        self.type = type
    }

    func perform() async throws -> some IntentResult {
        await TripRouter.shared.requestComposition(for: type)
        return .result()
    }
}

struct ToggleRatingIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Rating"

    @Parameter(title: "Beach ID")
    private var beachID: String?

    @Parameter(title: "Beach Rating")
    private var rating: Beach.Rating.IntentValue?

    init(beach: Beach, rating: Beach.Rating? = nil) {
        self.beachID = beach.id.uuidString
        self.rating = rating?.intentValue
    }

    init() {
        self.beachID = nil
        self.rating = nil
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let beachID, let beachID = UUID(uuidString: beachID) else {
            return .result()
        }
        let configuration = ModelConfiguration(groupContainer: .automatic)
        let container = try ModelContainer(
            for: Trip.self, Beach.self, configurations: configuration)
        let descriptor = FetchDescriptor(predicate: #Predicate<Beach> {
            $0.id == beachID
        })
        let results = try container.mainContext.fetch(descriptor)
        guard let beach = results.first else { return .result() }
        beach.rating = if let rating, let rating = Beach.Rating(intentValue: rating) {
            rating
        } else {
            switch beach.rating {
            case .none: .halfStar
            case .halfStar: .fullStar
            case .fullStar: .none
            }
        }
        try container.mainContext.save()
        return .result()
    }
}

// MARK: Utilities

extension Beach.Rating {
    fileprivate typealias IntentValue = Int

    fileprivate init?(intentValue: IntentValue) {
        switch intentValue {
        case 0: self = .none
        case 1: self = .halfStar
        case 2: self = .fullStar
        default:
            return nil
        }
    }

    fileprivate var intentValue: IntentValue {
        switch self {
        case .none: 0
        case .halfStar: 1
        case .fullStar: 2
        }
    }
}
