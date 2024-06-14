/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for the chart showing State of Mind data for a calendar.
*/

import SwiftUI
import HealthKit
import Charts

extension CalendarChartsView {
    
    /// A view that shows a series of content together.
    struct ChartView: View {
        @Binding var dateConfiguration: DateConfiguration
        private let chartSeries: [ChartSeries]
        
        init(dateConfiguration: Binding<DateConfiguration>, chartSeries: [ChartSeries]) {
            self._dateConfiguration = dateConfiguration
            self.chartSeries = chartSeries
        }
        
        var body: some View {
            VStack {
                chartContent
                    .padding()
                    .padding([.leading], 20) // Additional padding for leading because the view has no axis.
#if os(visionOS)
                    .background(.thickMaterial)
                    .cornerRadius(16)
#else
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .quaternarySystemFill))
                    }
#endif
                    .onGeometryChange(for: Int.self) { proxy in
                        Int(proxy.size.width / 80) // 80 points per chart point.
                    } action: { newValue in
                        dateConfiguration.aggregationBinCount = newValue
                    }
                DateIntervalPaginationView(dateConfiguration: $dateConfiguration)
                    .padding()
            }
        }
        
        @ViewBuilder
        private var chartContent: some View {
            Chart {
                ForEach(chartSeries) { series in
                    if let chartPoints = series.chartPoints {
                        ForEach(chartPoints) { $0.ruleMark }
                            .lineStyle(StrokeStyle(lineWidth: 20, lineCap: .round))
                            .foregroundStyle(Color(cgColor: series.calendar.color).gradient)
                    }
                }
            }
            .frame(minWidth: 80)
            .chartXScale(domain: [dateConfiguration.chartingDateInterval.start,
                                  dateConfiguration.chartingDateInterval.end]) // Always show the dates for the data query.
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: dateConfiguration.dateBins.count))
            }
            .chartYScale(range: .plotDimension(padding: 20))
            .chartYAxis {
                AxisMarks(values: EmojiType.allCases) { emoji in
                    AxisValueLabel(horizontalSpacing: 20) {
                        let emojiType = emoji.as(EmojiType.self)!
                        Text(emojiType.emoji)
                            .font(.title)
                    }
                }
            }
            .contentTransition(.interpolate)
            .animation(.default, value: chartSeries)
        }
    }
    
    /// A view that displays the date intervals with options to increment or decrement the date interval.
    private struct DateIntervalPaginationView: View {
        @Binding var dateConfiguration: DateConfiguration
        var configurationContainsCurrentDate: Bool {
            dateConfiguration.chartingDateInterval.contains(Calendar.current.startOfDay(for: Date()))
        }
        
        var body: some View {
            HStack {
                Button {
                    dateConfiguration.decrement()
                } label: {
                    Image(systemName: "arrow.backward.circle")
                }
                .buttonStyle(.plain)
                dateIntervalText.frame(minWidth: 100) // Prevent buttons from moving as the text size changes.
                Button {
                    dateConfiguration.increment()
                } label: {
                    Image(systemName: "arrow.forward.circle")
                }
                .buttonStyle(.plain)
                .disabled(configurationContainsCurrentDate)
            }
        }
        
        @ViewBuilder
        var dateIntervalText: some View {
            // Use the start of the day to be exclusive of the end of the week.
            let startOfDay = Calendar.current.startOfDay(for: dateConfiguration.chartingDateInterval.start)
            let startString = DateFormatter.chartDateFormatter.string(for: startOfDay)!
            let endOfDay = Calendar.current.startOfDay(for: dateConfiguration.chartingDateInterval.end)
            let endString = DateFormatter.chartDateFormatter.string(for: endOfDay)!
            Text("\(startString) - \(endString)")
                .font(.title3)
                .bold()
        }
    }
    
    // MARK: - Models
    
    /// Contains the collection of points for a chart.
    struct ChartSeries: Identifiable, Equatable, Hashable {
        var id: String { calendar.id }
        
        let calendar: CalendarModel
        let chartPoints: [ChartPoint]?
        
        init(calendar: CalendarModel,
             samples: [HKStateOfMind],
             dateConfiguration: DateConfiguration) {
            self.calendar = calendar
            self.chartPoints = Self.chartPoints(from: samples, dateBins: dateConfiguration.dateBins)
        }
        
        private static func chartPoints(from samples: [HKStateOfMind], dateBins: DateBins) -> [ChartPoint] {
            // Group the samples by date.
            let groupedSamples = Dictionary(grouping: samples, by: { sample in
                dateBins.index(for: sample.endDate)
            })
            
            // Create a chart point for each day, and pin it to the start date of each bin to place it in the bin.
            let chartPoints = groupedSamples.map { chartPoint(for: $0.value, date: dateBins[$0.key].lowerBound) }
            return chartPoints
        }
        
        private static func chartPoint(for sampleCollection: [HKStateOfMind], date: Date) -> ChartPoint {
            let valences = sampleCollection.map { $0.valence }
            return .init(xValue: date, yStart: valences.min() ?? 0, yEnd: valences.max() ?? 0)
        }
    }
    
    /// A singular chart point for the Insights chart, representing data for the given date
    /// (which the system aggregates according to the `DateConfiguration`).
    struct ChartPoint: Identifiable, Equatable, Hashable {
        var id: Date { xValue }
        let xValue: Date
        let yStart: Double
        let yEnd: Double
        
        var ruleMark: RuleMark {
            .init(x: .value("Date", xValue),
                  yStart: .value("Minimum Valence", yStart),
                  yEnd: .value("Maximum Valence", yEnd))
        }
        
        init(xValue: Date,
             yStart: Double,
             yEnd: Double) {
            self.xValue = xValue
            self.yStart = yStart
            self.yEnd = yEnd
        }
    }
}
