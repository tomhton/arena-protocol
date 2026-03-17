import ActivityKit
import SwiftUI
import WidgetKit


struct ArenaProtocolWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ArenaLiveActivityAttributes.self) { context in
            // Lock screen / StandBy banner
            let arenaColor = Color(hex: context.attributes.arenaColor)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(arenaColor)
                    .frame(width: 3)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.arenaIcon + " " + context.attributes.arenaLabel)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(arenaColor)
                        Text(context.attributes.questNote)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                    Spacer()
                    if context.state.isPaused {
                        Text("PAUSED")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(arenaColor)
                    } else {
                        Text(context.state.endTime, style: .timer)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(arenaColor)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black)
        } dynamicIsland: { context in
            let arenaColor = Color(hex: context.attributes.arenaColor)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.arenaIcon)
                        .font(.system(size: 28))
                        .foregroundColor(arenaColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text("PAUSED")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(arenaColor)
                    } else {
                        Text(context.state.endTime, style: .timer)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(arenaColor)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.questNote)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.arenaLabel)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(arenaColor)
                        .widgetURL(URL(string: "arenaprotocol://active")!)
                }
            } compactLeading: {
                Text(context.attributes.arenaIcon)
                    .font(.system(size: 16))
                    .foregroundColor(arenaColor)
            } compactTrailing: {
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(arenaColor)
                } else {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(arenaColor)
                        .monospacedDigit()
                }
            } minimal: {
                Text(context.attributes.arenaIcon)
                    .font(.system(size: 14))
                    .foregroundColor(arenaColor)
            }
        }
    }
}
