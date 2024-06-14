/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that demonstrates how to translate a single string of text.
*/

import SwiftUI
import Translation

struct SingleStringView: View {
    @State private var sourceText = "Hallo, welt!"
    @State private var targetText = ""

    // Define a configuration.
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        VStack {
            TextField("Enter text to translate", text: $sourceText)
                .textFieldStyle(.roundedBorder)
            Button("Translate") {
                triggerTranslation()
            }
            Text(verbatim: targetText)
        }
        // Pass the configuration to the task.
        .translationTask(configuration) { session in
            do {
                // Use the session the task provides to translate the text.
                let response = try await session.translate(sourceText)

                // Update the view with the translated result.
                targetText = response.targetText
            } catch {
                // Handle any errors.
            }
        }
        .padding()
        .navigationTitle("Single string")
    }

    private func triggerTranslation() {
        guard configuration == nil else {
            configuration?.invalidate()
            return
        }

        // Let the framework automatically determine the language pairing.
        configuration = .init()
    }
}

#Preview {
    SingleStringView()
}
