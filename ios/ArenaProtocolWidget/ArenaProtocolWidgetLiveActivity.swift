//
//  ArenaProtocolWidgetLiveActivity.swift
//  ArenaProtocolWidget
//
//  Created by Baloo on 3/16/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ArenaProtocolWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ArenaProtocolWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ArenaProtocolWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ArenaProtocolWidgetAttributes {
    fileprivate static var preview: ArenaProtocolWidgetAttributes {
        ArenaProtocolWidgetAttributes(name: "World")
    }
}

extension ArenaProtocolWidgetAttributes.ContentState {
    fileprivate static var smiley: ArenaProtocolWidgetAttributes.ContentState {
        ArenaProtocolWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ArenaProtocolWidgetAttributes.ContentState {
         ArenaProtocolWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ArenaProtocolWidgetAttributes.preview) {
   ArenaProtocolWidgetLiveActivity()
} contentStates: {
    ArenaProtocolWidgetAttributes.ContentState.smiley
    ArenaProtocolWidgetAttributes.ContentState.starEyes
}
