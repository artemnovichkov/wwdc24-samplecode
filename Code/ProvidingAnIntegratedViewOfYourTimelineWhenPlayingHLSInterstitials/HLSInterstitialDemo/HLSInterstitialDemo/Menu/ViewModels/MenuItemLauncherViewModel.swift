/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model for showing the menu item details.
*/
import Observation

protocol MenuItemLauncherViewModelDelegate: AnyObject {
    
    func menuItemLauncherViewModelWantsToBePlayed(_ viewModel: MenuItemLauncherViewModel)
}

@Observable
class MenuItemLauncherViewModel {
    weak var delegate: MenuItemLauncherViewModelDelegate?
    private let item: MenuItem

    // MARK: - Life cycle

    init(item: MenuItem) {
        self.item = item
    }

    // MARK: - View

    var title: String {
        // Get item title.
        item.title
    }

    var description: String {
        // Get item description.
        item.description
    }

    var buttonTitle: String {
        "Play"
    }

    func play() {
        // Begin playback.
        delegate?.menuItemLauncherViewModelWantsToBePlayed(self)
    }
}
