/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example that demonstrates the use of NaN (not a number).
*/

import SwiftUI
import Charts

struct NaNRepresentsNoValue: View {
    var body: some View {
        Chart {
            AreaPlot(x: "x", y: "1 + x if and only if x ≥ 0") { x in
                guard x >= 0 else {
                    return Double.nan
                }
                return 1 + x
            }
        }
        .chartXScale(domain: -5...10)
        .chartYScale(domain: -5...10)
        .chartPlotStyle { content in
            content
                .aspectRatio(contentMode: .fit)
                .clipped()
        }
    }
}

#Preview {
    NaNRepresentsNoValue()
        .padding()
}
