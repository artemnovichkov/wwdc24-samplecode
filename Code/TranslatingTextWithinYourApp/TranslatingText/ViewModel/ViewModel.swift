/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that set up the data for the translations in the demos' views.
*/

import Foundation
import Translation

@Observable
class ViewModel {
    var translatedText = ""
    var isTranslationSupported: Bool?

    // German food items ("Salad", "Fries", and "Soup")
    var foodItems = ["Salat 🥗", "Fritten 🍟", "Suppe 🍜"]

    func reset() {
        foodItems = ["Salat 🥗", "Fritten 🍟", "Suppe 🍜"]
        isTranslationSupported = nil
    }

    var availableLanguages: [AvailableLanguage] = []

    init() {
        prepareSupportedLanguages()
    }

    func prepareSupportedLanguages() {
        Task { @MainActor in
            let supportedLanguages = await LanguageAvailability().supportedLanguages
            availableLanguages = supportedLanguages.map {
                AvailableLanguage(locale: $0)
            }.sorted()
        }
    }
}

// MARK: - Single string of text

extension ViewModel {
    func translate(text: String, using session: TranslationSession) async {
        do {
            let response = try await session.translate(text)
            translatedText = response.targetText
        } catch {
            // Handle any errors.
        }
    }
}

// MARK: - Batch of strings

extension ViewModel {
    func translateAllAtOnce(using session: TranslationSession) async {
        Task { @MainActor in
            let requests: [TranslationSession.Request] = foodItems.map {
                // Map each item into a request.
                TranslationSession.Request(sourceText: $0)
            }

            do {
                let responses = try await session.translations(from: requests)
                foodItems = responses.map {
                    // Update each item with the translated result.
                    $0.targetText
                }
            } catch {
                // Handle any errors.
            }
        }
    }
}

// MARK: - Batch of strings as a sequence

extension ViewModel {
    func translateSequence(using session: TranslationSession) async {
        Task { @MainActor in
            let requests: [TranslationSession.Request] = foodItems.enumerated().map { (index, string) in
                // Assign each request a client identifier.
                    .init(sourceText: string, clientIdentifier: "\(index)")
            }

            do {
                for try await response in session.translate(batch: requests) {
                    // Use the returned client identifier (the index) to map the request to the response.
                    guard let index = Int(response.clientIdentifier ?? "") else { continue }
                    foodItems[index] = response.targetText
                }
            } catch {
                // Handle any errors.
            }
        }
    }
}

// MARK: - Language availability

extension ViewModel {
    func checkLanguageSupport(from source: Locale.Language, to target: Locale.Language) async {
        let availability = LanguageAvailability()
        let status = await availability.status(from: source, to: target)

        switch status {
        case .installed, .supported:
            isTranslationSupported = true
        case .unsupported:
            isTranslationSupported = false
        @unknown default:
            print("Not supported")
        }
    }
}
