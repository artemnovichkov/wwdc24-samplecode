/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view showing an insight that a calendar score represents.
*/

import SwiftUI

struct InsightCalendarScoreView: View {
    
    let insight: InsightModel
    let score: Int
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        InsightItemContainerView(backgroundColor: insight.color) {
            switch horizontalSizeClass {
            case .regular:
                regularHorizontalSizeClassView
            default:
                compactHorizontalSizeClassView
            }
        }
    }
    
    @ViewBuilder
    private var compactHorizontalSizeClassView: some View {
        VStack(alignment: .leading, spacing: 20) {
            displayLabelView
            HStack {
                Spacer()
                calendarScoreView
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var regularHorizontalSizeClassView: some View {
        HStack(alignment: .center) {
            displayLabelView
            Spacer()
            calendarScoreView
        }
        .padding()
    }
    
    @ViewBuilder
    private var displayLabelView: some View {
        Text(displayLabelText)
            .font(.title2)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
    }
    
    private var displayLabelText: String {
        let dateIntervalDisplayName = insight.dateInterval.displayName
        let insightDisplayName = insight.insightType.displayName
        if let dateIntervalDisplayName {
            return "\(dateIntervalDisplayName) \(insightDisplayName)"
        }
        return insightDisplayName
    }
    
    @ViewBuilder
    private var calendarScoreView: some View {
        CalendarScoreView(score: score,
                          strokeBackgroundColor: .white.opacity(0.25))
    }
    
}
