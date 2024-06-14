/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows an insight for an event.
*/

import SwiftUI

struct InsightEventView: View {
    
    let insightTitle: String
    let eventName: String
    var backgroundColor: Color = .gray
    let startDate: Date?
    let endDate: Date?
    
    init(insightTitle: String, event: EventModel?) {
        self.insightTitle = insightTitle
        self.eventName = event?.eventTitle ?? "No Event Found"
        if let event {
            self.backgroundColor = event.calendarColor
        }
        self.startDate = event?.startDate
        self.endDate = event?.endDate
    }
    
    init(insightTitle: String,
         eventName: String,
         backgroundColor: Color,
         startDate: Date?,
         endDate: Date?) {
        self.insightTitle = insightTitle
        self.eventName = eventName
        self.backgroundColor = backgroundColor
        self.startDate = startDate
        self.endDate = endDate
    }
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        InsightItemContainerView(backgroundColor: backgroundColor) {
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
            insightTitleText
            eventDetailsView
        }
    }
    
    @ViewBuilder
    private var regularHorizontalSizeClassView: some View {
        HStack {
            insightTitleText
            Spacer()
            eventDetailsView
        }
        .padding()
    }
    
    @ViewBuilder
    private var insightTitleText: some View {
        Text(insightTitle)
            .font(.title2)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
    }
    
    @ViewBuilder
    private var eventDetailsView: some View {
        VStack(alignment: .leading) {
            Text(eventName)
                .font(.title3)
                .bold()
            if let eventDateDescription {
                Text(eventDateDescription)
            }
            if let eventTimeDescription {
                Text(eventTimeDescription)
            }
        }
    }
    
    // MARK: - View Model
    
    private var eventDateDescription: String? {
        guard let startDate, let endDate else {
            return nil
        }
        let startDateDescription = DateFormatter.eventDateFormatter.string(from: startDate)
        let endDateDescription = DateFormatter.eventDateFormatter.string(from: endDate)
        if startDateDescription == endDateDescription {
            return startDateDescription
        } else {
            return "\(startDateDescription) - \(endDateDescription)"
        }
    }
    
    private var eventTimeDescription: String? {
        guard let startDate, let endDate else {
            return nil
        }
        let startDateDescription = DateFormatter.eventTimeFormatter.string(from: startDate)
        let endDateDescription = DateFormatter.eventTimeFormatter.string(from: endDate)
        return "\(startDateDescription) - \(endDateDescription)"
    }
    
}
