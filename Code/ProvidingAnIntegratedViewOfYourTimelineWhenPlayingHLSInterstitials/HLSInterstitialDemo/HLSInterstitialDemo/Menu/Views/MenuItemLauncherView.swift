/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show the menu item details.
*/
import SwiftUI

struct MenuItemLauncherView: View {
    let viewModel: MenuItemLauncherViewModel

    var body: some View {
        VStack {
            // Show item details.
            Text(viewModel.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(10)

            Text(viewModel.description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(10)

            // Show play button for item.
            Button(viewModel.buttonTitle) {
                viewModel.play()
            }
        }
    }
}
