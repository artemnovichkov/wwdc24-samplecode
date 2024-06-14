/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model for showing the menu sections.
*/
import Foundation
import Observation

protocol MenuSectionViewModelDelegate: AnyObject {

    func menuSectionViewModel(
        _ sectionViewModel: MenuSectionViewModel,
        wantsToPlayItemViewModel itemViewModel: MenuItemViewModel
    )
}

@Observable
class MenuSectionViewModel: Identifiable, MenuItemViewModelDelegate {
    weak var delegate: MenuSectionViewModelDelegate?

    private let section: MenuSection
    private var allItemViewModels = [MenuItemViewModel]()

    // MARK: - Identifiable

    var id: UUID {
        // Section ID
        section.id
    }

    // MARK: - Life cycle

    init(section: MenuSection) {
        self.section = section
        
        // Create item view models from items in menu section.
        allItemViewModels = section.items.map {
            let itemViewModel = MenuItemViewModel(item: $0)
            itemViewModel.delegate = self
            return itemViewModel
        }
        itemViewModels = allItemViewModels
    }

    // MARK: - MenuItemViewModelDelegate

    func menuItemViewModelWantsToBePlayed(_ itemViewModel: MenuItemViewModel) {
        // Begin playback.
        delegate?.menuSectionViewModel(self, wantsToPlayItemViewModel: itemViewModel)
    }

    // MARK: - View

    var itemViewModels = [MenuItemViewModel]()

    var title: String {
        // Section title
        section.title
    }
}
