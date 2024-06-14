/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model for showing the menu.
*/
import Combine
import Foundation
import GroupActivities
import Observation
import os
import SwiftUI

@Observable
class MenuViewModel: MenuSectionViewModelDelegate {
    private var allSectionViewModels = [MenuSectionViewModel]()
    private let sharePlayCoordinator = SharePlayCoordinator.shared

    // MARK: - Life cycle

    init(menu: Menu) {
        // Create view models from menu sections.
        self.allSectionViewModels = makeSectionViewModels(from: menu.sections)
        self.sectionViewModels = allSectionViewModels

        // Coordinate with SharePlay existing session.
        Task { [weak self] in
            guard let self = self else { return }
            for await sharedContent in self.sharePlayCoordinator.sharedContent {
                await self.receive(sharedContent: sharedContent)
            }
        }

        Task {
            await sharePlayCoordinator.resume()
        }
    }

    // MARK: - View

    var sectionViewModels = [MenuSectionViewModel]()

    var selectedItemViewModel: MenuItemViewModel? {
        willSet {
            if newValue != selectedItemViewModel {
                selectedItemViewModel?.dismissActiveContent()
            }
        }
    }

    var title: String {
        "HLS Interstitial Demo"
    }

    @MainActor
    func receive(menuURL url: URL) {
        Logger.general.log("[MenuViewModel] Received menu url \(url)")

        do {
            // Open the Menu.json file.
            try open(menuURL: url)
        } catch {
            Logger.general.error("Failed to open menu url. Error: \(error.localizedDescription)")
        }
    }

    // MARK: - MenuSectionViewModelDelegate

    func makeCurrentVideoMetadata(with itemViewModel: MenuItemViewModel) -> VideoMetadata {
        // Update video metadata for SharePlay coordination.
        VideoMetadata(
            menuItemIdentifier: itemViewModel.id,
            referenceDate: Date()
        )
    }

    func menuSectionViewModel(
        _ sectionViewModel: MenuSectionViewModel,
        wantsToPlayItemViewModel itemViewModel: MenuItemViewModel
    ) {
        Task { @MainActor in
            // Create a new activity for the selected video.
            let videoMetadata = makeCurrentVideoMetadata(with: itemViewModel)
            let activity = VideoWatchingActivity(videoMetadata: videoMetadata)

            // Await the result of the preparation call.
            switch await activity.prepareForActivation() {
            case .activationDisabled:
                // SharePlay isn't active or the participant prefers to play the video apart from the group.
                // Play the video locally.
                presentContentFromItemViewModel(itemViewModel, with: videoMetadata)

            case .activationPreferred:
                // SharePlay is active and the participant prefers to share this activity with the group.
                // The app starts video playback when it receives the session object for the activity.
                do {
                    // View model ignores the return value because activate() throws an exception if it encounters issues.
                    _ = try await activity.activate()
                } catch {
                    Logger.general.error("[MenuItemViewModel] Failed to active the movie watching activity. Error: \(error.localizedDescription)")
                }

            default:
                break
            }
        }
    }

    // MARK: - Private (URL)

    @MainActor
    private func open(menuURL url: URL) throws {
        // Open Menu.json.
        Logger.general.log("Attempting to decode custom menu file as `Menu`")
        let customMenu = try url.decodeJSONValue(Menu.self)
        
        // Create section view models from menu sections.
        allSectionViewModels = makeSectionViewModels(from: customMenu.sections)
        sectionViewModels = allSectionViewModels
    }

    // MARK: - Private (SharePlay)

    @MainActor
    private func receive(sharedContent: SharePlayCoordinator.SharedContent) {
        // Receive and display SharePlay content.
        Logger.general.log("[MenuViewModel] received SharePlay content \(String(describing: sharedContent))")

        switch sharedContent {
        case .none:
            dismissContent()

        case .video(let videoMetadata):
            // Get the item by the item identifier.
            guard let itemViewModel = menuItemViewModel(for: videoMetadata.menuItemIdentifier) else {
                Logger.general.error("[MenuViewModel] Received SharedMovie with unknown identifier: \(videoMetadata.menuItemIdentifier)")
                
                return
            }
            // Show player.
            presentContentFromItemViewModel(itemViewModel, with: videoMetadata)
        }
    }

    // MARK: - Private (View Model Tree)

    private func makeSectionViewModels(from sections: [MenuSection]) -> [MenuSectionViewModel] {
        sections.map {
            let sectionViewModel = MenuSectionViewModel(section: $0)
            sectionViewModel.delegate = self
            return sectionViewModel
        }
    }

    // MARK: - Private (Content Querying)

    private func menuItemViewModel(at path: IndexPath) -> MenuItemViewModel? {
        // Get a specific item in the menu section by index.
        sectionViewModels[boundsProtected: path.section]?
            .itemViewModels[boundsProtected: path.item]
    }

    private func menuItemViewModel(for identifier: UUID) -> MenuItemViewModel? {
        // Get a specific item in the menu by identifier.
        for sectionViewModel in sectionViewModels {
            for itemViewModel in sectionViewModel.itemViewModels where itemViewModel.id == identifier {
                return itemViewModel
            }
        }
        return nil
    }

    // MARK: - Private (Content Presentation)

    @MainActor
    private func presentContentFromItemViewModel(_ itemViewModel: MenuItemViewModel, with videoMetadata: VideoMetadata) {
        // Show player for the active item.
        Logger.general.log("[MenuViewModel] Presenting content with identifier \(itemViewModel.id.uuidString)")
        selectedItemViewModel = itemViewModel
        itemViewModel.presentPlayer(with: videoMetadata)
    }

    @MainActor
    private func dismissContent() {
        // Dismiss content for the active item.
        Logger.general.log("[MenuViewModel] Dismissing active content")
        selectedItemViewModel = nil
    }
}

extension MenuViewModel {

    // Create MenuViewModel.
    static let createViewModelWithMenu: MenuViewModel = {
        do {
            // Get menu from Menu.json.
            let menu = try Bundle.main.decode(Menu.self, fromJSONFile: "Menu")
            return MenuViewModel(menu: menu)
        } catch {
            // Return an empty menu if the app fails to read the Menu.json file.
            Logger.general.error("Failed to read menu from `Menu.json`. Error: \(error))")
            let emptyMenu = Menu(sections: [])
            return MenuViewModel(menu: emptyMenu)
        }
    }()
}
