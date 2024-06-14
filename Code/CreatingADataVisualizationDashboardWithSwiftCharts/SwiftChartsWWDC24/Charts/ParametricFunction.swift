/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A chart that represents a parametric function using `LinePlot`.
*/

import SwiftUI
import Charts

struct ParametricFunction: View {
    var body: some View {
        Chart {
            LinePlot(
                x: "x", y: "y", t: "t", domain: 0 ... .pi * 2
            ) { t in
                let x = sqrt(2) * pow(sin(t), 3)
                let y = cos(t) * (2 - cos(t) - pow(cos(t), 2))
                return (x, y)
            }
            .lineStyle(.init(lineWidth: 3))
        }
        .chartXScale(domain: -4...4)
        .chartYScale(domain: -5...3)
        .chartPlotStyle { content in
            content
                .aspectRatio(contentMode: .fit)
        }
        .foregroundStyle(.red)
    }
}

#Preview {
    ParametricFunction()
        .padding()
}
