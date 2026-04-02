#if canImport(ActivityKit)
import ActivityKit
import SwiftUI

struct UpcomingArena: Codable, Hashable, Sendable {
    var id: String
    var label: String
    var icon: String
    var color: String
}

struct ArenaLiveActivityAttributes: ActivityAttributes, Sendable {
    // Static — set once at Activity.request, never changes
    let arenaId: String         // identifies activity type: "idle" | "stuck" | arena id
    let questNote: String
    let startTime: Date         // session start — used for circular progress ring

    static let appGroupID = "group.arena.protocol"

    // Dynamic — updated via Activity.update as the session progresses
    struct ContentState: Codable, Hashable, Sendable {
        var endTime: Date
        var isPaused: Bool
        var pausedRemaining: TimeInterval
        var isIdle: Bool = false        // true = no session, show motivational text
        var isMandatory: Bool = false   // true = post-stuck grace, must pick an arena
        var jointCount: Int = 0         // number of joint arenas queued after primary
        // Arena identity — moves to ContentState so it updates when a joint takes over
        var arenaLabel: String = ""
        var arenaColor: String = "#E8C547"
        var arenaIcon: String = "◉"
        // Per-arena timing — endTime is the current arena's end, sessionEndTime is the total session end
        var currentArenaStart: Date = Date()   // current arena's start — for progress ring
        var sessionEndTime: Date = Date()      // total session end including all joints
        var nextArenaLabel: String = ""        // "" if no next arena
        var nextArenaIcon: String = ""
        var upcomingArenas: [UpcomingArena] = []
    }
}
#endif
