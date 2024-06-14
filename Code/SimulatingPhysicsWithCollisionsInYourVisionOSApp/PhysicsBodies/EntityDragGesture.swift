/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines a SwiftUI gesture that lets a person move a sphere in a scene.
*/

import SwiftUI
import RealityKit

struct EntityDragGesture: Gesture {
    struct GestureStateComponent: Component {
        var startPosition: SIMD3<Float>
    }

    let gestureStateType = GestureStateComponent.self

    typealias Closure = (Entity, SIMD3<Float>) -> Void

    let closure: Closure

    init(closure: @escaping Closure) {
        self.closure = closure
    }

    var body: some Gesture {
        DragGesture().targetedToAnyEntity().onChanged { gestureValue in
            let entity = gestureValue.entity
            let startPosition = startPosition(entity)
            let targetPosition = gestureValue.convert(gestureValue.translation3D,
                                                      from: .local,
                                                      to: .scene)

            closure(entity, startPosition + targetPosition)
        }.onEnded {
            $0.entity.components.remove(gestureStateType)
        }
    }

    func startPosition(_ entity: Entity) -> SIMD3<Float> {
        if let gestureStateComponent = entity.components[gestureStateType] {
            return gestureStateComponent.startPosition
        } else {
            let position = entity.position(relativeTo: nil)
            let newComponent = GestureStateComponent(startPosition: position)
            
            entity.components.set(newComponent)
            return position
        }
    }
}
