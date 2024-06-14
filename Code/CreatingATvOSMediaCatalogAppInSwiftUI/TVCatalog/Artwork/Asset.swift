/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for an asset.
*/

import SwiftUI

enum Asset: String, CaseIterable, Identifiable {
    case beach
    case botanist
    case camping
    case coffeeberry
    case creek
    case discovery
    case hillside
    case lab
    case lake
    case landing
    case ocean
    case park
    case poppy
    case samples
    case yucca

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }

    var landscapeImage: Image {
        Image(rawValue + "_landscape")
    }

    var portraitImage: Image {
        Image(rawValue + "_portrait")
    }

    var keywords: [String] {
        switch self {
        case .beach:
            ["nature", "photography", "sea", "ocean", "beach", "sunset", "sea", "waves", "boats", "sky"]
        case .camping:
            ["nature", "photography", "forest", "insects", "dark", "camping", "plants"]
        case .creek:
            ["creek", "nature", "photography", "plants", "petal", "flower"]
        case .hillside:
            ["hillside", "cliffs", "sea", "ocean", "waves", "surf", "rocks", "nature", "photography", "grass", "plants"]
        case .ocean:
            ["sea", "ocean", "nature", "photography", "waves", "island", "sky"]
        case .park:
            ["nature", "photography", "park", "cactus", "plants", "sky"]
        case .lake:
            ["nature", "photography", "water", "turtles", "animals", "reeds"]

        case .coffeeberry:
            ["animated", "animation", "plants", "coffeeberry"]
        case .yucca:
            ["animated", "animation", "plants", "yucca"]
        case .poppy:
            ["animated", "animation", "plants", "poppy"]
        case .samples:
            ["animated", "animation", "plants", "samples"]
        case .discovery:
            ["botanist", "discovery", "science", "animated", "animation", "character", "cave", "mushrooms", "fungus", "fungi", "plants"]
        case .lab:
            ["botanist", "science", "lab", "laboratory", "animated", "animation", "character", "window", "plants"]
        case .botanist:
            ["botanist", "science", "animated", "animation", "character", "rocks", "grass", "plants"]
        case .landing:
            ["botanist", "science", "animated", "animation", "character", "space", "planet"]
        }
    }

    static var lookupTable: [String: [Asset]] {
        var result: [String: [Asset]] = [:]
        for asset in allCases {
            for keyword in asset.keywords {
                result[keyword, default: []].append(asset)
            }
        }
        return result
    }
}
