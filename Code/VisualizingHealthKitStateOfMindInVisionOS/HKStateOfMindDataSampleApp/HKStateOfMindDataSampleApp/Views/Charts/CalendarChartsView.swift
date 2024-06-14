/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for showcasing State of Mind samples for calendars in a chart.
*/

import SwiftUI
import HealthKit
import EventKit
import Charts

/// A view that shows charts for the selected calendars.
struct CalendarChartsView: View {
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    let calendarModels: [CalendarModel]
    
    @State private var dataProvider: CalendarChartStateOfMindDataProvider = .init(healthStore: HealthStore.shared.healthStore,
                                                                                  selectedCalendars: [],
                                                                                  dateInterval: .weeklyInterval)
    @State private var dateConfiguration: DateConfiguration = DateConfiguration()
    
    /// Maps the core model to a view model for the chart.
    private var chartSeries: [ChartSeries] {
        return dataProvider.calendarStateOfMindData.map { calendarData in
            ChartSeries(calendar: calendarData.calendar,
                        samples: calendarData.stateOfMindSamples ?? [],
                        dateConfiguration: dateConfiguration)
        }
    }
    
    init(calendarModels: [CalendarModel]) {
        // Define the initial values for the view's state.
        self.calendarModels = calendarModels
    }
    
    var body: some View {
        VStack {
            // The calendar selector.
            if EKEventStore.authorizationStatus(for: .event) == .fullAccess {
                CalendarSelectorView(calendarModels: calendarModels,
                                     selectedCalendars: $dataProvider.selectedCalendars)
                .padding()
            } else {
                Text("Calendar Data Not Available")
            }
            
            // The chart viewer.
            if dataProvider.selectedCalendars.isEmpty {
                Spacer()
                Text("No Calendars Selected")
            } else {
                ChartView(dateConfiguration: $dateConfiguration,
                          chartSeries: chartSeries)
                .padding([.leading, .trailing])
            }
            Spacer()
        }
        .toolbar {
            if UIApplication.shared.supportsMultipleScenes {
                ToolbarItem(placement: .topBarTrailing) {
                    NewChartViewerButton()
                }
            }
        }
        .onChange(of: dateConfiguration, { oldValue, newValue in
            // Keep models in sync.
            dataProvider.dateInterval = newValue.queryDateInterval
        })
        .onAppear {
            self.dataProvider = .init(healthStore: HealthStore.shared.healthStore,
                                      selectedCalendars: Set(calendarModels),
                                      dateInterval: dateConfiguration.chartingDateInterval)
        }
    }
    
    private struct NewChartViewerButton: View {
        @Environment(\.openWindow) private var openWindow
        
        var body: some View {
            // Opens the chart viewer in a new window.
            Button("Open In New Window", systemImage: "plus.rectangle.on.rectangle") {
                openWindow(id: WindowGroupID.chart.rawValue)
            }
            .clipShape(Circle())
            .buttonBorderShape(.circle)
            .labelStyle(.iconOnly)
        }
    }
    
    // MARK: - Models
    
    /// A configuration of a particular lens into aggregating and visualization data over a date interval.
    struct DateConfiguration: Equatable {
        /// The date representing the latest date currently displaying.
        var anchorDate: Date = Calendar.current.startOfDay(for: Date()) // Begin with today as the anchor.
        /// The component to stride through when aggregating data.
        var aggregationCalendarComponent: Calendar.Component = .day
        /// The number of strides back in time from the anchor date.
        var aggregationBinCount: Int = 7
        
        /// The date interval working backward from the anchor date by the number of bins.
        var chartingDateInterval: DateInterval {
            .init(start: Calendar.current.date(byAdding: aggregationCalendarComponent,
                                               value: -(aggregationBinCount - 1), // Subtract 1 to avoid creating an additional bin.
                                               to: anchorDate)!,
                  end: anchorDate)
        }
        /// The date interval for querying backing data.
        var queryDateInterval: DateInterval {
            // Adjust the query date interval to be inclusive of today because the charting date interval normalizes to midnight today.
            .init(start: chartingDateInterval.start,
                  end: Calendar.current.date(byAdding: aggregationCalendarComponent, value: 1, to: anchorDate)!)
        }
        
        /// The bins to use to group data into chart points.
        var dateBins: DateBins { DateBins(unit: aggregationCalendarComponent,
                                          range: .init(uncheckedBounds: (chartingDateInterval.start, chartingDateInterval.end))) }
        
        /// Shifts the configuration back by one group of bins.
        mutating func decrement() {
            anchorDate = Calendar.current.date(byAdding: aggregationCalendarComponent,
                                               value: -aggregationBinCount,
                                               to: anchorDate)!
        }
        
        /// Shifts the configuration forward by one group of bins.
        mutating func increment() {
            anchorDate = Calendar.current.date(byAdding: aggregationCalendarComponent,
                                               value: aggregationBinCount,
                                               to: anchorDate)!
        }
    }
}
