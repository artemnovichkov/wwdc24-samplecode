/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that demonstrates how to offer a system UI translation.
*/

import SwiftUI
import Translation

struct ViewTranslationView: View {
    // Define the condition to display the translation UI.
    @State private var showTranslation = false

    // Define the text you want to translate.
    var originalText = "Hallo, welt!"

    var body: some View {
        VStack {
            Text(verbatim: originalText)
            Button("Translate") {
                showTranslation.toggle()
            }
        }
        // Offer a system UI translation.
        .translationPresentation(isPresented: $showTranslation,
                                 text: originalText)
        .navigationTitle("Translate")
    }
}

#Preview {
    ViewTranslationView()
}

