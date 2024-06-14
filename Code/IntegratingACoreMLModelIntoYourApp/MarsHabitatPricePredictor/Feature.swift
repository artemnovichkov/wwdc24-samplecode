/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Enumeration representing the different features for the habitats.
*/

import UIKit

/**
     Represents the different features used by this model. Each feature
     (# of solar panels, # of greenhouses, or size) is an input value to the
     model. So each needs an appropriate `UIPicker` as well.
*/
enum Feature: Int {
    case solarPanels = 0, greenhouses, size
}
