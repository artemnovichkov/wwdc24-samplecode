/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model for each menu item.
*/
import Foundation
import os
import SwiftUI
import Observation

protocol MenuItemViewModelDelegate: AnyObject {
    func menuItemViewModelWantsToBePlayed(_ itemViewModel: MenuItemViewModel)
}

@Observable
class MenuItemViewModel: Identifiable, Hashable, MenuItemLauncherViewModelDelegate {
    weak var delegate: MenuItemViewModelDelegate?
    private var currentPlayerState: PlayerState?

    @ObservationIgnored
    private lazy var menuItemLauncherViewModel = {
        let viewModel = MenuItemLauncherViewModel(item: item)
        viewModel.delegate = self
        return viewModel
    }()

    let item: MenuItem

    // MARK: - Identifiable

    var id: UUID {
        item.id
    }

    // MARK: - Life cycle

    init(item: MenuItem) {
        self.item = item
        self.contentViewModel = .launcher(menuItemLauncherViewModel)
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MenuItemViewModel, rhs: MenuItemViewModel) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Public (ViewModels)

    func dismissActiveContent() {
        // Release player and clear player state when dismissing active content.
        Task { @MainActor in
            contentViewModel = .launcher(menuItemLauncherViewModel)
            ModalPresentationCoordinator.shared.dismissModalView()
            currentPlayerState?.invalidate()
            currentPlayerState = nil
        }
    }

    func presentPlayer(with videoMetadata: VideoMetadata) {
        // Show video player.
        
        let unsafeSelf = UnsafeSendable(wrappedValue: self)

        Task { @MainActor in
            // Create player state from menu item.
            let playerState = PlayerState(menuItem: self.item, videoMetadata: videoMetadata)
            unsafeSelf.wrappedValue.currentPlayerState = playerState

            // Use custom integrated timeline player view.
            let playerView = IntegratedTimelinePlayerView(
                playerState: playerState
            )
            
            // Release player when player view is explicitly dismissed.
            ModalPresentationCoordinator.shared.requestPresentation {
                playerView
            } onDismiss: {
                playerState.invalidate()
                unsafeSelf.wrappedValue.currentPlayerState = nil
            }
        }
    }

    // MARK: - MenuItemLauncherDelegate

    func menuItemLauncherViewModelWantsToBePlayed(_ viewModel: MenuItemLauncherViewModel) {
        delegate?.menuItemViewModelWantsToBePlayed(self)
    }

    // MARK: - View

    enum ContentViewModel {
        case none
        case launcher(MenuItemLauncherViewModel)
        case player(AnyView)
    }

    var contentViewModel = ContentViewModel.none

    var title: String {
        item.title
    }
}
