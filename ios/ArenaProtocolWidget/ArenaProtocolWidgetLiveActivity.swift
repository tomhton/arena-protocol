//
//  ArenaProtocolWidgetLiveActivity.swift
//  ArenaProtocolWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Color hex initialiser (inlined — widget target cannot reach RootView.swift's extension)

private extension Color {
    init(_ hex: String) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >>  8) & 0xFF) / 255.0,
            blue:  Double( rgb        & 0xFF) / 255.0
        )
    }
}

// MARK: - Live Activity

struct ArenaProtocolWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ArenaLiveActivityAttributes.self) { context in

            // MARK: Lock Screen / Banner
            let arenaColor = Color(context.attributes.arenaColor)
            HStack(spacing: 0) {
                // Arena-colour left border accent
                Rectangle()
                    .fill(arenaColor)
                    .frame(width: 3)

                HStack(spacing: 10) {
                    Text(context.attributes.arenaIcon)
                        .font(.system(size: 22))
                        .foregroundStyle(arenaColor)

                    Text(context.attributes.arenaLabel)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    if context.state.isPaused {
                        Text("PAUSED")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(arenaColor)
                    } else {
                        Text(context.state.endTime, style: .timer)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(arenaColor)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(Color.black.opacity(0.8))

        } dynamicIsland: { context in
            let arenaColor = Color(context.attributes.arenaColor)

            DynamicIsland {
                // MARK: Expanded — Top: arena label
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.arenaLabel)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(arenaColor)
                }

                // MARK: Expanded — Middle: quest note
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.questNote)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // MARK: Expanded — Bottom: countdown or PAUSED
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isPaused {
                        Text("PAUSED")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(arenaColor)
                    } else {
                        Text(context.state.endTime, style: .timer)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(arenaColor)
                            .monospacedDigit()
                    }
                }

            } compactLeading: {
                // MARK: Compact Leading — arena icon in arena colour
                Text(context.attributes.arenaIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(arenaColor)

            } compactTrailing: {
                // MARK: Compact Trailing — countdown or "PAUSED" in small caps
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(arenaColor)
                } else {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(arenaColor)
                        .monospacedDigit()
                }

            } minimal: {
                // MARK: Minimal — icon only in arena colour
                Text(context.attributes.arenaIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(arenaColor)
            }
        }
    }
}

// MARK: - Preview helpers

extension ArenaLiveActivityAttributes {
    fileprivate static var preview: ArenaLiveActivityAttributes {
        ArenaLiveActivityAttributes(
            arenaId: "craft",
            arenaLabel: "CRAFT",
            arenaColor: "#708090",
            arenaIcon: "△",
            questNote: "Write 200 words on the new feature proposal"
        )
    }
}

extension ArenaLiveActivityAttributes.ContentState {
    fileprivate static var active: ArenaLiveActivityAttributes.ContentState {
        ArenaLiveActivityAttributes.ContentState(
            endTime: Date.now.addingTimeInterval(25 * 60),
            isPaused: false,
            pausedRemaining: 0
        )
    }

    fileprivate static var paused: ArenaLiveActivityAttributes.ContentState {
        ArenaLiveActivityAttributes.ContentState(
            endTime: Date.now.addingTimeInterval(12 * 60),
            isPaused: true,
            pausedRemaining: 12 * 60
        )
    }
}

// MARK: - Previews

#Preview("Active — Lock Screen", as: .content, using: ArenaLiveActivityAttributes.preview) {
    ArenaProtocolWidgetLiveActivity()
} contentStates: {
    ArenaLiveActivityAttributes.ContentState.active
}

#Preview("Paused — Lock Screen", as: .content, using: ArenaLiveActivityAttributes.preview) {
    ArenaProtocolWidgetLiveActivity()
} contentStates: {
    ArenaLiveActivityAttributes.ContentState.paused
}

#Preview("Active — Expanded Island", as: .dynamicIsland(.expanded), using: ArenaLiveActivityAttributes.preview) {
    ArenaProtocolWidgetLiveActivity()
} contentStates: {
    ArenaLiveActivityAttributes.ContentState.active
}

#Preview("Paused — Expanded Island", as: .dynamicIsland(.expanded), using: ArenaLiveActivityAttributes.preview) {
    ArenaProtocolWidgetLiveActivity()
} contentStates: {
    ArenaLiveActivityAttributes.ContentState.paused
}
