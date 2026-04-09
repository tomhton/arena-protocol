import Foundation

// MARK: - WidgetState
struct WidgetState: Codable {
    var activeArenaName: String?
    var activeArenaColor: String?   // hex e.g. "#C0392B"
    var timerEndsAt: Date?
    var todaySessionCount: Int
}

// Lightweight arena stub for widget/intent targets
struct SharedArena: Codable {
    var id: String
    var label: String
    var icon: String
    var color: String
}

// Pending intent written by Shortcuts, consumed by app on launch
struct PendingArenaIntent: Codable {
    var arenaId: String
    var duration: Int
    var note: String
}

// MARK: - SharedStore
final class SharedStore {
    private static let suiteName = "group.arena.protocol"
    private static let widgetStateKey = "arena_widget_state"
    private static let sessionsKey = "arena_sessions"
    private static let arenasKey = "arena_shared_arenas"
    private static let pendingIntentKey = "arena_pending_intent"
    private static let pendingTaskKey = "arena_pending_task"

    private static var suite: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // Count today's sessions from App Group defaults
    private static func todayCount() -> Int {
        guard let data = suite.data(forKey: sessionsKey),
              let sessions = try? JSONDecoder().decode([SessionStub].self, from: data)
        else { return 0 }
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return sessions.filter { $0.date == today }.count
    }

    static func writeActiveSession(arenaName: String, arenaColor: String, endsAt: Date) {
        let state = WidgetState(
            activeArenaName: arenaName,
            activeArenaColor: arenaColor,
            timerEndsAt: endsAt,
            todaySessionCount: todayCount()
        )
        if let data = try? JSONEncoder().encode(state) {
            suite.set(data, forKey: widgetStateKey)
        }
    }

    static func clearActiveSession() {
        let state = WidgetState(
            activeArenaName: nil,
            activeArenaColor: nil,
            timerEndsAt: nil,
            todaySessionCount: todayCount()
        )
        if let data = try? JSONEncoder().encode(state) {
            suite.set(data, forKey: widgetStateKey)
        }
    }

    static func readWidgetState() -> WidgetState {
        guard let data = suite.data(forKey: widgetStateKey),
              let state = try? JSONDecoder().decode(WidgetState.self, from: data)
        else {
            return WidgetState(activeArenaName: nil, activeArenaColor: nil,
                               timerEndsAt: nil, todaySessionCount: 0)
        }
        return state
    }

    // MARK: - Arena List (for App Intents + Control Center widget)

    static func writeArenas(_ arenas: [SharedArena]) {
        if let data = try? JSONEncoder().encode(arenas) {
            suite.set(data, forKey: arenasKey)
        }
    }

    static func readArenas() -> [SharedArena] {
        guard let data = suite.data(forKey: arenasKey),
              let arenas = try? JSONDecoder().decode([SharedArena].self, from: data)
        else { return [] }
        return arenas
    }

    // MARK: - Pending Intent (Shortcuts → App)

    static func writePendingIntent(arenaId: String, duration: Int, note: String) {
        let intent = PendingArenaIntent(arenaId: arenaId, duration: duration, note: note)
        if let data = try? JSONEncoder().encode(intent) {
            suite.set(data, forKey: pendingIntentKey)
        }
    }

    static func readPendingIntent() -> PendingArenaIntent? {
        guard let data = suite.data(forKey: pendingIntentKey),
              let intent = try? JSONDecoder().decode(PendingArenaIntent.self, from: data)
        else { return nil }
        return intent
    }

    static func clearPendingIntent() {
        suite.removeObject(forKey: pendingIntentKey)
    }

    // MARK: - Pending Checklist Task (Shortcuts → App)

    static func writePendingChecklistTask(_ text: String) {
        suite.set(text, forKey: pendingTaskKey)
    }

    static func readPendingChecklistTask() -> String? {
        suite.string(forKey: pendingTaskKey)
    }

    static func clearPendingChecklistTask() {
        suite.removeObject(forKey: pendingTaskKey)
    }
}

// Minimal stub so the widget target can decode session count
// without importing DataStore
private struct SessionStub: Codable {
    let date: String   // yyyy-MM-dd
}
