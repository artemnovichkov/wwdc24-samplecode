/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A chart that represents data in a histogram using `BarMark`.
*/

import SwiftUI
import Charts

struct BreakdownHistogram: View {
    @Environment(Model.self) private var model: Model
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let breakdownCategory: BreakdownCategory
    
    var topN: Int {
        if horizontalSizeClass == .compact {
            switch breakdownCategory {
            case .axisType: 3
            case .technology: 3
            case .state: 4
            }
        } else {
            switch breakdownCategory {
            case .axisType: 4
            case .technology: 3
            case .state: 5
            }
        }
    }

    private var dataKeyPath: KeyPath<DataPoint, String> {
        switch breakdownCategory {
        case .axisType:
            \DataPoint.panelAxisType
        case .technology:
            \DataPoint.tech
        case .state:
            \DataPoint.state
        }
    }

    var bins: [(key: String, value: Int)] {
        model.data
            .reduce(into: [:]) { $0[$1[keyPath: dataKeyPath], default: 0] += 1 }
            .sorted { $0.value > $1.value || $0.value == $1.value && $0.key < $1.key }
    }

    var filteredData: ArraySlice<(key: String, value: Int)> {
        bins.prefix(topN)
    }

    var body: some View {
        Chart(filteredData, id: \.key) { element in
            BarMark(
                x: .value("Facility count", element.value),
                y: .value(breakdownCategory.description, element.key)
            )
            .foregroundStyle(by: .value("Type", model.breakdownField == breakdownCategory ? element.key : ""))
            .cornerRadius(4)
            .opacity(model.breakdownField == breakdownCategory ? 0.6 : 0.4)
            .annotation(position: .leading, alignment: .leading, overflowResolution: .init(x: .fit(to: .plot))) {
                Text(element.key.replacingOccurrences(of: "-", with: " ")).padding(.leading, 2)
            }
        }
        .chartYAxis(.hidden)
        .chartForegroundStyleScale(domain: model.breakdownField == breakdownCategory ? model.breakdownField.domain : [""])
        .chartLegend(.hidden)
        .onTapGesture {
            model.breakdownField = breakdownCategory
        }
    }
}

#Preview(traits: .sampleData) {
    BreakdownHistogram(breakdownCategory: .technology)
}
