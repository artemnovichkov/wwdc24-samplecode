/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows insights on a person's calendar events.
*/

import EventKit
import HealthKit
import SwiftUI

struct InsightsGridView: View {
    
    let calendars: Calendars
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    private let dataFetcher = InsightsDataFetcher()
    
    let insightSections: [InsightSection] = [
        .init(sectionType: .weeklyScores, insights: [
            .init(insightType: .workLifeBalanceScore,
                  dateInterval: .weekly,
                  color: .mint),
            .init(insightType: .calendarQualityScore,
                  dateInterval: .weekly,
                  color: .cyan)
        ]),
        .init(sectionType: .eventHighlights, insights: [
            .init(insightType: .mostMeaningfulEvent),
            .init(insightType: .mostBoringEvent),
            .init(insightType: .proudestMoment)
        ])
    ]
    
    @State private var weeklyWorkLifeBalanceScore: Int?
    @State private var weeklyCalendarQualityScore: Int?
    
    @State private var mostMeaningfulEvent: EventModel?
    @State private var mostBoringEvent: EventModel?
    @State private var proudestEvent: EventModel?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            ForEach(insightSections) { section in
                InsightSectionView(sectionTitle: section.sectionType.displayName) {
                    LazyVGrid(columns: gridColumns(for: section.insights)) {
                        ForEach(section.insights) { insight in
                            insightView(for: insight)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            Task {
                try await calculateMetrics()
            }
        }
    }
    
    private func gridColumns<Content>(for dataSource: [Content]) -> [GridItem] {
        guard dataSource.count > 1 else {
            return [GridItem(.flexible())]
        }
        switch horizontalSizeClass {
        case .regular:
            return [GridItem(.flexible()), GridItem(.flexible())]
        default:
            return [GridItem(.flexible())]
        }
    }
    
    @ViewBuilder
    private func insightView(for insightModel: InsightModel) -> some View {
        switch insightModel.dateInterval {
        case .none:
            generalInsightView(for: insightModel)
        case .weekly:
            weeklyInsightView(for: insightModel)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func generalInsightView(for insightModel: InsightModel) -> some View {
        switch insightModel.insightType {
        case .mostMeaningfulEvent:
            InsightEventView(insightTitle: insightModel.insightType.displayName,
                             event: mostMeaningfulEvent)
        case .mostBoringEvent:
            InsightEventView(insightTitle: insightModel.insightType.displayName,
                             event: mostBoringEvent)
        case .proudestMoment:
            InsightEventView(insightTitle: insightModel.insightType.displayName,
                             event: proudestEvent)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func weeklyInsightView(for insightModel: InsightModel) -> some View {
        switch insightModel.insightType {
        case .workLifeBalanceScore:
            if let weeklyWorkLifeBalanceScore {
                InsightCalendarScoreView(insight: insightModel,
                                         score: weeklyWorkLifeBalanceScore)
            }
        case .calendarQualityScore:
            if let weeklyCalendarQualityScore {
                InsightCalendarScoreView(insight: insightModel,
                                         score: weeklyCalendarQualityScore)
            }
        default:
            EmptyView()
        }
    }
    
    private func calculateMetrics() async throws {
        // Weekly scores
        weeklyWorkLifeBalanceScore = await WorkLifeBalanceScoreProvider.calculateWorkLifeBalanceScore(
            from: calendars,
            numberOfDays: 7
        )
        weeklyCalendarQualityScore = try await CalendarQualityScoreProvider.calendarQualityScore(
            forNumberOfDays: 7,
            associations: [.work],
            healthStore: healthStore
        )
        
        // Event highlights
        mostMeaningfulEvent = try await dataFetcher.event(matching: .happy,
                                                          calendarModels: calendars.calendarModels,
                                                          dateInterval: .eventHighlightInterval)
        mostBoringEvent = try await dataFetcher.event(matching: .indifferent,
                                                      calendarModels: calendars.calendarModels,
                                                      dateInterval: .eventHighlightInterval)
        proudestEvent = try await dataFetcher.event(matching: .proud,
                                                    calendarModels: calendars.calendarModels,
                                                    dateInterval: .eventHighlightInterval)
    }
    
}
