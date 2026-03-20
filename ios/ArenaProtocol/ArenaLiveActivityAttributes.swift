import ActivityKit
import SwiftUI

struct ArenaLiveActivityAttributes: ActivityAttributes, Sendable {
    // Static (non-changing) fields
    let arenaId: String
    let arenaLabel: String
    let arenaColor: String
    let arenaIcon: String
    let questNote: String
    let startTime: Date          // session start — used for circular progress ring

    static let appGroupID = "group.arena.protocol"

    // Dynamic (changing) state
    struct ContentState: Codable, Hashable, Sendable {
        var endTime: Date
        var isPaused: Bool
        var pausedRemaining: TimeInterval
        var isIdle: Bool = false        // true = no session, show motivational text
        var isMandatory: Bool = false   // true = post-stuck grace, must pick an arena
        var jointCount: Int = 0         // number of joint arenas queued after primary
    }
}
