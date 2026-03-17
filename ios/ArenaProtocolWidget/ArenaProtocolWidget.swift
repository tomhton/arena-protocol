import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(),
                    widgetState: WidgetState(activeArenaName: "SPIRIT", activeArenaColor: "#D4A017",
                                             timerEndsAt: Date().addingTimeInterval(1500), todaySessionCount: 3))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, widgetState: SharedStore.readWidgetState())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let state = SharedStore.readWidgetState()
        let now = Date()

        // Refresh every minute while active, every 15 minutes when idle
        let refreshDate: Date
        if let endsAt = state.timerEndsAt, endsAt > now {
            refreshDate = min(endsAt, now.addingTimeInterval(60))
        } else {
            refreshDate = now.addingTimeInterval(900)
        }

        let entry = SimpleEntry(date: now, configuration: configuration, widgetState: state)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let widgetState: WidgetState
}

// MARK: - Widget Entry View

struct ArenaProtocolWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(state: entry.widgetState)
        case .systemMedium: MediumWidgetView(state: entry.widgetState)
        default:            SmallWidgetView(state: entry.widgetState)
        }
    }
}

// MARK: - Small Widget

private struct SmallWidgetView: View {
    let state: WidgetState

    private var arenaColor: Color {
        Color(hex: state.activeArenaColor ?? "#E8C547")
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Color(red: 0.031, green: 0.031, blue: 0.063)

            // Color accent bar (top)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(arenaColor.opacity(0.85))
                    .frame(height: 3)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                // App identifier
                Text("ARENA")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(3)
                    .padding(.top, 10)

                Spacer()

                if let name = state.activeArenaName, let endsAt = state.timerEndsAt, endsAt > Date() {
                    // Active session state
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(arenaColor)
                            .kerning(2)
                            .lineLimit(1)

                        Text(endsAt, style: .timer)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Text("remaining")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .kerning(1)
                    }
                } else {
                    // Idle state
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(state.todaySessionCount)")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(arenaColor)

                        Text(state.todaySessionCount == 1 ? "SESSION\nTODAY" : "SESSIONS\nTODAY")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .kerning(1)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .widgetURL(URL(string: state.activeArenaName != nil ? "arenaprotocol://active" : "arenaprotocol://"))
    }
}

// MARK: - Medium Widget

private struct MediumWidgetView: View {
    let state: WidgetState

    private var arenaColor: Color {
        Color(hex: state.activeArenaColor ?? "#E8C547")
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.031, green: 0.031, blue: 0.063)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(arenaColor.opacity(0.85))
                    .frame(height: 3)
                Spacer()
            }

            HStack(alignment: .center, spacing: 0) {
                // Left: branding + session info
                VStack(alignment: .leading, spacing: 6) {
                    Text("ARENA PROTOCOL")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(3)
                        .padding(.top, 10)

                    Spacer()

                    if let name = state.activeArenaName {
                        Text(name)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(arenaColor)
                            .kerning(2)
                        Text("IN PROGRESS")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .kerning(2)
                    } else {
                        Text("\(state.todaySessionCount) SESSION\(state.todaySessionCount != 1 ? "S" : "")")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(arenaColor)
                            .kerning(2)
                        Text("TODAY")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .kerning(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // Right: timer or tap prompt
                VStack(alignment: .trailing, spacing: 4) {
                    if let endsAt = state.timerEndsAt, endsAt > Date() {
                        Text(endsAt, style: .timer)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                        Text("left")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .kerning(2)
                    } else {
                        Text("START")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(arenaColor)
                            .kerning(4)
                        Text("SESSION →")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(arenaColor.opacity(0.6))
                            .kerning(2)
                    }
                }
                .frame(width: 110, alignment: .trailing)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .padding(.top, 10)
            }
        }
        .widgetURL(URL(string: state.activeArenaName != nil ? "arenaprotocol://active" : "arenaprotocol://"))
    }
}

// MARK: - Widget Configuration

struct ArenaProtocolWidget: Widget {
    let kind: String = "ArenaProtocolWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ArenaProtocolWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.031, green: 0.031, blue: 0.063), for: .widget)
        }
        .configurationDisplayName("Arena Protocol")
        .description("Live focus timer and daily session count.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Color(hex:) is defined in ArenaWidgetView.swift for the widget extension scope.
