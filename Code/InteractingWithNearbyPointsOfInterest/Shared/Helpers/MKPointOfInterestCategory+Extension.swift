/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility file to provide icons for point-of-interest categories.
*/

import Foundation
import MapKit

extension MKPointOfInterestCategory {
    
    static let travelPointsOfInterest: [MKPointOfInterestCategory] = [
        // Places to eat, drink, and be merry.
        .bakery,
        .brewery,
        .cafe,
        .distillery,
        .restaurant,
        .winery,
        
        // Places to stay.
        .campground,
        .hotel,
        .rvPark,
        
        // Places to go.
        .beach,
        .castle,
        .conventionCenter,
        .fairground,
        .fortress,
        .nationalMonument,
        .nationalPark,
        .planetarium,
        .spa,
        .zoo
    ]
    
    static let defaultPointOfInterestSymbolName = "mappin.and.ellipse"
    
    var symbolName: String {
        switch self {
        case .airport:
            return "airplane"
        case .atm, .bank:
            return "banknote"
        case .bakery, .brewery, .cafe, .distillery, .foodMarket, .restaurant, .winery:
            return "fork.knife"
        case .beach:
            return "beach.umbrella"
        case .campground, .hotel:
            return "bed.double"
        case .carRental, .evCharger, .gasStation, .parking:
            return "car"
        case .store:
            return "storefront"
        case .library, .museum, .school, .theater, .university:
            return "building.columns"
        case .nationalMonument, .nationalPark, .park:
            return "leaf"
        case .postOffice:
            return "envelope"
        case .publicTransport:
            return "bus"
        case .zoo:
            return "bird"
        default:
            return MKPointOfInterestCategory.defaultPointOfInterestSymbolName
        }
    }
}
