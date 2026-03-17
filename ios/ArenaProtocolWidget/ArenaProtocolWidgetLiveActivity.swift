import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Attributes

struct ArenaActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var arenaLabel: String
        var arenaColor: String   // hex string e.g. "#C0392B"
        var arenaIcon: String    // single unicode char e.g. "◉"
        var questNote: String
        var endTime: Date
        var isPaused: Bool
        var pausedRemaining: TimeInterval  // seconds remaining when paused
    }

    var arenaId: String
}

// MARK: - Live Activity Widget

struct ArenaProtocolWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ArenaActivityAttributes.self) { context in
            // ── Lock Screen / Banner ──────────────────────────────────────────
            LockScreenBannerView(context: context)
                .widgetURL(URL(string: "arenaprotocol://active"))

        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded (long-press) ─────────────────────────────────────
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                // ── Compact Leading: arena icon in arena color ────────────────
                CompactLeadingView(context: context)
            } compactTrailing: {
                // ── Compact Trailing: countdown timer or PAUSED ───────────────
                CompactTrailingView(context: context)
            } minimal: {
                MinimalView(context: context)
            }
            .widgetURL(URL(string: "arenaprotocol://active"))
            .keylineTint(Color(hex: context.state.arenaColor))
        }
    }
}

// MARK: - Lock Screen / Banner

private struct LockScreenBannerView: View {
    let context: ActivityViewContext<ArenaActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.state.arenaColor)

        HStack(spacing: 0) {
            // Colored left strip
            Rectangle()
                .fill(arenaColor)
                .frame(width: 6)

            HStack(spacing: 12) {
                // Arena icon
                Text(context.state.arenaIcon)
                    .font(.system(size: 22))
                    .foregroundColor(arenaColor)

                VStack(alignment: .leading, spacing: 2) {
                    // Arena label
                    Text(context.state.arenaLabel)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(1.5)

                    // Quest note (truncated to one line)
                    if !context.state.questNote.isEmpty {
                        Text(context.state.questNote)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Timer or PAUSED
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(arenaColor)
                } else {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(arenaColor)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color(red: 0.031, green: 0.031, blue: 0.063))  // #080810
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Compact Leading (Dynamic Island)

private struct CompactLeadingView: View {
    let context: ActivityViewContext<ArenaActivityAttributes>

    var body: some View {
        Text(context.state.arenaIcon)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: context.state.arenaColor))
            .padding(.leading, 4)
    }
}

// MARK: - Compact Trailing (Dynamic Island)

private struct CompactTrailingView: View {
    let context: ActivityViewContext<ArenaActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.state.arenaColor)

        if context.state.isPaused {
            Text("—")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(arenaColor)
                .padding(.trailing, 4)
        } else {
            Text(context.state.endTime, style: .timer)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(arenaColor)
                .monospacedDigit()
                .padding(.trailing, 4)
        }
    }
}

// MARK: - Minimal (Dynamic Island single-app minimal)

private struct MinimalView: View {
    let context: ActivityViewContext<ArenaActivityAttributes>

    var body: some View {
        Text(context.state.arenaIcon)
            .font(.system(size: 12))
            .foregroundColor(Color(hex: context.state.arenaColor))
    }
}

// MARK: - Expanded Leading

private struct ExpandedLeadingView: View {
    let context: ActivityViewContext<ArenaActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.state.arenaColor)

        VStack(alignment: .leading, spacing: 4) {
            Text(context.state.arenaIcon)
                .font(.system(size: 28))
                .foregroundColor(arenaColor)
            Text(context.state.arenaLabel)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(arenaColor)
                .tracking(1.2)
        }
        .padding(.leading, 4)
    }
}

// MARK: - Expanded Trailing

private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<ArenaActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.state.arenaColor)

        VStack(alignment: .trailing, spacing: 4) {
            if context.state.isPaused {
                Text("PAUSED")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(arenaColor)
            } else {
                Text(context.state.endTime, style: .timer)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(arenaColor)
                    .monospacedDigit()
            }
        }
        .padding(.trailing, 4)
    }
}

// MARK: - Expanded Bottom

private struct ExpandedBottomView: View {
    let context: ActivityViewContext<ArenaActivityAttributes>

    var body: some View {
        if !context.state.questNote.isEmpty {
            Text(context.state.questNote)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
        }
    }
}

// MARK: - Color(hex:) helper (widget extension scope)
// Duplicated here because widget extensions don't share the main app module.

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >>  8) & 0xFF) / 255
            b = Double( int        & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
