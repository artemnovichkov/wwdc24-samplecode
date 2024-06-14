/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Combine publisher that transforms the given upstream elements
  by providing the current element along with the previously published element.
*/

import Combine

extension Combine.Publisher {
    func withPrevious() -> AnyPublisher<(previous: Output?, current: Output), Failure> {
        scan(nil) { previousWithPrevious, currentElement in
            (previous: previousWithPrevious?.current, current: currentElement)
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }
}
