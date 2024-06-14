/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The document type.
*/

import SwiftUI
import UniformTypeIdentifiers

struct WritingAppDocument: FileDocument {

    // Define the document type this app loads.
    // - Tag: ContentType
    static var readableContentTypes: [UTType] { [.writingAppDocument] }
    
    var story: String

    init(text: String = "") {
        self.story = text
    }

    // Load a file's contents into the document.
    // - Tag: DocumentInit
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        story = string
    }

    // Saves the document's data to a file.
    // - Tag: FileWrapper
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(story.utf8)
        return .init(regularFileWithContents: data)
    }
}
