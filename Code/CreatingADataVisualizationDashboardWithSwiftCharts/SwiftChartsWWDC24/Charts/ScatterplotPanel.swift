/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A chart that represents data in a scatterplot using `PointPlot`.
*/

import SwiftUI
import Charts

private enum GeographicalCoordinateKind: String, CaseIterable, Identifiable {
    case longitude = "Longitude"
    case latitude = "Latitude"

    var id: Self { self }
}

struct ScatterplotPanel: View {
    @State private var scatterplotKind: GeographicalCoordinateKind = .longitude
    @Environment(\.colorScheme) private var colorScheme

    static var title: LocalizedStringKey = "Capacity density by"

    var body: some View {
        Scatterplot(kind: scatterplotKind)
            .dashboardPanel(darker: colorScheme == .dark) {
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
        Picker(
            Self.title,
            selection: $scatterplotKind.animation(.easeInOut(duration: 0.5))
        ) {
            ForEach(GeographicalCoordinateKind.allCases) { kind in
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

private struct Scatterplot: View {
    @Environment(Model.self) private var model: Model
    @Environment(\.colorScheme) var colorScheme

    let kind: GeographicalCoordinateKind

    var data: [DataPoint] {
        model.filteredData
    }

    var xDomain: ClosedRange<Double> {
        switch kind {
        case .longitude: -125 ... -68
        case .latitude: 25...50
        }
    }

    var xKeyPath: KeyPath<DataPoint, Double> {
        switch kind {
        case .longitude: \.xLongitude.degrees
        case .latitude: \.yLatitude.degrees
        }
    }

    var body: some View {
        let regression = QuadraticRegression(data, x: xKeyPath, y: \.capacityDensity)

        let confidenceInterval = ConfidenceInterval(
            data: data, x: xKeyPath, y: \.capacityDensity, regression: regression)

        Chart {
            PointPlot(
                data,
                x: .value("Longitude", xKeyPath),
                y: .value("Capacity density", \.capacityDensity)
            )
            .foregroundStyle(by: .value("Breakdown", model.breakdownField.keyPath))
            .symbolSize(4)

            LinePlot(x: "x", y: "y") { x in
                regression(x)
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .lineStyle(.init(lineWidth: colorScheme == .dark ? 1.5 : 1))

            AreaPlot(x: "x", yStart: "Confidence interval low", yEnd: "Confidence interval low") {
                x in confidenceInterval(x)
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .opacity(0.3)
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: 0...200)
        .chartYAxisLabel("Energy density (watts per m²)")
        .chartForegroundStyleScale(domain: model.breakdownField.domain)
        .chartLegend(.hidden)
        .chartPlotStyle {
            $0.clipped()
        }
    }
}

#Preview(traits: .sampleData) {
    ScatterplotPanel()
}
