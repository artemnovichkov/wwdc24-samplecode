/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A file with views that gate content based on authorization.
*/

import HealthKit
import HealthKitUI
import EventKit
import SwiftUI

/// A view that handles requesting HealthKit data access and gates display of the `contentView` on successful authorization.
struct HealthKitAuthorizationGatedView<ContentView: View>: View {
    let contentView: ContentView
    
    @Binding var authorized: Bool?
    
    init(authorized: Binding<Bool?>, @ViewBuilder contentView: () -> ContentView) {
        self._authorized = authorized
        self.contentView = contentView()
    }
    
    var body: some View {
        VStack {
            switch authorized {
            case nil: ProgressView()
            case .some(true): contentView
            case .some(false):
                if HKHealthStore.isHealthDataAvailable() {
                    Text("Health data access isn't authorized.")
                } else {
                    Text("Health data isn't available on this device.")
                }
            }
        }
    }
}

/// A view that handles requesting EventKit data access, and gates the display of the `contentView` on successful authorization.
struct EventKitAuthorizationGatedView<ContentView: View>: View {
    let contentView: ContentView
    
    @Binding private var authorized: Bool?
    
    init(authorized: Binding<Bool?>,
         @ViewBuilder contentView: () -> ContentView) {
        self._authorized = authorized
        self.contentView = contentView()
    }
    
    var body: some View {
        VStack {
            switch authorized {
            case nil: ProgressView()
            case .some(true): contentView
            case .some(false): Text("Calendar data is not available.")
            }
        }
    }
}
