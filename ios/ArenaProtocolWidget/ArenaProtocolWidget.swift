// ArenaProtocolWidget.swift — Arena Protocol
// Widget entry point, timeline entry, and timeline provider.
// This file belongs to the ArenaProtocolWidget extension target only.
// It never imports DataStore — all state comes through SharedStore.

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
        ArenaEntry(date: Date(), widgetState: placeholderState)
    }

    func getSnapshot(in context: Context, completion: @escaping (ArenaEntry) -> Void) {
        completion(ArenaEntry(date: Date(), widgetState: placeholderState))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArenaEntry>) -> Void) {
        let state  = SharedStore.readWidgetState()
        let entry  = ArenaEntry(date: Date(), widgetState: state)
        // Refresh every 60 seconds so the countdown stays reasonably accurate.
        let next   = Calendar.current.date(byAdding: .second, value: 60, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }

    // Snapshot placeholder: CRAFT arena, 25-minute session
    private var placeholderState: WidgetState {
        WidgetState(
            activeArenaName: "CRAFT",
            activeArenaColor: "#708090",
            timerEndsAt: Date().addingTimeInterval(25 * 60),
            todaySessionCount: 3
        )
    }
}

// MARK: - Widget Definition

@main
struct ArenaProtocolWidget: Widget {
    let kind = "ArenaProtocolWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArenaProvider()) { entry in
            ArenaWidgetView(entry: entry)
        }
        .configurationDisplayName("Arena Protocol")
        .description("Shows your active focus session and today's count.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}
