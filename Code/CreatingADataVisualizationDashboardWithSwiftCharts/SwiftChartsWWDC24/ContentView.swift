/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view for the app.
*/

import SwiftUI

enum Tabs: Hashable {
    case function
    case dashboard
}

struct ContentView: View {
    @State private var selectedTab: Tabs = .dashboard
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(DashboardWindows.self) private var dashboardWindows

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Functions", systemImage: "function",
                value: Tabs.function) {
                Functions()
            }

            Tab("Dashboard", systemImage: "rectangle.3.group",
                value: Tabs.dashboard) {
                Dashboard()
                    #if os(visionOS)
                    .onAppear {
                        for window in DashboardWindow.allCases {
                            if !dashboardWindows.openedWindows.contains(window) {
                                dashboardWindows.openedWindows.insert(window)
                                openWindow(id: window.rawValue)
                            }
                        }
                    }
                    #endif
            }
        }
        // For easy readability of the numerous small scatterplot
        // points, a dark background is often preferable.
        .preferredColorScheme(.dark)
    }
}

#Preview(traits: .sampleData) {
    ContentView()
        .environment(DashboardWindows())
}
