/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An entry in a list of reference objects.
*/

import SwiftUI
import ARKit

struct ListEntryView: View {
    var referenceObject: ReferenceObject
    var referenceObjectLoader: ReferenceObjectLoader
    
    var body: some View {
        let binding = Binding(
            get: { referenceObjectLoader.enabledReferenceObjects.contains(referenceObject) },
            set: { enabled in
                if enabled {
                    referenceObjectLoader.enabledReferenceObjects.append(referenceObject)
                } else {
                    referenceObjectLoader.enabledReferenceObjects.removeAll(where: { $0.id == referenceObject.id })
                }
            }
        )
        
        Toggle(isOn: binding, label: {
            Text("\(referenceObject.name)")
        })
    }
}
