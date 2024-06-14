/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that demonstrates how to translate a batch of strings
 as a sequence.
*/

import SwiftUI
import Translation

struct BatchAsSequenceView: View {
    @Environment(ViewModel.self) var viewModel

    // Use the configuration, along with the button tap, to trigger the translation.
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        VStack {
            ForEach(viewModel.foodItems, id: \.self) { item in
                Text(item)
                    .padding()
            }
            HStack {
                Button("Translate") {
                    triggerTranslation()
                }
                Button("Reset") {
                    viewModel.reset()
                }
            }
        }
        .translationTask(configuration) { session in
            await viewModel.translateAllAtOnce(using: session)
        }
        .onAppear {
            viewModel.reset()
        }
        .padding()
        .navigationTitle("Batch as a sequence")
    }

    private func triggerTranslation() {
        if configuration == nil {
            // Set the language pairing.
            configuration = .init(source: Locale.Language(identifier: "de"),
                                  target: Locale.Language(identifier: "en"))
        } else {
            // Invalidate the previous configuration.
            configuration?.invalidate()
        }
    }
}

#Preview {
    BatchAsSequenceView()
}
