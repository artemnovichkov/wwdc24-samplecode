/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that allows activity participants select which categories
  they'd like to play with.
*/

import SwiftUI

/// A view that allows activity participants select which categories
/// they'd like to play with.
///
/// For example, maybe they want to play with phrases pulled from historical
/// events, or with something more simple, like different fruits and vegetables.
///
///```
/// ┌────────────────────────────────────┐
/// │                                    │
/// │ Film & Television               □  │
/// │ Fruits & Vegetables             ■  │
/// │ Historical Events               □  │
/// │ ...                             □  │
/// │                                    │
/// │                                    │
/// │             ┌────────┐             │
/// │             │ Play ▶ │             │
/// │             └────────┘             │
/// └────────────────────────────────────┘
/// ```
struct CategorySelectionView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        Form {
            Section {
                ForEach(PhraseManager.shared.categories, id: \.self) { category in
                    Toggle(category.description, isOn: isCategoryActive(category))
                }
            } header: {
                Text("Categories")
            } footer: {
                Text("Select the categories you'd like to play with.")
            }
        }
        .guessTogetherToolbar()
        
        Button("Play", systemImage: "play") {
            appModel.sessionController?.enterTeamSelection()
        }
        .padding(.vertical)
    }
    
    func isCategoryActive(_ category: String) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                if let sessionController = appModel.sessionController {
                    return !sessionController.game.excludedCategories.contains(category)
                } else {
                    return false
                }
            },
            set: { isOn in
                if isOn {
                    appModel.sessionController?.game.excludedCategories.remove(category)
                } else {
                    let excludedCategoriesCount = appModel.sessionController?.game.excludedCategories.count ?? 0
                    guard excludedCategoriesCount + 1 < PhraseManager.shared.categories.count else {
                        return
                    }
                    
                    appModel.sessionController?.game.excludedCategories.insert(category)
                }
            }
        )
    }
}
