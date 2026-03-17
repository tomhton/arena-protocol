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
                CompactLeadingView(context: context)
            } compactTrailing: {
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
                .frame(width: 4)

            HStack(spacing: 12) {
                // Circular progress clock with icon inside
                if context.state.isPaused {
                    ZStack {
                        Circle()
                            .stroke(arenaColor.opacity(0.25), lineWidth: 2)
                            .frame(width: 40, height: 40)
                        Text(context.attributes.arenaIcon)
                            .font(.system(size: 18))
                            .foregroundColor(arenaColor.opacity(0.5))
                    }
                } else {
                    ProgressView(
                        timerInterval: context.attributes.startTime...context.state.endTime,
                        countsDown: true
                    ) {
                        EmptyView()
                    } currentValueLabel: {
                        Text(context.attributes.arenaIcon)
                            .font(.system(size: 16))
                            .foregroundColor(arenaColor)
                    }
                    .progressViewStyle(.circular)
                    .tint(arenaColor)
                    .frame(width: 40, height: 40)
                }

                // Text block
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.arenaLabel)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(1.5)

                    if !context.attributes.questNote.isEmpty {
                        Text(context.attributes.questNote)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Timer or PAUSED
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(arenaColor.opacity(0.6))
                } else {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(arenaColor)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 56, alignment: .trailing)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color(red: 0.031, green: 0.031, blue: 0.063))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Compact Leading (Dynamic Island)
// Circular progress ring with arena icon — updates continuously like .timer Text

private struct CompactLeadingView: View {
    let context: ActivityViewContext<ArenaLiveActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.attributes.arenaColor)

        if context.state.isPaused {
            ZStack {
                Circle()
                    .stroke(arenaColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 22, height: 22)
                Text("II")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(arenaColor.opacity(0.6))
            }
        } else {
            ProgressView(
                timerInterval: context.attributes.startTime...context.state.endTime,
                countsDown: true
            ) {
                EmptyView()
            } currentValueLabel: {
                Text(context.state.endTime, style: .timer)
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundColor(arenaColor)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
            }
            .progressViewStyle(.circular)
            .tint(arenaColor)
            .frame(width: 22, height: 22)
        }
    }
}

// MARK: - Compact Trailing (Dynamic Island)

private struct CompactTrailingView: View {
    let context: ActivityViewContext<ArenaLiveActivityAttributes>

    var body: some View {
        let arenaColor = Color(hex: context.attributes.arenaColor)

        if context.state.isPaused {
            Text("PAUSED")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(arenaColor.opacity(0.7))
                .fixedSize()
        } else {
            Text(context.state.endTime, style: .timer)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
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
        let arenaColor = Color(hex: context.attributes.arenaColor)

        ProgressView(
            timerInterval: context.attributes.startTime...context.state.endTime,
            countsDown: true
        ) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.circular)
        .tint(arenaColor)
        .frame(width: 16, height: 16)
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

// Color(hex:) is defined in ArenaWidgetView.swift for the widget extension scope.
