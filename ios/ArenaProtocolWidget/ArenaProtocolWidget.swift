import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct ArenaEntry: TimelineEntry {
    let date: Date
    let widgetState: WidgetState
}

// MARK: - Timeline Provider
struct ArenaProvider: TimelineProvider {
    func placeholder(in context: Context) -> ArenaEntry {
        ArenaEntry(date: .now, widgetState: WidgetState(
            activeArenaName: "CRAFT",
            activeArenaColor: "#708090",
            timerEndsAt: Date().addingTimeInterval(25 * 60),
            todaySessionCount: 3
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (ArenaEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArenaEntry>) -> Void) {
        let state = SharedStore.readWidgetState()
        let entry = ArenaEntry(date: .now, widgetState: state)
        let refresh = Calendar.current.date(byAdding: .second, value: 60, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - Widget Definition
@main
struct ArenaProtocolWidget: Widget {
    let kind: String = "ArenaProtocolWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArenaProvider()) { entry in
            ArenaWidgetView(entry: entry)
        }
        .configurationDisplayName("Arena Protocol")
        .description("Track your active arena timer.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}
