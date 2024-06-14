/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The observable object for managing opened dashboard windows.
*/

import Observation

enum DashboardWindow: String, CaseIterable {
    case thematicMap
    case scatterPlot
    case capacityDensityDistribution
}

@Observable
class DashboardWindows {
    var openedWindows: Set<DashboardWindow> = []
}
