/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A chart that draws datapoints in an outline of a map using `PointPlot` and `LinePlot`.
*/

import SwiftUI
import Charts

struct ThematicMap: View {
    @Environment(Model.self) var model: Model
    @Environment(\.colorScheme) var colorScheme

    @State private var xSelection: Double? = nil
    @State private var ySelection: Double? = nil

    private var closestPoint: DataPoint? {
        guard let xSelection, let ySelection else {
            return nil
        }

        func distance(_ point: DataPoint) -> Double {
            let xDiff = point.mapProjection.x - xSelection
            let yDiff = point.mapProjection.y - ySelection
            return sqrt(xDiff * xDiff + yDiff * yDiff)
        }

        let withinRadius = model.filteredData.filter { distance($0) < 0.01 }

        return withinRadius.min {
            distance($0) < distance($1)
        }
    }

    var body: some View {
        Chart {
            LinePlot(
                contiguousUSABorderCoordinates,
                x: .value("Longitude", \.mapProjection.x),
                y: .value("Latitude", \.mapProjection.y)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(.init(lineWidth: 1, lineCap: .round, lineJoin: .round))
            .foregroundStyle(.gray)

            PointPlot(
                model.filteredData,
                x: .value("Longitude", \.mapProjection.x),
                y: .value("Latitude", \.mapProjection.y)
            )
            .symbolSize(by: .value("Capacity", \.capacityDC))
            .foregroundStyle(by: .value("Breakdown", model.breakdownField.keyPath))

            if let focused = closestPoint {
                PointMark(
                    x: .value("Selected point (longitude)", focused.mapProjection.x),
                    y: .value("Selected point (latitude)", focused.mapProjection.y)
                )
                .symbolSize(50)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .accessibilityHidden(true)
                .annotation(position: .top, overflowResolution: .init(x: .fit, y: .fit)) {
                    Text("\(focused.name) (\(focused.state)) \(focused.capacityDC.formatted(.number.precision(.fractionLength(0...1)))) MW")
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .backgroundStyle(.ultraThinMaterial)
                        )
                        .padding(4)

                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: .automatic(includesZero: false))
        .chartYScale(domain: .automatic(includesZero: false))
        .chartSymbolSizeScale(domain: 0...1500, range: 2...100)
        .chartLegend(.hidden)
        .chartForegroundStyleScale(domain: model.breakdownField.domain)
        .chartPlotStyle {
            $0.aspectRatio(1.7, contentMode: .fit)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .chartXSelection(value: $xSelection)
        .chartYSelection(value: $ySelection)
    }
}

#Preview(traits: .sampleData, .fixedLayout(width: 600, height: 420), .landscapeLeft) {
    ThematicMap()
        .dashboardPanel("Installations (Size: Capacity)")
        .padding(dashboardPadding)
        #if os(visionOS)
        .glassBackgroundEffect()
        #endif
}
