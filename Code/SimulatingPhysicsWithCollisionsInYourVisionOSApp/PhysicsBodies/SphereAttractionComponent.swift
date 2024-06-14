/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines a RealityKit component that applies an attractive force to all other
 entities with the same component.
*/

import RealityKit

struct SphereAttractionComponent: Component {
    init() {
        SphereAttractionSystem.registerSystem()
    }
}
