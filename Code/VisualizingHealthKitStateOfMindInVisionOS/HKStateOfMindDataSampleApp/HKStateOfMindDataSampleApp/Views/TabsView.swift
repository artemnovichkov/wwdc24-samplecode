/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that manages the top-level tabs of the app.
*/
import SwiftUI
import EventKit
import HealthKit

/// The top-level tab view for the app.
struct TabsView: View {
    /// The types of tabs for the app.
    enum TabKind: Hashable {
        case today
        case charts
        case insights
    }
    
    /// The tab to select on appear, if any.
    private var initialTab: TabKind? = nil
    
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    @State private var selectedTab: TabKind = .charts
    @Binding var calendars: Calendars
    
    /* Authorization */
    @Binding var eventsAuthorized: Bool?
    
    @Binding var toggleHealthDataAuthorization: Bool
    @Binding var healthDataAuthorized: Bool?
    
    init(initialSelection: TabKind,
         calendars: Binding<Calendars>,
         eventsAuthorized: Binding<Bool?>,
         toggleHealthDataAuthorization: Binding<Bool>,
         healthDataAuthorized: Binding<Bool?>
    ) {
        self.initialTab = initialSelection
        self._calendars = calendars
        self._eventsAuthorized = eventsAuthorized
        self._toggleHealthDataAuthorization = toggleHealthDataAuthorization
        self._healthDataAuthorized = healthDataAuthorized
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(.todayViewDisplayTitle, systemImage: "calendar.day.timeline.leading", value: TabKind.today) {
                todayView()
            }
            Tab(.chartsViewDisplayTitle, systemImage: "chart.bar.xaxis", value: TabKind.charts) {
                calendarChartsView()
            }
            Tab(.insightsViewDisplayTitle, systemImage: "lightbulb", value: TabKind.insights) {
                insightsView()
            }
        }.onAppear {
            if let initialTab {
                selectedTab = initialTab
            }
        }
    }
    
    @MainActor
    @ViewBuilder
    private func todayView() -> some View {
        NavigationStack {
            EventKitAuthorizationGatedView(authorized: $eventsAuthorized) {
                HealthKitAuthorizationGatedView(authorized: $healthDataAuthorized) {
                    TodayView(calendars: calendars)
                        .navigationTitle(.todayViewDisplayTitle)
                }
            }
        }
    }
    
    @MainActor
    @ViewBuilder
    private func calendarChartsView() -> some View {
        NavigationStack {
            EventKitAuthorizationGatedView(authorized: $eventsAuthorized) {
                HealthKitAuthorizationGatedView(authorized: $healthDataAuthorized) {
                    CalendarChartsView(calendarModels: calendars.calendarModels)
                }
            }
            .navigationTitle(.chartsViewDisplayTitle)
        }
    }
    
    @MainActor
    @ViewBuilder
    private func insightsView() -> some View {
        NavigationStack {
            EventKitAuthorizationGatedView(authorized: $eventsAuthorized) {
                InsightsGridView(calendars: calendars)
                    .navigationTitle(.insightsViewDisplayTitle)
            }
        }
    }
    
}

@MainActor
extension LocalizedStringKey {
    static let todayViewDisplayTitle: LocalizedStringKey = "Today"
    static let chartsViewDisplayTitle: LocalizedStringKey = "Charts"
    static let insightsViewDisplayTitle: LocalizedStringKey = "Insights"
}
