//
//  ArenaProtocolWidget.swift
//  ArenaProtocolWidget
//
//  Created by Baloo on 3/16/26.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), widgetState: WidgetState(activeArenaName: nil, activeArenaColor: nil, timerEndsAt: nil, todaySessionCount: 0))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, widgetState: SharedStore.readWidgetState())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let widgetState = SharedStore.readWidgetState()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) ?? currentDate
            let entry = SimpleEntry(date: entryDate, configuration: configuration, widgetState: widgetState)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let widgetState: WidgetState
}

struct ArenaProtocolWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

            Text("Favorite Emoji:")
            Text(entry.configuration.favoriteEmoji)
        }
    }
}

struct ArenaProtocolWidget: Widget {
    let kind: String = "ArenaProtocolWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ArenaProtocolWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    ArenaProtocolWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, widgetState: WidgetState(activeArenaName: nil, activeArenaColor: nil, timerEndsAt: nil, todaySessionCount: 0))
    SimpleEntry(date: .now, configuration: .starEyes, widgetState: WidgetState(activeArenaName: nil, activeArenaColor: nil, timerEndsAt: nil, todaySessionCount: 0))
}
