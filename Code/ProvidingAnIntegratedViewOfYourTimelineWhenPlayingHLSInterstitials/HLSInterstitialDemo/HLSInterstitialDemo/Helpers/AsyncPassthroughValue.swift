/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol that asynchronously sends element values of a sequence.
*/
import Foundation

public actor AsyncPassthroughValue<Element: Sendable>: AsyncSequence, AsyncIteratorProtocol {

    enum State {
        case active
        case terminal

        mutating func cancel() {
            switch self {
            case .active: self = .terminal
            default: break
            }
        }
    }

    var state: State
    var sendContinuation: UnsafeContinuation<Void, Never>?
    var nextContinuations = [UnsafeContinuation<Element?, Never>]()

    public init(_ elementType: Element.Type = Element.self) {
        state = .active
    }

    // Send the next element.
    public func next() async -> Element? {
        if Task.isCancelled {
            state.cancel()
            return nil
        }

        switch state {
        case .active:
            return await withUnsafeContinuation { continuation in
                nextContinuations.append(continuation)
                if let sendContinuation = sendContinuation {
                    self.sendContinuation = nil
                    sendContinuation.resume()
                }
            }

        case .terminal:
            return nil
        }
    }

    // Send the element value.
    public func send(_ element: Element) async {
        switch state {
        case .active:
            var other: UnsafeContinuation<Void, Never>?
            defer { other?.resume() }
            return await withUnsafeContinuation {
                other = sendContinuation
                sendContinuation = $0
                if !nextContinuations.isEmpty {
                    let nextContinuation = nextContinuations.removeFirst()
                    nextContinuation.resume(returning: element)
                }
            }

        case .terminal:
            break
        }
    }

    // Remove all the elements.
    public func finish() async {
        switch state {
        case .active:
            state = .terminal
        case .terminal:
            break
        }

        let continuations = nextContinuations
        nextContinuations.removeAll()
        for continuation in continuations {
            continuation.resume(returning: nil)
        }
    }

    public nonisolated func makeAsyncIterator() -> AsyncPassthroughValue<Element> {
        return self
    }
}

