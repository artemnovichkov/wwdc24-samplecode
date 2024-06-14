/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that demonstrates how to initiate the downloading of languages
 necessary to perform a translation.
*/

import SwiftUI
import Translation

struct PrepareTranslationView: View {

    // Define the pairing of languages you want to download.
    @State private var configuration = TranslationSession.Configuration(
        source: Locale.Language(identifier: "pt_BR"),
        target: Locale.Language(identifier: "ko_KR")
    )

    @State private var buttonTapped = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Tap the button to start downloading languages before offering a translation.")
            Button("Prepare") {
                configuration.invalidate()
                buttonTapped = true
            }
        }
        .translationTask(configuration) { session in
            if buttonTapped {
                do {
                    // Display a sheet asking the user's permission
                    // to start downloading the language pairing.
                    try await session.prepareTranslation()
                } catch {
                    // Handle any errors.
                }
            }
        }
        .padding()
        .navigationTitle("Prepare translation")
    }
}

#Preview {
    PrepareTranslationView()
}
