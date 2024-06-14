/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to help decode JSON values from a URL.
*/
import Foundation
import os

extension URL {

    func decodeJSONValue<T: Decodable>(_ type: T.Type) throws -> T {
        let data = try Data(contentsOf: self)
        let decoder = JSONDecoder()
        let result = try decoder.decode(T.self, from: data)
        return result
    }

    func decodeJSONValue<T: Decodable>(_ type: T.Type, fallback: T) -> T {
        do {
            return try decodeJSONValue(type)
        } catch {
            Logger.general.error("Failed to decode \(type) from \(self). Error: \(error.localizedDescription)")
            return fallback
        }
    }
}
