// CalendarManager.swift — Arena Protocol
// EventKit wrapper. Writes focus blocks + reads upcoming events for feed suggestions.

import EventKit
import SwiftUI
import UserNotifications

@MainActor
final class CalendarManager {
    static let shared = CalendarManager()
    nonisolated(unsafe) private let store = EKEventStore()

    var authStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    var isWriteAuthorized: Bool {
        let s = authStatus
        return s == .writeOnly || s == .fullAccess
    }

    var isReadAuthorized: Bool {
        authStatus == .fullAccess
    }

    // Request write-only (for users who haven't granted yet)
    func requestWriteAccess() async -> Bool {
        do { return try await store.requestWriteOnlyAccessToEvents() } catch { return false }
    }

    // Request full access (needed for feed reading)
    func requestFullAccess() async -> Bool {
        do { return try await store.requestFullAccessToEvents() } catch { return false }
    }

    // MARK: - Write

    func arenaCalendar() -> EKCalendar? {
        // Use the default calendar — Google Calendar (CalDAV) blocks programmatic
        // calendar creation (EKErrorDomain Code=17), so we write to wherever the
        // user's default is set (Google Calendar, iCloud, etc.)
        return store.defaultCalendarForNewEvents
    }

    @discardableResult
    func addEvent(title: String, start: Date, end: Date, notes: String = "") -> String? {
        guard isReadAuthorized, let cal = arenaCalendar() else {
            print("[CalendarManager] addEvent skipped — fullAccess:\(isReadAuthorized) cal:\(arenaCalendar() != nil)")
            return nil
        }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        if !notes.isEmpty { event.notes = notes }
        event.calendar = cal
        do {
            try store.save(event, span: .thisEvent, commit: true)
            return event.eventIdentifier
        } catch {
            print("[CalendarManager] save event failed: \(error)")
            return nil
        }
    }

    func updateEventEnd(id: String, newEnd: Date) {
        guard isReadAuthorized else { return }
        guard let event = store.event(withIdentifier: id) else {
            print("[CalendarManager] updateEventEnd — event not found: \(id)")
            return
        }
        event.endDate = newEnd
        do {
            try store.save(event, span: .thisEvent, commit: true)
        } catch {
            print("[CalendarManager] updateEventEnd failed: \(error)")
        }
    }

    func deleteEvent(id: String) {
        guard isReadAuthorized else { return }
        guard let event = store.event(withIdentifier: id) else {
            print("[CalendarManager] deleteEvent — event not found: \(id)")
            return
        }
        do {
            try store.remove(event, span: .thisEvent, commit: true)
        } catch {
            print("[CalendarManager] deleteEvent failed: \(error)")
        }
    }

    // MARK: - Read feed

    /// Returns events currently in progress (started before now, ending after now).
    func activeEvents() -> [EKEvent] {
        guard isReadAuthorized else { return [] }
        let now = Date()
        let lookback = now.addingTimeInterval(-24 * 3600)
        let lookahead = now.addingTimeInterval(8 * 3600)
        let pred = store.predicateForEvents(withStart: lookback, end: lookahead, calendars: nil)
        return store.events(matching: pred)
            .filter { event in
                guard let cal = event.calendar else { return false }
                return cal.title != "Arena Protocol" && !event.isAllDay
                    && event.startDate <= now && event.endDate > now
            }
    }

    /// Returns upcoming calendar events (all calendars except "Arena Protocol") in the next `hours` hours.
    func upcomingEvents(hours: Int = 12) -> [EKEvent] {
        guard isReadAuthorized else { return [] }
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(hours * 3600))
        let pred = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        return store.events(matching: pred)
            .filter { event in
                guard let cal = event.calendar else { return false }
                return cal.title != "Arena Protocol" && !event.isAllDay
            }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Returns all calendar events for today (past, current, and upcoming).
    func todayEvents() -> [EKEvent] {
        guard isReadAuthorized else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? Date()
        let pred = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: pred)
            .filter { event in
                guard let cal = event.calendar else { return false }
                return cal.title != "Arena Protocol" && !event.isAllDay
            }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Match an event title to one of the user's arenas via keyword heuristics.
    func matchArena(for event: EKEvent, arenas: [Arena]) -> Arena? {
        let title = (event.title ?? "").lowercased()
        let notes = (event.notes ?? "").lowercased()
        let text  = "\(title) \(notes)"

        // arena-id → keywords (ordered by specificity)
        let rules: [(String, [String])] = [
            ("health",     ["gym", "workout", "run", "walk", "yoga", "swim", "train",
                            "health", "recovery", "rest", "sleep", "physio", "stretch"]),
            ("connection", ["meeting", "call", "sync", "standup", "lunch", "dinner",
                            "coffee", "catch up", "catch-up", "family", "friend",
                            "interview", "1:1", "one on one"]),
            ("alignment",  ["plan", "review", "strategy", "retrospective", "retro",
                            "goal", "vision", "clarity", "priorit", "roadmap",
                            "weekly", "daily"]),
            ("execution",  ["deep work", "focus", "build", "code", "write", "design",
                            "project", "develop", "ship", "work block", "study",
                            "research", "draft"]),
        ]

        for (id, keywords) in rules {
            if keywords.contains(where: { text.contains($0) }) {
                if let match = arenas.first(where: { $0.id == id }) { return match }
            }
        }
        return nil
    }

