/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data model for a data point.
*/

import SwiftUI

struct DataPoint: Identifiable {
    let index: Int
    let id: Int
    let name: String
    let state: String
    let area: Int
    let startYear: Int
    let capacityAC: Double // Megawatts
    let capacityDC: Double // Megawatts
    let panelAxisType: String
    let tech: String
    let xLongitude: Angle
    let yLatitude: Angle

    // Precomputed stored properties for faster access using vectorized plots.
    let mapProjection: ThematicMapProjection
    let capacityDensity: Double
    let capacityGW: Double // Gigawatts
    let facilityCount: Double = 1

    internal init(
        index: Int,
        id: Int,
        name: String,
        state: String,
        area: Int,
        startYear: Int,
        capacityAC: Double,
        capacityDC: Double,
        panelAxisType: String,
        tech: String,
        xLongitude: Angle,
        yLatitude: Angle
    ) {
        self.index = index
        self.id = id
        self.name = name
        self.state = state
        self.area = area
        self.startYear = startYear
        self.capacityAC = capacityAC
        self.capacityDC = capacityDC
        self.panelAxisType = panelAxisType
        self.tech = tech
        self.xLongitude = xLongitude
        self.yLatitude = yLatitude
        self.mapProjection = .init(xLongitude: xLongitude, yLatitude: yLatitude)
        self.capacityDensity = 1_000_000 * capacityDC / Double(area)
        self.capacityGW = capacityDC / 1000
    }
}
