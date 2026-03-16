import Foundation

// MARK: - WidgetState
struct WidgetState: Codable {
    var activeArenaName: String?
    var activeArenaColor: String?   // hex e.g. "#C0392B"
    var timerEndsAt: Date?
    var todaySessionCount: Int
}

// MARK: - SharedStore
final class SharedStore {
    private static let suiteName = "group.com.arenaprotocol.app"
    private static let widgetStateKey = "arena_widget_state"
    private static let sessionsKey = "arena_sessions"

    private static var suite: UserDefaults {
        UserDefaults(suiteName: suiteName)!
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
}

// Minimal stub so the widget target can decode session count
// without importing DataStore
private struct SessionStub: Codable {
    let date: String   // yyyy-MM-dd
}
