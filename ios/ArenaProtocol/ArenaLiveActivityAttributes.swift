import ActivityKit
import SwiftUI

struct ArenaLiveActivityAttributes: ActivityAttributes, Sendable {
    // Static (non-changing) fields
    let arenaId: String
    let arenaLabel: String
    let arenaColor: String
    let arenaIcon: String
    let questNote: String

    static let appGroupID = "group.arena.protocol"

    // Dynamic (changing) state
    struct ContentState: Codable, Hashable, Sendable {
        var endTime: Date
        var isPaused: Bool
        var pausedRemaining: TimeInterval
    }
}
