/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The panel that displays the time-series charts.
*/

import SwiftUI
import Charts

private enum TimeSeriesKind: String, CaseIterable, Identifiable {
    case bars = "Count and Capacity"
    case heatmap = "Count by Capacity"

    var id: Self { self }
}

struct TimeSeriesPanel: View {
    @State private var timeSeriesKind: TimeSeriesKind = .bars

    static var title: LocalizedStringKey = "Installations"

    var body: some View {
        TimeSeries(kind: timeSeriesKind)
            .dashboardPanel {
                Group {
                    #if os(macOS)
                    picker
                        .pickerStyle(.segmented)
                    #else
                    LabeledContent {
                        picker
                            .pickerStyle(.segmented)
                    } label: {
                        Text(Self.title)
                    }
                    #endif
                }
                .font(.headline)
            }
    }

    var picker: some View {
        Picker(Self.title, selection: $timeSeriesKind) {
            ForEach(TimeSeriesKind.allCases) { kind in
                Text(kind.rawValue).tag(kind)
            }
        }
    }
}

private struct HeatmapBinKey: Hashable {
    let xLongitude: String
    let yLatitude: String
}

private struct HeatmapBinValue: Hashable {
    let capacity: Double
    let area: Int
}

private struct TimeSeries: View {
    @Environment(Model.self) private var model: Model
    let kind: TimeSeriesKind

    var body: some View {
        switch kind {
        case .bars:
            VStack(spacing: 36) {
                TimeSeriesBars(yLabel: "Facility count", metric: \.facilityCount)
                TimeSeriesBars(yLabel: "Installed capacity (gigawatts)", metric: \.capacityGW)
            }
        case .heatmap:
            Heatmap()
        }
    }
}

#Preview(traits: .sampleData) {
    TimeSeriesPanel()
}
