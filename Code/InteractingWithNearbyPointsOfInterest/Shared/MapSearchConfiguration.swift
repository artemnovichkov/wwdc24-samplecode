/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model object of settings to control the type of search results that return.
*/

import Foundation
import MapKit
import SwiftUI

/// An object containing parameters for customizing search criteria.
@Observable class MapSearchConfiguration {
    
    /// Options that indicate how to use the region information in a search.
    enum RegionPriority: CaseIterable {
        case `default`
        case required
        
        var localSearchRegionPriority: MKLocalSearchRegionPriority {
            switch self {
            case .default:
                MKLocalSearchRegionPriority.default
            case .required:
                MKLocalSearchRegionPriority.required
            }
        }
    }
    
    /// Options that indicate types of search results.
    enum SearchResultType: CaseIterable {
        case addresses
        case pointsOfInterest
        
        var completionResultType: MKLocalSearchCompleter.ResultType {
            switch self {
            case .addresses:
                MKLocalSearchCompleter.ResultType.address
            case .pointsOfInterest:
                MKLocalSearchCompleter.ResultType.pointOfInterest
            }
        }
        
        var localSearchResultType: MKLocalSearch.ResultType {
            switch self {
            case .addresses:
                MKLocalSearch.ResultType.address
            case .pointsOfInterest:
                MKLocalSearch.ResultType.pointOfInterest
            }
        }
    }
    
    /// Options for customizing the point-of-interest categories available in the search.
    enum PointOfInterestOptions: CaseIterable {
        case includeTravelCategories
        case excludeTravelCategories
        case anyCategory
        
        /// A filter that `MKMapView` uses.
        var filter: MKPointOfInterestFilter? {
            switch self {
            case .includeTravelCategories:
                MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)
            case .excludeTravelCategories:
                MKPointOfInterestFilter(excluding: MKPointOfInterestCategory.travelPointsOfInterest)
            case .anyCategory:
                nil
            }
        }
        
        /// An array of categories that `Map` uses.
        var categories: PointOfInterestCategories {
            switch self {
            case .includeTravelCategories:
                PointOfInterestCategories.including(MKPointOfInterestCategory.travelPointsOfInterest)
            case .excludeTravelCategories:
                PointOfInterestCategories.excluding(MKPointOfInterestCategory.travelPointsOfInterest)
            case .anyCategory:
                PointOfInterestCategories.all
            }
        }
    }
    
    /// Options for customizing the fields of an address to use in the search.
    enum AddressOptions: CaseIterable {
        case anyField
        case includeCityAndPostalCode
        
        var filter: MKAddressFilter {
            switch self {
            case .anyField:
                return MKAddressFilter.includingAll
            case .includeCityAndPostalCode:
                return MKAddressFilter(including: [.locality, .postalCode])
            }
        }
    }
    
    var resultType: SearchResultType = .pointsOfInterest
    var pointOfInterestOptions: PointOfInterestOptions = .anyCategory
    var addressOptions: AddressOptions = .anyField
    
    /// The region to use for scoping the search.
    var region: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
    
    /// Specifies whether the region is a hint to determine the search results, or whether the search results need to be in the region.
    var regionPriority: RegionPriority = .default
}
