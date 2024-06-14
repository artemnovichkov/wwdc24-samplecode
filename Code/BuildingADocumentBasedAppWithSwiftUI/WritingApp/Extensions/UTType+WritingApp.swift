/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file defines a type for this app's writing document.
*/

import UniformTypeIdentifiers

// This app's document type.
extension UTType {
    static var writingAppDocument: UTType {
        UTType(exportedAs: "com.example.writingAppDocument")
    }
}
