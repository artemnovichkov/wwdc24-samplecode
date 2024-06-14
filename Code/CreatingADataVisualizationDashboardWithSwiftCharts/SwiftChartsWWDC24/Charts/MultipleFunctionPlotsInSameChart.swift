/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example that graphs multiple functions in the same chart.
*/

import SwiftUI
import Charts

struct MultipleFunctionPlotsInSameChart: View {
    var body: some View {
        Chart {
            LinePlot(x: "x", y: "y = sin(x)") { sin($0) }
                .foregroundStyle(by: .value("function", "y = sin(x)"))
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

            LinePlot(x: "x", y: "y = 3cos(2x)") { 3 * cos(2 * $0) }
                .foregroundStyle(by: .value("function", "y = 3cos(2x)"))
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 8]))
                .opacity(0.8)
        }
        .chartXScale(domain: -10...10)
        .chartYScale(domain: -10...10)
        .chartPlotStyle { content in
            content
                .aspectRatio(contentMode: .fit)
        }
    }
}

#Preview {
    MultipleFunctionPlotsInSameChart()
        .padding()
}
