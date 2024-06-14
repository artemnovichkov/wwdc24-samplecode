/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A chart that supports dragging and displaying `LinePlot`'s value.
*/

import SwiftUI
import Charts

struct InteractiveFunctionPlot: View {
    private let minX = -10.0
    private let maxX = 10.0
    private let minY = -4.0
    private let maxY = 4.0

    // Animating in
    @State private var onAppearDate: Date = .now

    // Selection
    @State private var selectedX: Double?

    var body: some View {
        TimelineView(.animation) { context in
            let animationDuration = 1.5

            Chart {
                RuleMark(x: .value("Y axis", 0))
                    .foregroundStyle(Color.secondary)
                RuleMark(y: .value("X axis", 0))
                    .foregroundStyle(Color.secondary)

                let samplingDomainLowerBound = minX
                let samplingDomainUpperBound: Double = {
                    let elapsedTime = context.date.timeIntervalSince(onAppearDate)
                    let progress = max(0, min(1, elapsedTime / animationDuration))
                    let currentMaxX = minX.interpolated(towards: maxX, amount: progress)
                    return currentMaxX
                }()
                LinePlot(
                    x: "x", y: "sin(x)",
                    domain: samplingDomainLowerBound...samplingDomainUpperBound
                ) { x in
                    sin(x)
                }
                .lineStyle(StrokeStyle(lineWidth: 2))

                if let selectedX, selectedX <= samplingDomainUpperBound {
                    let actualY = sin(selectedX)
                    PointMark(
                        x: .value("X", selectedX),
                        y: .value("Y", actualY)
                    )
                    .annotation {
                        Text("(\(selectedX, format: .number.precision(.fractionLength(2))), \(actualY, format: .number.precision(.fractionLength(2))))")
                            .monospaced()
                    }
                }
            }
            .chartXScale(domain: minX ... maxX)
            .chartYScale(domain: minY ... maxY)
            .chartXSelection(value: $selectedX)
            .chartPlotStyle { content in
                content
                    .aspectRatio(2, contentMode: .fit)
                    .clipped()
            }
        }
        .onAppear {
            onAppearDate = .now
        }
    }
}

#Preview {
    InteractiveFunctionPlot()
        .padding()
}
