/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A chart that represents time-series data using `BarMark`.
*/

import SwiftUI
import Charts

struct TimeHoverHighlight: ChartContent {
    let hoveredYear: Int

    var body: some ChartContent {
        RectangleMark(
            x: .value("Highlighted year", dateFromYear(hoveredYear), unit: .year),
            width: .ratio(1)
        )
        .foregroundStyle(.white)
        .opacity(0.2)
        .cornerRadius(4)
    }
}

struct TimeSeriesBars: View {
    @Environment(Model.self) private var model: Model
    let yLabel: LocalizedStringKey
    let metric: KeyPath<DataPoint, Double>

    struct SubBarKey: Hashable, Identifiable {
        let year: Date
        let breakdown: String

        var id: String {
            "\(year)|\(breakdown)"
        }
    }

    var body: some View {
        @Bindable var model = model
        Chart {
            if let hoveredYear = model.hoveredYear {
                TimeHoverHighlight(hoveredYear: hoveredYear)
            }

            let data: [(key: SubBarKey, value: Double)] = model.data.reduce(into: [:]) {
                let key = SubBarKey(
                    year: dateFromYear($1.startYear),
                    breakdown: $1[keyPath: model.breakdownField.keyPath]
                )
                $0[key, default: 0] += $1[keyPath: metric]
            }.sorted { $0.key.year < $1.key.year || $0.key.year == $1.key.year && $0.key.breakdown < $1.key.breakdown }

            ForEach(data, id: \.key) {
                BarMark(
                    x: .value("Year", $0.key.year, unit: .year),
                    y: .value(yLabel, $0.value)
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("Breakdown", $0.key.breakdown))
            }
        }
        .chartXScale(domain: timeDomain)
        .chartYAxisLabel(yLabel)
        .chartYAxis {
            AxisMarks {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXSelection(value: $model.hoveredTime)
        .chartForegroundStyleScale(domain: model.breakdownField.domain)
        .chartLegend(.hidden)
    }
}

#Preview(traits: .sampleData) {
    TimeSeriesBars(
        yLabel: "Installed capacity",
        metric: \.capacityGW
    )
}
