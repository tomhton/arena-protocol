// CalendarManager.swift — Arena Protocol
// EventKit wrapper. Writes focus blocks to a dedicated "Arena Protocol" calendar.

import EventKit
import SwiftUI

@MainActor
final class CalendarManager {
    static let shared = CalendarManager()
    private let store = EKEventStore()

    var authStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    var isAuthorized: Bool {
        let s = authStatus
        return s == .writeOnly || s == .fullAccess
    }

    func requestAccess() async -> Bool {
        do {
            return try await store.requestWriteOnlyAccessToEvents()
        } catch {
            return false
        }
    }

    // Find or create the dedicated "Arena Protocol" calendar
    func arenaCalendar() -> EKCalendar? {
        if let existing = store.calendars(for: .event).first(where: { $0.title == "Arena Protocol" }) {
            return existing
        }
        // Prefer CalDAV (Google/iCloud sync) over local
        let source = store.sources.first(where: { $0.sourceType == .calDAV })
                  ?? store.sources.first(where: { $0.sourceType == .subscribed })
                  ?? store.sources.first(where: { $0.sourceType == .local })
        guard let source else { return nil }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = "Arena Protocol"
        cal.source = source
        cal.cgColor = UIColor(Color(hex: "#E8C547")).cgColor
        try? store.saveCalendar(cal, commit: true)
        return cal
    }

    func addEvent(title: String, start: Date, end: Date, notes: String = "") {
        guard isAuthorized, let cal = arenaCalendar() else { return }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        if !notes.isEmpty { event.notes = notes }
        event.calendar = cal
        try? store.save(event, span: .thisEvent, commit: true)
    }
}

// MARK: - Timezone helpers

struct ClockTimezone: Identifiable, Equatable {
    let id: String           // TimeZone identifier
    let label: String        // display label, e.g. "PST"

    func abbreviation(for date: Date = Date()) -> String {
        TimeZone(identifier: id)?.abbreviation(for: date) ?? label
    }

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
}
