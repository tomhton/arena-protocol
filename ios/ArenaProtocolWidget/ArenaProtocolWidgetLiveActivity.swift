import ActivityKit
import SwiftUI
import WidgetKit


struct ArenaProtocolWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ArenaLiveActivityAttributes.self) { context in
            // DEBUG: most aggressive visibility test — if this is not visible the
            // closure itself is not executing (stale extension binary).
            Text("ALIVE")
                .foregroundColor(.red)
                .background(Color.yellow)
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
                Text("X")
                    .foregroundColor(.red)
            } compactTrailing: {
                Text("TEST")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } minimal: {
                Text(context.attributes.arenaIcon)
                    .font(.system(size: 14))
                    .foregroundColor(arenaColor)
            }
        }
    }
}
