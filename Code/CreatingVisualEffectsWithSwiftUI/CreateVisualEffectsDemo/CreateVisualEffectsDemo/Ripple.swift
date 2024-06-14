/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Examples for using and configuring the ripple shader as a layer effect.
*/

import SwiftUI

#Preview("Ripple") {
    @Previewable @State var counter: Int = 0
    @Previewable @State var origin: CGPoint = .zero

    VStack {
        Spacer()

        Image("palm_tree")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .onPressingChanged { point in
                if let point {
                    origin = point
                    counter += 1
                }
            }
            .modifier(RippleEffect(at: origin, trigger: counter))

        Spacer()
    }
    .padding()
}

#Preview("Ripple Editor") {
    @Previewable @State var origin: CGPoint = .zero
    @Previewable @State var time: TimeInterval = 0.3
    @Previewable @State var amplitude: TimeInterval = 12
    @Previewable @State var frequency: TimeInterval = 15
    @Previewable @State var decay: TimeInterval = 8

    VStack {
        GroupBox {
            Grid {
                GridRow {
                    VStack(spacing: 4) {
                        Text("Time")
                        Slider(value: $time, in: 0 ... 2)
                    }
                    VStack(spacing: 4) {
                        Text("Amplitude")
                        Slider(value: $amplitude, in: 0 ... 100)
                    }
                }
                GridRow {
                    VStack(spacing: 4) {
                        Text("Frequency")
                        Slider(value: $frequency, in: 0 ... 30)
                    }
                    VStack(spacing: 4) {
                        Text("Decay")
                        Slider(value: $decay, in: 0 ... 20)
                    }
                }
            }
            .font(.subheadline)
        }

        Spacer()

        Image("palm_tree")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .modifier(RippleModifier(origin: origin, elapsedTime: time, duration: 2, amplitude: amplitude, frequency: frequency, decay: decay))
            .onTapGesture {
                origin = $0
            }

        Spacer()
    }
    .padding(.horizontal)
}

struct PushEffect<T: Equatable>: ViewModifier {
    var trigger: T

    func body(content: Content) -> some View {
        content.keyframeAnimator(
            initialValue: 1.0,
            trigger: trigger
        ) { view, value in
            view.visualEffect { view, _ in
                view.scaleEffect(value)
            }
        } keyframes: { _ in
            SpringKeyframe(0.95, duration: 0.2, spring: .snappy)
            SpringKeyframe(1.0, duration: 0.2, spring: .bouncy)
        }
    }
}

/// A modifer that performs a ripple effect to its content whenever its
/// trigger value changes.
struct RippleEffect<T: Equatable>: ViewModifier {
    var origin: CGPoint

    var trigger: T

    init(at origin: CGPoint, trigger: T) {
        self.origin = origin
        self.trigger = trigger
    }

    func body(content: Content) -> some View {
        let origin = origin
        let duration = duration

        content.keyframeAnimator(
            initialValue: 0,
            trigger: trigger
        ) { view, elapsedTime in
            view.modifier(RippleModifier(
                origin: origin,
                elapsedTime: elapsedTime,
                duration: duration
            ))
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(duration, duration: duration)
        }
    }

    var duration: TimeInterval { 3 }
}

/// A modifier that applies a ripple effect to its content.
struct RippleModifier: ViewModifier {
    var origin: CGPoint

    var elapsedTime: TimeInterval

    var duration: TimeInterval

    var amplitude: Double = 12
    var frequency: Double = 15
    var decay: Double = 8
    var speed: Double = 1200

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.Ripple(
            .float2(origin),
            .float(elapsedTime),

            // Parameters
            .float(amplitude),
            .float(frequency),
            .float(decay),
            .float(speed)
        )

        let maxSampleOffset = maxSampleOffset
        let elapsedTime = elapsedTime
        let duration = duration

        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: maxSampleOffset,
                isEnabled: 0 < elapsedTime && elapsedTime < duration
            )
        }
    }

    var maxSampleOffset: CGSize {
        CGSize(width: amplitude, height: amplitude)
    }
}

extension View {
    func onPressingChanged(_ action: @escaping (CGPoint?) -> Void) -> some View {
        modifier(SpatialPressingGestureModifier(action: action))
    }
}

struct SpatialPressingGestureModifier: ViewModifier {
    var onPressingChanged: (CGPoint?) -> Void

    @State var currentLocation: CGPoint?

    init(action: @escaping (CGPoint?) -> Void) {
        self.onPressingChanged = action
    }

    func body(content: Content) -> some View {
        let gesture = SpatialPressingGesture(location: $currentLocation)

        content
            .gesture(gesture)
            .onChange(of: currentLocation, initial: false) { _, location in
                onPressingChanged(location)
            }
    }
}

struct SpatialPressingGesture: UIGestureRecognizerRepresentable {
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @objc
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }

    @Binding var location: CGPoint?

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = 0
        recognizer.delegate = context.coordinator

        return recognizer
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIGestureRecognizerType, context: Context) {
            switch recognizer.state {
                case .began:
                    location = context.converter.localLocation
                case .ended, .cancelled, .failed:
                    location = nil
                default:
                    break
            }
        }
    }
