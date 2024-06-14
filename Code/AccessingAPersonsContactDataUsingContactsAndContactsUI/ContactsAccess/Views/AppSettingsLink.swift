/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app settings link view.
*/

import Contacts
import SwiftUI

struct AppSettingsLink: View {
    @Environment(ContactStoreManager.self) private var storeManager
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            VStack {
                Group {
                    if storeManager.authorizationStatus == .denied {
                        deniedView
                    } else if storeManager.authorizationStatus == .restricted {
                        restrictedView
                    }
                }
                .multilineTextAlignment(.center)
            }
            .navigationTitle("Your Contacts")
        }
    }
    
    /// Takes the person to the Settings app on their device, where they can change permission settings for the app.
    private func navigatetoSettings() {
        guard let destination = URL(string: UIApplication.openSettingsURLString) else {
            fatalError("Expected a valid URL.")
        }
        openURL(destination)
    }
    
    private var navigateButton: some View {
        Button {
            navigatetoSettings()
        } label: {
            Text("Go to Settings")
        }
    }
    
    private var deniedView: some View {
        ContentUnavailableView {
            Label("No Access", systemImage: "lock.fill")
        } description: {
            Text("The app doesn't have permission to access contact data. Please grant the app access to Contacts in Settings.")
        } actions: {
            navigateButton
        }
    }
    
    private var restrictedView: some View {
        ContentUnavailableView {
            Label("Restricted Access", systemImage: "lock.fill")
        } description: {
            Text("This device doesn't allow access to Contacts. Please update the permission in Settings.")
        } actions: {
            navigateButton
        }
    }
}