    /// Explicit bracket-prefix matching: "[WORK] Deep focus" → WORK arena.
    /// Case-insensitive. Matches against arena label and id.
    /// Also handles partial matches: "[RECOVERY]" matches "RECOVERY & RESTORATION".
    func matchBracketArena(for event: EKEvent, arenas: [Arena]) -> Arena? {
        let title = (event.title ?? "").uppercased()
        // Extract the bracketed tag: "[SOMETHING] ..." → "SOMETHING"
        guard title.hasPrefix("["),
              let close = title.firstIndex(of: "]") else { return nil }
        let tag = String(title[title.index(after: title.startIndex)..<close])
        // Match tag against arena label or id (exact or prefix)
        return arenas.first { tag == $0.label.uppercased() || tag == $0.id.uppercased() }
            ?? arenas.first { $0.label.uppercased().hasPrefix(tag) || tag.hasPrefix($0.label.uppercased()) }
    }

    /// Strip the "[...] " prefix from a title, returning the remainder as a session note.
    func stripBracketPrefix(_ title: String, arena: Arena) -> String {
        guard title.hasPrefix("["), let close = title.firstIndex(of: "]") else { return title }
        let afterBracket = title.index(after: close)
        return String(title[afterBracket...]).trimmingCharacters(in: .whitespaces)
    }

    /// Look up an event by its identifier. Returns nil if deleted or unavailable.
    func event(withIdentifier id: String) -> EKEvent? {
        guard isReadAuthorized else { return nil }
        return store.event(withIdentifier: id)
    }
}

// MARK: - Timezone helpers

struct ClockTimezone: Identifiable, Equatable {
    let id: String
    let label: String
    var timeZone: TimeZone { TimeZone(identifier: id) ?? .current }
}

let CLOCK_TIMEZONES: [ClockTimezone] = [
    ClockTimezone(id: "device",              label: "Device"),
    ClockTimezone(id: "America/Los_Angeles", label: "Pacific"),
    ClockTimezone(id: "America/Denver",      label: "Mountain"),
    ClockTimezone(id: "America/Chicago",     label: "Central"),
    ClockTimezone(id: "America/New_York",    label: "Eastern"),
    ClockTimezone(id: "UTC",                 label: "UTC"),
]

extension Date {
    func formatted(timezone id: String) -> String {
        let tz = id == "device" ? TimeZone.current : (TimeZone(identifier: id) ?? .current)
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        fmt.timeZone = tz
        fmt.amSymbol = "AM"; fmt.pmSymbol = "PM"
        let abbr = tz.abbreviation(for: self) ?? ""
        return "\(fmt.string(from: self)) \(abbr)"
    }

    /// "in 23m" / "now" / "12m ago"
    func relativeShort() -> String {
        let diff = Int(self.timeIntervalSinceNow / 60)
        if diff > 1 { return "in \(diff)m" }
        if diff >= -2 { return "now" }
        return "\(-diff)m ago"
    }

    /// Duration in whole minutes between two dates
    func minutesUntil(_ end: Date) -> Int {
        max(1, Int(end.timeIntervalSince(self) / 60))
    }
}

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

// MARK: - Calendar Sync Manager

@MainActor
final class CalendarSyncManager {
    static let shared = CalendarSyncManager()

    /// Event identifiers already processed (started or dismissed). Persisted to UserDefaults.
    private var processedIds: Set<String> {
        didSet { saveProcessedIds() }
    }

    private let processedKey = "arena_cal_synced_events"

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: processedKey) ?? []
        processedIds = Set(saved)
    }

    private func saveProcessedIds() {
        UserDefaults.standard.set(Array(processedIds), forKey: processedKey)
    }

    /// Scan upcoming calendar events for bracket-prefixed arena matches.
    /// Schedules notifications for future events and returns all pending sessions.
    func syncBracketEvents(arenas: [Arena], socialArena: Arena? = nil) -> [PendingCalSession] {
        let cal = CalendarManager.shared
        guard cal.isReadAuthorized else { return [] }

        let allArenas = socialArena.map { arenas + [$0] } ?? arenas
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

            let secondsFromNow = event.startDate.timeIntervalSinceNow
            if secondsFromNow > 5 {
                scheduleCalSessionNotification(session: session, secondsFromNow: secondsFromNow)
            }
        }

        return pending.sorted { $0.startTime < $1.startTime }
    }

    /// Find a pending session that's ready to start right now (within the last 90 seconds).
    func readySession(from pending: [PendingCalSession]) -> PendingCalSession? {
        let now = Date()
        return pending.first { session in
            let diff = now.timeIntervalSince(session.startTime)
            return diff >= -5 && diff <= 90
        }
    }

    func markProcessed(_ eventId: String) {
        processedIds.insert(eventId)
    }

    func isProcessed(_ eventId: String) -> Bool {
        processedIds.contains(eventId)
    }

    /// Remove entries older than 24 hours to prevent unbounded growth.
    func cleanupOldEntries() {
        if processedIds.count > 200 {
            let ids = Array(processedIds)
            processedIds = Set(ids.suffix(100))
        }
    }

    private func scheduleCalSessionNotification(session: PendingCalSession, secondsFromNow: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "\(session.arena.icon) \(session.arena.label) starting now"
        content.body = session.note.isEmpty
            ? "Calendar block - \(session.durationMins)m"
            : "\(session.note) - \(session.durationMins)m"
        content.sound = .default
        content.categoryIdentifier = "CALENDAR_SESSION"
        content.userInfo = [
            "arenaId": session.arena.id,
            "durationMins": session.durationMins,
            "note": session.note,
            "eventId": session.id
        ]

        let notificationID = "cal_session_\(session.id)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsFromNow, repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        center.add(request)
    }
}

private extension Array {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
