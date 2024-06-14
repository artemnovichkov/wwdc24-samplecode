/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show the main menu list.
*/
import Foundation
import SwiftUI

struct MenuView: View {
    @Bindable var viewModel: MenuViewModel
    @State var selectedItemViewModel: MenuItemViewModel?

    @ViewBuilder
    var menuDetailView: some View {
        if let selectedItemViewModel = viewModel.selectedItemViewModel {
            // Show details or player for selected item.
            switch selectedItemViewModel.contentViewModel {
            case .none:
                EmptyView()
            case .launcher(let menuItemLauncherViewModel):
                // Show item details.
                MenuItemLauncherView(viewModel: menuItemLauncherViewModel)
            case .player(let playerView):
                // Show player for item.
                playerView
            }
        } else {
            // Show generic view if no item is selected.
            GeometryReader { proxy in
                Image(systemName: "play.tv")
                    .font(.system(size: 60))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
    }

    @ViewBuilder
    var menuSidebarView: some View {
        // Show all items from the JSON menu.
        List(selection: $selectedItemViewModel) {
            // Iterate through all sections in the menu.
            ForEach(viewModel.sectionViewModels) { sectionViewModel in
                Section(sectionViewModel.title) {
                    // Display all menu items for each menu section.
                    ForEach(sectionViewModel.itemViewModels) { itemViewModel in
                        NavigationLink(value: itemViewModel) {
                            Text(itemViewModel.title)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedItemViewModel) { _, selectedItemViewModel in
            // Update the selected item view model based on list selection.
            viewModel.selectedItemViewModel = selectedItemViewModel
        }
    }

    var body: some View {
        VStack {
            Text("HLS Interstitial Demo").font(.headline).bold().padding(10)
            
            // Menu to navigate through examples.
            NavigationSplitView {
                // Show the list of all items.
                menuSidebarView
            } detail: {
                // Show details of the selected item.
                menuDetailView
            }
            .navigationTitle(viewModel.title)
            .modalPresentationCoordinated()
            .onOpenURL { url in
                viewModel.receive(menuURL: url)
            }
        }
        
    }
}
