/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The panel that displays multiple charts that break down the data by several categories.
*/

import SwiftUI
import Charts

struct BreakdownPanel: View {
    @Environment(Model.self) private var model: Model

    var body: some View {
        VStack {
            picker
                .pickerStyle(.segmented)
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(BreakdownCategory.allCases) { category in
                    BreakdownHistogram(breakdownCategory: category)
                        .aspectRatio(contentMode: .fit)
                        .fixedSize(horizontal: false, vertical: true)
                        .dashboardPanel()
                }
            }
        }
    }

    @ViewBuilder var picker: some View {
        @Bindable var model = model
        Picker(selection: $model.breakdownField) {
            ForEach(BreakdownCategory.allCases) { kind in
                Text(kind.description)
                    .tag(kind)
            }
        } label: {
            EmptyView()
        }
    }
}

#Preview(traits: .sampleData) {
    BreakdownPanel()
}
