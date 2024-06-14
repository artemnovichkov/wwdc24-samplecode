/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that demonstrates how to offer a system UI translation
 where the user can replace the original text with the translation.
*/

import SwiftUI
import Translation

struct ReplaceTranslationView: View {
    @State private var showTranslation = false
    
    // Define the text you want to translate.
    @State private var originalText = "Me gustaría pedir la ensalada pequeña."

    var body: some View {
        VStack(spacing: 20) {
            TextField("Text to translate", text: $originalText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button("Translate") {
                showTranslation.toggle()
            }
        }
        // Setting the `replacementAction` closure returns the translated text.
        .translationPresentation(isPresented: $showTranslation, text: originalText) { translatedText in
            originalText = translatedText
        }
        .padding()
        .navigationTitle("Replace")
    }
}

#Preview {
    ReplaceTranslationView()
}
