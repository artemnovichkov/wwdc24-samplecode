/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The valid drink types.
*/

internal import Foundation

// Define the types of drinks that Coffee Tracker supports.
public enum DrinkType: Int, CaseIterable, Identifiable, Codable, Sendable {

    case smallCoffee
    case mediumCoffee
    case largeCoffee
    case singleEspresso
    case doubleEspresso
    case quadEspresso
    case blackTea
    case greenTea
    case softDrink
    case energyDrink
    case chocolate

    // A unique ID for each drink.
    public var id: Int {
        self.rawValue
    }

    // The name of the drink as a user-readable string.
    public var name: String {
        switch self {
        case .smallCoffee: "Small Coffee"
        case .mediumCoffee: "Medium Coffee"
        case .largeCoffee: "Large Coffee"
        case .singleEspresso: "Single Espresso"
        case .doubleEspresso: "Double Espresso"
        case .quadEspresso: "Quad Espresso"
        case .blackTea: "Black Tea"
        case .greenTea: "Green Tea"
        case .softDrink: "Soft Drink"
        case .energyDrink: "Energy Drink"
        case .chocolate: "Chocolate"
        }
    }

    // The amount of caffeine in the drink.
    public var mgCaffeinePerServing: Double {
        switch self {
        case .smallCoffee: 96.0
        case .mediumCoffee: 144.0
        case .largeCoffee: 192.0
        case .singleEspresso: 64.0
        case .doubleEspresso: 128.0
        case .quadEspresso: 256.0
        case .blackTea: 47.0
        case .greenTea: 28.0
        case .softDrink: 22.0
        case .energyDrink: 29.0
        case .chocolate: 18.0
        }
    }
}
