/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry point for the app.
*/

import SwiftUI

@main
struct SwiftChartsWWDC24App: App {
    @State private var model = Model()
    @State private var dashboardWindows = DashboardWindows()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    do {
                        try model.loadSampleData()
                    } catch {
                        fatalError("Error loading sample data: \(error)")
                    }
                }
                .environment(model)
                .environment(dashboardWindows)
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 320)
                #endif
        }
        #if os(visionOS)
        .defaultSize(width: 640, height: 880)
        #elseif os(macOS)
        .defaultSize(width: 960, height: 640)
        #endif

        #if os(visionOS)
        WindowGroup(id: DashboardWindow.thematicMap.rawValue) {
            ThematicMap()
                .dashboardPanel(darker: true) {
                    HStack {
                        Text("Installations")
                            .font(.headline)
                        Spacer()
                        Text("Size: capacity")
                            .font(.subheadline)
                    }
                }
                .padding(dashboardPadding)
                .glassBackgroundEffect()
                .onDisappear {
                    dashboardWindows.openedWindows.remove(.thematicMap)
                }
        }
        .defaultSize(width: 640, height: 480)
        .environment(model)

        WindowGroup(id: DashboardWindow.scatterPlot.rawValue) {
            ScatterplotPanel()
                .padding(dashboardPadding)
                .glassBackgroundEffect()
                .onDisappear {
                    dashboardWindows.openedWindows.remove(.scatterPlot)
                }
        }
        .defaultSize(width: 640, height: 480)
        .environment(model)

        WindowGroup(id: DashboardWindow.capacityDensityDistribution.rawValue) {
            CapacityDensityDistribution()
                .dashboardPanel("Distribution of capacity density")
                .padding(dashboardPadding)
                .glassBackgroundEffect()
                .onDisappear {
                    dashboardWindows.openedWindows.remove(.capacityDensityDistribution)
                }
        }
        .defaultSize(width: 640, height: 320)
        .environment(model)
        #endif
    }
}
