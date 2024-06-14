/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A chart that represents data in a heatmap using `RectangleMark`.
*/

import SwiftUI
import Charts

struct Heatmap: View {
    @Environment(Model.self) private var model: Model

    // Split each 10x increment in the logarithmic Y axis exactly to 5 parts.
    let base = pow(10, 1.0 / 5.0)
    let startExponent = -1
    let endExponent = 15

    struct HeatmapBinKey: Hashable {
        let year: Int
        let capacityIndex: Int

        var yearDate: Date {
            dateFromYear(year)
        }
    }

    struct HeatmapBin: Identifiable {
        let id: HeatmapBinKey
        let capacityLo: Double
        let capacityHi: Double
        let capacitySum: Double
        let values: [DataPoint]
    }

    var body: some View {
        @Bindable var model = model
        Chart {
            let capacityBins = NumberBins(
                thresholds: (startExponent...endExponent).map { log(pow(base, Double($0))) }
            )

            let capacityBinThresholds = capacityBins.thresholds.map(exp)
            
            let groups = Dictionary(grouping: model.data) {
                HeatmapBinKey(year: $0.startYear, capacityIndex: capacityBins.index(for: log($0.capacityDC)))
            }

            let yearCapacityBins = (startYear...endYear).flatMap { year in
                capacityBinThresholds.dropLast().enumerated().map { (capacityIndex, _) in
                    let key: HeatmapBinKey = .init(year: year, capacityIndex: capacityIndex)
                    let values = groups[key] ?? [] // Add a zero-valued bin to fill the plot.
                    return HeatmapBin(
                        id: key,
                        capacityLo: capacityBinThresholds[key.capacityIndex],
                        capacityHi: capacityBinThresholds[key.capacityIndex + 1],
                        capacitySum: values.reduce(0) { $0 + $1.capacityDC / 1000 },
                        values: values
                    )
                }
            }

            if let hoveredYear = model.hoveredYear {
                TimeHoverHighlight(hoveredYear: hoveredYear)
            }

            RectanglePlot(
                yearCapacityBins,
                x: .value("Installation year", \.id.yearDate, unit: .year),
                y: .value("Capacity range", \.capacityLo, \.capacityHi),
                width: .ratio(0.9),
                height: .ratio(0.9)
            )
            .foregroundStyle(by: .value("Count", \.values.count))
        }
        .chartXScale(domain: timeDomain)
        .chartYScale(domain: pow(base, Double(startExponent)) ... pow(base, Double(endExponent)), type: .log)
        .chartYAxisLabel("Count by capacity range (megawatts)")
        .chartYAxis {
            AxisMarks {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXSelection(value: $model.hoveredTime)
        .frame(minHeight: 250)
    }
}

#Preview(traits: .sampleData) {
    Heatmap()
}
