/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines dice color options.
*/

import CoreBluetooth
import SwiftUI

enum DiceColor: String {
    case blue, pink

    var color: Color {
        switch self {
            case .pink: .pink
            case .blue: .cyan
        }
    }

    var displayName: String {
        "\(self.rawValue.capitalized) Dice"
    }

    var diceName: String {
        "\(self.rawValue)"
    }

    var serviceUUID: CBUUID {
        switch self {
            case .pink: CBUUID(string: "E56A082E-C49B-47CA-A2AB-389127B8ABE3")
            case .blue: CBUUID(string: "E56A082E-C49B-47CA-A2AB-389127B8ABE4")
        }
    }
}
