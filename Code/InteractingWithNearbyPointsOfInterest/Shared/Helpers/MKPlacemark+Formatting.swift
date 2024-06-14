/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility file to format addresses for display.
*/

import MapKit
import Contacts

extension MKPlacemark {
    var formattedAddress: String? {
        guard let postalAddress = postalAddress else { return nil }
        return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ")
    }
}
