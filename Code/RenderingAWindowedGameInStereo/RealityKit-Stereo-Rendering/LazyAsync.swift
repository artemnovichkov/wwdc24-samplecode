/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility that runs an async task only once and
 caches the result.
*/

public actor LazyAsync<T> {

    private var value: T?
    private let closure: () async -> T

    public init(_ closure: @escaping () async -> T) {
        self.closure = closure
    }

    public func get() async -> T {
        if let value = value {
            return value
        } else {
            self.value = await closure()
            return await get()
        }
    }
}
