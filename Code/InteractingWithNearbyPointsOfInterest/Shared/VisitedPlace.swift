/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data structure representing a location the user visits with the app.
*/

import Foundation
@preconcurrency import MapKit
import OSLog
import SwiftData

@Model
class VisitedPlace: Identifiable {
    
    /// The identifier that allows the app to retrieve the full details about this place from MapKit.
    @Attribute(.unique)
    let id: String
    let visitDate = Date()
    
    init(id: String) {
        self.id = id
    }
    
    /*
     The `VisitedPlace` structure only saves a map item's identifier to persist a map item to storage.
     To convert this stored identifier back to an `MKMapItem` for use in the app's UI, issue a request
     to get the `MKMapItem` object for the identifier.
     */
    /// - Tag: MapItemRequest
    @MainActor
    func convertToMapItem() async -> MKMapItem? {
        guard let identifier = MKMapItem.Identifier(rawValue: id) else { return nil }
        let request = MKMapItemRequest(mapItemIdentifier: identifier)
        var mapItem: MKMapItem? = nil
        do {
            mapItem = try await request.mapItem
        } catch let error {
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Map Item Requests")
            logger.error("Getting map item from identifier failed. Error: \(error.localizedDescription)")
        }
        return mapItem
    }
}

extension VisitedPlace {
    /// Place initial data into the model container so the sample isn't empty when it first runs.
    @MainActor
    static func seedHistoryWithInitialData(in modelContex: ModelContext) async {
        let sanFranciscoAppleStoreUnionSquareID = "IC44C414F19A0D09D"
        
        if let models = try? modelContex.fetch(VisitedPlace.reverseOrderFetchDescriptor), models.isEmpty {
            let visit = VisitedPlace(id: sanFranciscoAppleStoreUnionSquareID)
            modelContex.insert(visit)
        }
    }
    
    /// - Tag: MapItemIdentifier
    static func addNewVisit(mapItem: MKMapItem, to modelContext: ModelContext) {
        guard let identifier = mapItem.identifier else { return }
        let visit = VisitedPlace(id: identifier.rawValue)
        
        // This is in a transaction to ensure that if a person already visited the place, its record updates
        // by the time the UI rebuilds to prevent duplicate visit entries in the UI.
        try? modelContext.transaction {
            modelContext.insert(visit)
        }
    }
    
    /// The description for querying the visit history data from the model container.
    static var reverseOrderFetchDescriptor: FetchDescriptor<VisitedPlace> {
        var descriptor = FetchDescriptor<VisitedPlace>(sortBy: [SortDescriptor(\.visitDate, order: .reverse)])
        descriptor.fetchLimit = 10
        return descriptor
    }
}
