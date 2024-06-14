/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to help check index bounds on a collection.
*/
import Foundation

extension Collection {

    subscript (boundsProtected index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
