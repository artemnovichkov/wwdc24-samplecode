/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Models representing one or more insights.
*/

import Foundation
import SwiftUI

enum InsightDateInterval {
    case none
    case daily
    case weekly
    case monthly
    
    var displayName: String? {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        default:
            return nil
        }
    }
}

enum InsightType {
    case workLifeBalanceScore
    case calendarQualityScore
    case mostMeaningfulEvent
    case mostBoringEvent
    case proudestMoment
    
    var displayName: String {
        switch self {
        case .workLifeBalanceScore:
            return "Work-Life Balance"
        case .calendarQualityScore:
            return "Calendar Quality"
        case .mostMeaningfulEvent:
            return "Most Meaningful Event"
        case .mostBoringEvent:
            return "Most Boring Event"
        case .proudestMoment:
            return "Proudest Moment"
        }
    }
}

struct InsightModel: Identifiable {
    let id = UUID()
    let insightType: InsightType
    var dateInterval: InsightDateInterval = .none
    var color: Color = .gray
}

enum InsightSectionType {
    case weeklyScores
    case eventHighlights
    
    var displayName: String {
        switch self {
        case .weeklyScores:
            return "Weekly Scores"
        case .eventHighlights:
            return "Event Highlights"
        }
    }
}

struct InsightSection: Identifiable {
    let id = UUID()
    let sectionType: InsightSectionType
    let insights: [InsightModel]
}
