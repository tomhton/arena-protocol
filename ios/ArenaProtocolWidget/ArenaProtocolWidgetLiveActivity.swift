import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget

struct ArenaProtocolWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ArenaLiveActivityAttributes.self) { context in
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
            .keylineTint(Color(hex: context.attributes.arenaColor))
        }
    }
}

// MARK: - Lock Screen / Banner

private struct LockScreenBannerView: View {
    let context: ActivityViewContext<ArenaLiveActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.attributes.arenaColor)

        HStack(spacing: 0) {
            // Colored left strip
            Rectangle()
                .fill(arenaColor)
                .frame(width: 6)

            HStack(spacing: 12) {
                // Arena icon
                Text(context.attributes.arenaIcon)
                    .font(.system(size: 22))
                    .foregroundColor(arenaColor)

                VStack(alignment: .leading, spacing: 2) {
                    // Arena label
                    Text(context.attributes.arenaLabel)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(1.5)

                    // Quest note (truncated to one line)
                    if !context.attributes.questNote.isEmpty {
                        Text(context.attributes.questNote)
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
    let context: ActivityViewContext<ArenaLiveActivityAttributes>

    var body: some View {
        Text(context.attributes.arenaIcon)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: context.attributes.arenaColor))
            .frame(width: 20, height: 20)
    }
}

// MARK: - Compact Trailing (Dynamic Island)

private struct CompactTrailingView: View {
    let context: ActivityViewContext<ArenaLiveActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.attributes.arenaColor)

        if context.state.isPaused {
            Text("—")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(arenaColor)
                .fixedSize()
        } else {
            Text(context.state.endTime, style: .timer)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(arenaColor)
                .monospacedDigit()
                .frame(maxWidth: 60)
        }
    }
}

// MARK: - Minimal (Dynamic Island single-app minimal)

private struct MinimalView: View {
    let context: ActivityViewContext<ArenaLiveActivityAttributes>

    var body: some View {
        Text(context.attributes.arenaIcon)
            .font(.system(size: 12))
            .foregroundColor(Color(hex: context.attributes.arenaColor))
    }
}

// MARK: - Expanded Leading

private struct ExpandedLeadingView: View {
    let context: ActivityViewContext<ArenaLiveActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.attributes.arenaColor)

        VStack(alignment: .leading, spacing: 4) {
            Text(context.attributes.arenaIcon)
                .font(.system(size: 20))
                .foregroundColor(arenaColor)
            Text(context.attributes.arenaLabel)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(arenaColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Expanded Trailing

private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<ArenaLiveActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.attributes.arenaColor)

        Group {
            if context.state.isPaused {
                Text("PAUSED")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(arenaColor)
            } else {
                Text(context.state.endTime, style: .timer)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(arenaColor)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Expanded Bottom

private struct ExpandedBottomView: View {
    let context: ActivityViewContext<ArenaLiveActivityAttributes>

    var body: some View {
        if !context.attributes.questNote.isEmpty {
            Text(context.attributes.questNote)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }
}
