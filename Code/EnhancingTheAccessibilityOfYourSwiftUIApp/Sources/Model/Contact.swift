/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for an object that represents a person's contact information.
*/

import Foundation
import SwiftData
import CoreTransferable

@Model
final class Contact: Identifiable {
    enum Sound: String, Codable, Transferable {
        case fans
        case synth
        case bells
        case rattle
        case fork
        case rain

        var name: String {
            switch self {
            case .fans: "Fans"
            case .synth: "Synth"
            case .bells: "Bells"
            case .rattle: "Rattle"
            case .fork: "Fork"
            case .rain: "Rain"
            }
        }

        var file: (name: String, type: String) {
            switch self {
            case .fans: ("fans", "m4a")
            case .synth: ("synth", "aif")
            case .bells: ("bells", "aif")
            case .rattle: ("rattle", "aif")
            case .fork: ("fork", "m4a")
            case .rain: ("rain", "aif")
            }
        }

        static var transferRepresentation: some TransferRepresentation {
            CodableRepresentation(contentType: .text)
            ProxyRepresentation(exporting: \.rawValue)
        }
    }

    struct SoundItem: Identifiable, Equatable, Codable {
        var id: UUID
        var point: CGPoint
        var sound: Contact.Sound

        init(id: UUID = UUID(), point: CGPoint, sound: Contact.Sound) {
            self.id = id
            self.point = point
            self.sound = sound
        }
    }

    @Attribute(.unique)
    var name: String
    var alert: [SoundItem]

    init(
        name: String,
        alert: [SoundItem]
    ) {
        self.name = name
        self.alert = alert
    }
}

// MARK: Generator

extension Contact {
    static let names = [
        "Kathy",
        "Nick",
        "Jack",
        "Beth",
        "Emily",
        "Andrew",
        "Cooper",
        "Eric",
        "Liz",
        "Patrick"
    ]
}
