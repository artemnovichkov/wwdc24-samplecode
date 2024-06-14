/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that verifies the authorization status of the app.
*/

import SwiftUI

struct MainView: View {
    @Environment(ContactStoreManager.self) private var storeManager
    
    var body: some View {
        VStack {
            switch storeManager.authorizationStatus {
            case .authorized:  FullAccessList()
            case .limited: LimitedAccessTab()
            case .restricted, .denied: AppSettingsLink()
            case .notDetermined: RequestAccessButton()
            @unknown default:
                fatalError("An unknown error occurred.")
            }
        }
        .onAppear {
            storeManager.fetchAuthorizationStatus()
        }
    }
}

#Preview {
    MainView()
        .environment(ContactStoreManager())
}
