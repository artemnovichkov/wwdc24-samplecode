/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example of limiting the sampling domain for a function graph.
*/

import SwiftUI
import Charts

struct LimitFunctionSamplingDomain: View {
    var body: some View {
        Chart {
            AreaPlot(
                x: "x", yStart: "cos(x)", yEnd: "sin(x)",
                domain: -135...45
            ) { x in
                (yStart: cos(x / 180 * .pi),
                 yEnd: sin(x / 180 * .pi))
            }
        }
        .chartXScale(domain: -315...225)
        .chartYScale(domain: -5...5)
        .chartPlotStyle { content in
            content
                .aspectRatio(contentMode: .fit)
        }
    }
}

#Preview {
    LimitFunctionSamplingDomain()
        .padding()
}
