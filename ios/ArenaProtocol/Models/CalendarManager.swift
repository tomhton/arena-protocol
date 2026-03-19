// CalendarManager.swift — Arena Protocol
// EventKit wrapper. Writes focus blocks + reads upcoming events for feed suggestions.

import EventKit
import SwiftUI

@MainActor
final class CalendarManager {
    static let shared = CalendarManager()
    private let store = EKEventStore()

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
        if let existing = store.calendars(for: .event).first(where: { $0.title == "Arena Protocol" }) {
            return existing
        }
        // Use the default calendar's source — this follows wherever the user's primary
        // calendar lives (Google Calendar via CalDAV, iCloud, Exchange, local, etc.)
        let source = store.defaultCalendarForNewEvents?.source
                  ?? store.sources.first(where: { $0.sourceType == .calDAV })
                  ?? store.sources.first(where: { $0.sourceType == .local })
        guard let source else { return nil }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = "Arena Protocol"
        cal.source = source
        cal.cgColor = UIColor(Color(hex: "#E8C547")).cgColor
        do {
            try store.saveCalendar(cal, commit: true)
            return cal
        } catch {
            print("[CalendarManager] saveCalendar failed: \(error)")
            return nil
        }
    }

    func addEvent(title: String, start: Date, end: Date, notes: String = "") {
        guard isWriteAuthorized, let cal = arenaCalendar() else {
            print("[CalendarManager] addEvent skipped — authorized:\(isWriteAuthorized)")
            return
        }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        if !notes.isEmpty { event.notes = notes }
        event.calendar = cal
        do {
            try store.save(event, span: .thisEvent, commit: true)
        } catch {
            print("[CalendarManager] save event failed: \(error)")
        }
    }

    // MARK: - Read feed

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
