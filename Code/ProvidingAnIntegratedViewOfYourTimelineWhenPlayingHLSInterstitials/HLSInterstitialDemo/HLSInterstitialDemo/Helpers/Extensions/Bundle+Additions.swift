/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to help decode a bundle.
*/
import Foundation
import os

extension Bundle {

    func decode<T: Decodable>(_ type: T.Type, fromJSONFile file: String) throws -> T {
        guard let url = self.url(forResource: file, withExtension: "json") else {
            throw DecodingError.missingResource
        }

        return try url.decodeJSONValue(type)
    }
}

extension Bundle {

    enum DecodingError: Error {
        case missingResource
    }
}
