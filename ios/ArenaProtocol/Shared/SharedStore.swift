// SharedStore.swift — Arena Protocol
// Shared data bridge between the main app and the WidgetKit extension.
// Uses an App Group suite so both targets can read and write the same defaults.
// The widget target imports only this file — it never touches DataStore.

import Foundation

// MARK: - WidgetState

struct WidgetState: Codable {
    var activeArenaName: String?
    var activeArenaColor: String?   // hex, e.g. "#C0392B"
    var timerEndsAt: Date?
    var todaySessionCount: Int
}

// MARK: - SharedStore

final class SharedStore {

    private static let suiteName  = "group.com.arenaprotocol.app"
    private static let widgetKey  = "arena_widget_state"
    private static let sessionsKey = "arena_sessions"   // same key DataStore uses

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: Write — called by the main app when a session starts

    static func writeActiveSession(arenaName: String, arenaColor: String, endsAt: Date) {
        let state = WidgetState(
            activeArenaName: arenaName,
            activeArenaColor: arenaColor,
            timerEndsAt: endsAt,
            todaySessionCount: todayCount()
        )
        save(state)
    }

    // MARK: Clear — called by the main app when a session ends or is abandoned

    static func clearActiveSession() {
        let state = WidgetState(
            activeArenaName: nil,
            activeArenaColor: nil,
            timerEndsAt: nil,
            todaySessionCount: todayCount()
        )
        save(state)
    }

    // MARK: Read — called by the widget timeline provider

    static func readWidgetState() -> WidgetState {
        guard
            let data  = defaults.data(forKey: widgetKey),
            let state = try? JSONDecoder().decode(WidgetState.self, from: data)
        else {
            return WidgetState(activeArenaName: nil, activeArenaColor: nil,
                               timerEndsAt: nil, todaySessionCount: 0)
        }
        return state
    }

    // MARK: Private helpers

    private static func save(_ state: WidgetState) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: widgetKey)
        }
    }

    /// Reads arena_sessions from the App Group suite and counts today's entries.
    /// Mirrors DataStore's encoding exactly (JSONEncoder, same key).
    private static func todayCount() -> Int {
        // Session is a simple Codable struct — replicated minimally here so the
        // widget target never needs to import DataStore.
        struct _Session: Decodable { var date: String }

        let today = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()

        guard
            let data     = defaults.data(forKey: sessionsKey),
            let sessions = try? JSONDecoder().decode([_Session].self, from: data)
        else { return 0 }

        return sessions.filter { $0.date == today }.count
    }
}
