/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for entities.
*/
 
import SwiftUI
import RealityKit

// MARK: RainbowModel
/// A model containing data to assign to the created entities for the rainbow.
@Observable
class RainbowModel {
    // MARK: - Properties
    /// An array of the data to use for entities you add as attachments.
    var attachments: [EntityData] = [
        /// A `UIView` arch with orange color.
        EntityData(title: "orange"),
        /// A `CALayer` arch with red color.
        EntityData(title: "red"),
        /// A SwiftUI arch with pink color.
        EntityData(title: "pink"),
        /// A SwiftUI arch with blue color.
        EntityData(title: "blue")
    ]
    
    /// A Reality Composer Pro plane, from an asset creator, that is a physically based material with dark green color.
    var plane = EntityData(title: "plane")
    
    /// An array of the data for arches to load from Reality Composer Pro.
    var realityKitAssets: [EntityData] = [
        /// A Reality Composer Pro arch, from an asset creator, that is a custom shader graph material with green color.
        EntityData(title: "green"),
        /// A Reality Composer Pro arch, from an asset creator, that is a simple metallic material with yellow color.
        EntityData(title: "yellow", simpleMaterial: .init(color: .yellow, isMetallic: true))
    ]
}

// MARK: - Entity data
/// Represents the properites of each entity.
struct EntityData: Identifiable {
    let id = UUID()
    var title: String
    var simpleMaterial: SimpleMaterial? = nil
}

/// An enumeration that provides the type of view to create an attachment for.
enum ArchAttachment: String {
    case orange, pink, blue, red
}

/// Stores the position and scale of each attachment.
struct ViewAttachment: Identifiable {
    let id = UUID()
    var entity: EntityData
    var position: SIMD3<Float> = .zero
    var scale: SIMD3<Float> = .one
}
