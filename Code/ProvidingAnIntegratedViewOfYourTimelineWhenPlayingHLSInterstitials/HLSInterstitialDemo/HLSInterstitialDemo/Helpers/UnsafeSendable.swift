/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Wraps a value as an unchecked Sendable type.
*/
import Foundation

struct UnsafeSendable<WrappedType> : @unchecked Sendable {
    let wrappedValue: WrappedType

    init(wrappedValue: WrappedType) {
        self.wrappedValue = wrappedValue
    }
}
