/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view containing a single map item for use in a `List` or `UICollectionView` interface.
*/

import MapKit
import SwiftUI

struct MapItemRowView: View {
    
    let mapItem: MKMapItem
    
    private var symbolName: String {
        mapItem.pointOfInterestCategory?.symbolName ?? MKPointOfInterestCategory.defaultPointOfInterestSymbolName
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: symbolName)
                    .imageScale(.large)
                    .frame(minWidth: 20, maxWidth: 30)
                VStack(alignment: .leading) {
                    Text(mapItem.name ?? "")
                        .font(.headline)
                    Text(mapItem.placemark.formattedAddress ?? "")
                        .font(.subheadline)
                }
            }
        }
    }
}
