/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a set of charts that demonstrate function graphing.
*/

import SwiftUI
import Charts

struct Functions: View {
    static let viewTitle: LocalizedStringKey = "Function Catalog"

    private let columns = [
        GridItem(.adaptive(minimum: 320), spacing: 8, alignment: .topLeading)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    InteractiveFunctionPlot()
                        .dashboardPanel("Interactive function plot")
                        .frame(maxHeight: 480, alignment: .leading)

                    LazyVGrid(columns: columns, spacing: 20) {
                        FunctionExamples()
                    }
                }
                .padding(dashboardPadding)
            }
            .navigationTitle(Self.viewTitle)
        }
    }
}

#Preview(traits: .sampleData) {
    Functions()
        .padding()
}
