/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Logic for the app's widget.
*/

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct SwiftUIAccessibilitySampleWidget: Widget {
    let kind: String = "SwiftUIAccessibilitySampleWidget"

    private var gradient: LinearGradient {
        let color = Color.blue
        return .linearGradient(
            Gradient(colors: [color.opacity(0.8), color]),
            startPoint: .top, endPoint: .bottom)
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { _ in
            WidgetView()
                .containerBackground(gradient, for: .widget)
                .modelContainer(for: [Trip.self, Beach.self, Contact.self])
        }
        .configurationDisplayName("SwiftUI Accessibility Sample")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

/// A widget for showing the rating of beaches that have been added through
/// the `BeachesView` interface.
struct WidgetView: View {
    @Query private var beaches: [Beach]
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.scenePhase) private var scenePhase

    /// The beaches for the provided widget family. Includes six entries for large widgets
    /// and three entries for small widgets.
    private var scopedBeaches: [Beach] {
        let count = widgetFamily == .systemLarge ? 6 : 3
        let beaches: [Beach] = if beaches.count > count {
            .init(beaches[0..<count])
        } else {
            beaches
        }
        return beaches.sorted { $0.rating > $1.rating }
    }

    private var tintColor: Color {
        .blue.mix(with: .black, by: 0.5)
    }

    var body: some View {
        VStack {
            let scopedBeaches = self.scopedBeaches
            if scopedBeaches.isEmpty {
                Text("No Beaches Added")
                    .foregroundStyle(.white)
            } else {
                ForEach(scopedBeaches) { beach in
                    BeachView(beach: beach)
                    if scopedBeaches.last?.id != beach.id {
                        Divider()
                            .foregroundStyle(tintColor)
                            .padding(3)
                    }
                }
                Spacer()
            }
        }
        .tint(tintColor)
        .onChange(of: scenePhase) { _beaches.update() }
    }
}

// MARK: Timeline Provider

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date())
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (Entry) -> Void
    ) {
        let entry = Entry(date: Date())
        completion(entry)
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<Entry>) -> Void
    ) {
        let timeline = Timeline(entries: [Entry](), policy: .never)
        completion(timeline)
    }
}

private struct Entry: TimelineEntry {
    let date: Date
}
