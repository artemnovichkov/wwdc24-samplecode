/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The dashboard that displays all the charts.
*/

import SwiftUI
import Charts

struct Dashboard: View {
    @Environment(Model.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    var plots: some View {
        #if os(visionOS)
        EmptyView()
        #else
        VStack(spacing: 20) {
            ScatterplotPanel()

            ThematicMap()
                .dashboardPanel(darker: colorScheme == .dark) {
                    HStack {
                        Text("Installations")
                            .font(.headline)
                        Spacer()
                        Text("Size: capacity")
                            .font(.subheadline)
                    }
                }
        }
        #endif
    }

    var body: some View {
        ViewThatFits {
            HStack(spacing: 36) {
                VStack(spacing: 20) {
                    BreakdownPanel()
                    TimeSeriesPanel()
                }
                plots
            }

            ScrollView {
                VStack(spacing: 20) {
                    BreakdownPanel()
                    plots
                    TimeSeriesPanel()
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(dashboardPadding)
    }
}

var dashboardPadding: CGFloat {
    #if os(macOS)
    return 20
    #elseif os(visionOS)
    return 32
    #else
    return 8
    #endif
}

#Preview(traits: .sampleData) {
    Dashboard()
}
