// CalendarSyncManager.swift — Arena Protocol
// Polls EventKit for bracket-prefixed events (e.g. "[WORK] Deep focus")
// and schedules notifications + auto-start prompts at their start times.

import EventKit
import UserNotifications
import SwiftUI

// MARK: - Pending Calendar Session

struct PendingCalSession: Identifiable, Equatable {
    let id: String          // EKEvent.eventIdentifier
    let arena: Arena
    let startTime: Date
    let durationMins: Int
    let note: String        // event title with bracket prefix stripped

    static func == (lhs: PendingCalSession, rhs: PendingCalSession) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CalendarSyncManager

@MainActor
final class CalendarSyncManager {
    static let shared = CalendarSyncManager()

    /// Event identifiers already processed (started or dismissed). Persisted to UserDefaults.
    private var processedIds: Set<String> {
        didSet { saveProcessedIds() }
    }

    private let processedKey = "arena_cal_synced_events"

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: "arena_cal_synced_events") ?? []
        processedIds = Set(saved)
    }

    private func saveProcessedIds() {
        UserDefaults.standard.set(Array(processedIds), forKey: processedKey)
    }

    // MARK: - Sync

    /// Scan upcoming calendar events for bracket-prefixed arena matches.
    /// Schedules notifications for future events and returns all pending sessions.
    func syncBracketEvents(arenas: [Arena], socialArena: Arena? = nil) -> [PendingCalSession] {
        let cal = CalendarManager.shared
        guard cal.isReadAuthorized else { return [] }

        let allArenas = socialArena.map { arenas + [$0] } ?? arenas
        // Look 8 hours ahead plus events that started within last 5 minutes
        let upcoming = cal.upcomingEvents(hours: 8)
        let recentStart = Date().addingTimeInterval(-5 * 60)
        let active = cal.activeEvents().filter { $0.startDate >= recentStart }
        let events = (active + upcoming).uniqued(by: \.eventIdentifier)

        var pending: [PendingCalSession] = []

        for event in events {
            guard let arena = cal.matchBracketArena(for: event, arenas: allArenas) else { continue }
            let eventId = event.eventIdentifier ?? ""
            guard !eventId.isEmpty, !processedIds.contains(eventId) else { continue }

            let duration = max(1, Int(event.endDate.timeIntervalSince(event.startDate) / 60))
            let note = cal.stripBracketPrefix(event.title ?? "", arena: arena)

            let session = PendingCalSession(
                id: eventId,
                arena: arena,
                startTime: event.startDate,
                durationMins: duration,
                note: note
            )
            pending.append(session)

            // Schedule notification for future events
            let secsFromNow = event.startDate.timeIntervalSinceNow
            if secsFromNow > 5 {
                scheduleCalSessionNotification(session: session, secondsFromNow: secsFromNow)
            }
        }

        return pending.sorted { $0.startTime < $1.startTime }
    }

    /// Find a pending session that's ready to start right now (within the last 90 seconds).
    func readySession(from pending: [PendingCalSession]) -> PendingCalSession? {
        let now = Date()
        return pending.first { session in
            let diff = now.timeIntervalSince(session.startTime)
            return diff >= -5 && diff <= 90  // just arrived or up to 90s ago
        }
    }

    // MARK: - Mark Processed

    func markProcessed(_ eventId: String) {
        processedIds.insert(eventId)
    }

    func isProcessed(_ eventId: String) -> Bool {
        processedIds.contains(eventId)
    }

    /// Remove entries older than 24 hours to prevent unbounded growth.
    func cleanupOldEntries() {
        // We can't check event dates from IDs alone, so just cap the set size.
        // Old entries become harmless once the event passes.
        if processedIds.count > 200 {
            // Keep the most recently added ~100 entries (Set is unordered, but this prevents growth)
            let arr = Array(processedIds)
            processedIds = Set(arr.suffix(100))
        }
    }

    // MARK: - Notification

    private func scheduleCalSessionNotification(session: PendingCalSession, secondsFromNow: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "\(session.arena.icon) \(session.arena.label) starting now"
        content.body = session.note.isEmpty
            ? "Calendar block — \(session.durationMins)m"
            : "\(session.note) — \(session.durationMins)m"
        content.sound = .default
        content.categoryIdentifier = "CALENDAR_SESSION"
        content.userInfo = [
            "arenaId": session.arena.id,
            "durationMins": session.durationMins,
            "note": session.note,
            "eventId": session.id
        ]

        let notifId = "cal_session_\(session.id)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsFromNow, repeats: false)
        let request = UNNotificationRequest(identifier: notifId, content: content, trigger: trigger)

        // Replace any existing notification for this event
        center.removePendingNotificationRequests(withIdentifiers: [notifId])
        center.add(request)
    }
}

// MARK: - Array unique helper

private extension Array {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
