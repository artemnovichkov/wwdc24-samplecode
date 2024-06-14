/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A wrapper type that bundles a label to a SwiftUI slider.
*/

import SwiftUI

/// A SwiftUI view that pairs a text label with a slider control.
///
/// The view places a label just above the slider.
/// The label explains to a person what the slider does.
public struct LabelSlider<Value>: View where Value: BinaryFloatingPoint, Value.Stride: BinaryFloatingPoint {

    /// The label that annotates the slider.
    var label: String

    /// The slider's underlying value.
    @Binding var value: Value

    /// The slider's range of acceptable values.
    var range: ClosedRange<Value>

    /// The difference in value between two adjacent positions along the slider.
    var step: Value.Stride?

    /// The main view for the particle slider.
    public var body: some View {
        VStack(alignment: .leading) {
            Text(label).font(.subheadline)
            if let step {
                Slider(
                    value: $value,
                    in: range,
                    step: step
                )
            } else {
                Slider(value: $value, in: range)
            }
        }
    }
}

#Preview {
    VStack {
        LabelSlider(label: "Example 1", value: .constant(5), range: 0...10)
        LabelSlider(label: "Example 2", value: .constant(5), range: 0...10, step: 1)
    }.padding(30).glassBackgroundEffect()
}
