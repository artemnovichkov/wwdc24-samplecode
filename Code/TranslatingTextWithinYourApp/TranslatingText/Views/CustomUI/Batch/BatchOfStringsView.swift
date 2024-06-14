/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that demonstrates how to translate a batch of strings all at once.
*/

import SwiftUI
import Translation

struct BatchOfStringsView: View {
    @Environment(ViewModel.self) var viewModel

    // Define a configuration.
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
            // Use the session the task provides to translate the text.
            await viewModel.translateAllAtOnce(using: session)
        }
        .onAppear {
            viewModel.reset()
        }
        .padding()
        .navigationTitle("Batch all at once")
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
    BatchOfStringsView()
}
