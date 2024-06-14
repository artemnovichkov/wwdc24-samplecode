/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view of settings to customize the app's behavior.
*/

import MapKit
import SwiftUI

struct SettingsView: View {
    
    var locationService: LocationService
    @Bindable var searchConfiguration: MapSearchConfiguration
    
    @Environment(\.dismiss) private var dismissAction
    var hostedDismissHandler: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        locationService.requestLocation()
                    } label: {
                        Label("Get Current Location", systemImage: "location")
                    }
                }
                Section {
                    Picker("Search For", selection: $searchConfiguration.resultType) {
                        ForEach(MapSearchConfiguration.SearchResultType.allCases, id: \.self) { option in
                            Text(option.localizedLabel)
                        }
                    }
                    Picker("Search Region", selection: $searchConfiguration.regionPriority) {
                        ForEach(MapSearchConfiguration.RegionPriority.allCases, id: \.self) { option in
                            Text(option.localizedLabel)
                        }
                    }
                }
                Section(header: Text("Points of Interest")) {
                    Picker("Category", selection: $searchConfiguration.pointOfInterestOptions) {
                        ForEach(MapSearchConfiguration.PointOfInterestOptions.allCases, id: \.self) { option in
                            Text(option.localizedLabel)
                        }
                    }
                }
                Section(header: Text("Address Search")) {
                    Picker("Address Component", selection: $searchConfiguration.addressOptions) {
                        ForEach(MapSearchConfiguration.AddressOptions.allCases, id: \.self) { option in
                            Text(option.localizedLabel)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") {
                    dismissAction()
                }.bold()
            }
            .onDisappear {
                if let hostedDismissHandler {
                    hostedDismissHandler()
                }
            }
        }
    }
}

private extension MapSearchConfiguration.SearchResultType {
    var localizedLabel: LocalizedStringKey {
        switch self {
        case .addresses:
            "Addresses"
        case .pointsOfInterest:
            "Points of Interest"
        }
    }
}

private extension MapSearchConfiguration.RegionPriority {
    var localizedLabel: LocalizedStringKey {
        switch self {
        case .default:
            "Nearby"
        case .required:
            "Visible Map Only"
        }
    }
}

private extension MapSearchConfiguration.PointOfInterestOptions {
    var localizedLabel: LocalizedStringKey {
        switch self {
        case .excludeTravelCategories:
            "Exclude Travel Categories"
        case .includeTravelCategories:
            "Include Travel Categories"
        case .anyCategory:
            "Any Category"
        }
    }
}

private extension MapSearchConfiguration.AddressOptions {
    var localizedLabel: LocalizedStringKey {
        switch self {
        case .anyField:
            "Any Address Field"
        case .includeCityAndPostalCode:
            "City and Postal Code"
        }
    }
}
