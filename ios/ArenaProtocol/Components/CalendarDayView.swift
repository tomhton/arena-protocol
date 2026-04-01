// CalendarDayView.swift — Arena Protocol
// Day-ahead calendar panel — smart visibility tiers, tappable arena events, layout switcher.

import SwiftUI
import EventKit

struct CalendarDayView: View {
    @Environment(DataStore.self) private var store
    @State private var events: [EKEvent] = []

    // Tap callback — parent provides the arena launch flow
    var onTapArenaEvent: ((Arena, Int, String) -> Void)? = nil

    private var now: Date { Date() }

    // MARK: - Event Classification

    private var pastEvents: [EKEvent] { events.filter { $0.endDate < now } }
    private var currentEvent: EKEvent? { events.first { $0.startDate <= now && $0.endDate > now } }
    private var futureEvents: [EKEvent] { events.filter { $0.startDate > now } }

    // Past: only show last 2
    private var visiblePast: [EKEvent] { Array(pastEvents.suffix(2)) }
    // Future: first 3-4 are prominent, rest are minimal
    private var prominentFuture: [EKEvent] { Array(futureEvents.prefix(4)) }
    private var laterFuture: [EKEvent] { Array(futureEvents.dropFirst(4)) }

    var body: some View {
        if CalendarManager.shared.isReadAuthorized {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .padding(.bottom, 10)

                if events.isEmpty {
                    emptyState
                } else {
                    switch store.settings.calendarViewStyle {
                    case .timeline: timelineLayout
                    case .compact:  compactLayout
                    case .agenda:   agendaLayout
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.02))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .onAppear { events = CalendarManager.shared.todayEvents() }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 6) {
            Text("📅").font(.system(size: 10))
            Text("TODAY")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.3))
                .kerning(5)

            Spacer()

            // Layout switcher
            layoutSwitcher

            // Open Google Calendar
            Button {
                if let url = URL(string: "googlecalendar://"),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                } else if let url = URL(string: "calshow://") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("OPEN ↗")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#60A5FA").opacity(0.5))
                    .kerning(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#60A5FA").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
        }
    }

    private var layoutSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewStyle.allCases, id: \.self) { style in
                let active = store.settings.calendarViewStyle == style
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.settings.calendarViewStyle = style
                        store.saveSettings()
                    }
                } label: {
                    Text(style.icon)
                        .font(.system(size: 9))
                        .foregroundStyle(active ? Color.white.opacity(0.6) : Color.white.opacity(0.15))
                        .frame(width: 22, height: 18)
                        .background(active ? Color.white.opacity(0.08) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.trailing, 6)
    }

    private var emptyState: some View {
        HStack {
            Text("CLEAR DAY")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.15))
                .kerning(3)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Timeline Layout (default)

    private var timelineLayout: some View {
        VStack(spacing: 1) {
            // Past (last 2, minimal)
            ForEach(visiblePast, id: \.eventIdentifier) { event in
                timelineRow(event, tier: .past)
            }

            // Current (prominent)
            if let cur = currentEvent {
                timelineRow(cur, tier: .now)
            }

            // Upcoming (first 4, full detail)
            ForEach(prominentFuture, id: \.eventIdentifier) { event in
                timelineRow(event, tier: .upcoming)
            }

            // Later (minimal)
            ForEach(laterFuture, id: \.eventIdentifier) { event in
                timelineRow(event, tier: .later)
            }
        }
    }

    // MARK: - Compact Layout

    private var compactLayout: some View {
        VStack(spacing: 4) {
            // Current event — full width card
            if let cur = currentEvent {
                compactCard(cur, tier: .now)
            }

            // Upcoming — horizontal scroll
            if !futureEvents.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(futureEvents, id: \.eventIdentifier) { event in
                            let prominent = prominentFuture.contains(where: { $0.eventIdentifier == event.eventIdentifier })
                            compactCard(event, tier: prominent ? .upcoming : .later)
                                .frame(width: prominent ? 140 : 100)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Agenda Layout

    private var agendaLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            // NOW section
            if let cur = currentEvent {
                agendaSection(label: "NOW", events: [cur], tier: .now)
            }

            // UP NEXT section (first 3-4)
            if !prominentFuture.isEmpty {
                agendaSection(label: "UP NEXT", events: prominentFuture, tier: .upcoming)
            }

            // LATER section
            if !laterFuture.isEmpty {
                agendaSection(label: "LATER", events: laterFuture, tier: .later)
            }

            // DONE section (past, last 2)
            if !visiblePast.isEmpty {
                agendaSection(label: "DONE", events: visiblePast, tier: .past)
            }
        }
    }

    private func agendaSection(label: String, events: [EKEvent], tier: EventTier) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(tier == .now ? Color(hex: "#E8C547").opacity(0.6) : Color.white.opacity(0.15))
                .kerning(3)
                .padding(.leading, 4)
                .padding(.bottom, 1)
            ForEach(events, id: \.eventIdentifier) { event in
                timelineRow(event, tier: tier)
            }
        }
    }

    // MARK: - Shared Row Components

    private enum EventTier {
        case past, now, upcoming, later
    }

    private func resolveArena(_ event: EKEvent) -> Arena? {
        CalendarManager.shared.matchBracketArena(for: event, arenas: store.letteredArenas)
            ?? CalendarManager.shared.matchArena(for: event, arenas: store.arenas)
    }

    private func timelineRow(_ event: EKEvent, tier: EventTier) -> some View {
        let matched = resolveArena(event)
        let accent = matched.map { Color(hex: $0.color) } ?? Color(hex: "#60A5FA").opacity(0.5)
        let dur = event.startDate.minutesUntil(event.endDate)
        let isTappable = matched != nil && tier != .past

        return Button {
            guard let arena = matched else { return }
            onTapArenaEvent?(arena, dur, CalendarManager.shared.stripBracketPrefix(event.title ?? "", arena: arena))
        } label: {
            HStack(spacing: 8) {
                // Time
                VStack(spacing: 1) {
                    Text(formatTime(event.startDate))
                        .font(.system(size: tier == .now ? 9 : 8, weight: .semibold, design: .monospaced))
                        .foregroundStyle(tier == .now ? accent : Color.white.opacity(tier == .past ? 0.12 : 0.3))
                    if tier == .now {
                        Text("NOW")
                            .font(.system(size: 6, weight: .bold, design: .monospaced))
                            .foregroundStyle(accent)
                            .kerning(1)
                    }
                }
                .frame(width: 38, alignment: .trailing)

                // Bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(tier: tier, accent: accent))
                    .frame(width: tier == .past || tier == .later ? 2 : 3,
                           height: tier == .now ? 34 : (tier == .upcoming ? 28 : 18))

                // Content
                if tier == .past || tier == .later {
                    // Minimal: single line
                    Text(event.title ?? "Untitled")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(tier == .past ? 0.12 : 0.2))
                        .lineLimit(1)
                    Spacer()
                    Text("\(dur)m")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.1))
                } else {
                    // Full: title + duration + arena icon
                    VStack(alignment: .leading, spacing: 1) {
                        Text(event.title ?? "Untitled")
                            .font(.system(size: 10, weight: tier == .now ? .bold : .semibold, design: .monospaced))
                            .foregroundStyle(tier == .now ? accent : Color.white.opacity(0.6))
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text("\(dur)m")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.2))
                            if tier == .upcoming {
                                Text("· \(event.startDate.relativeShort())")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.15))
                            }
                        }
                    }
                    Spacer()
                    if let m = matched {
                        VStack(spacing: 2) {
                            Text(m.icon)
                                .font(.system(size: tier == .now ? 14 : 11))
                                .foregroundStyle(accent.opacity(tier == .now ? 0.8 : 0.5))
                            if isTappable {
                                Text("▶")
                                    .font(.system(size: 6))
                                    .foregroundStyle(accent.opacity(0.3))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, tier == .past || tier == .later ? 3 : 5)
            .background(rowBackground(tier: tier, accent: accent))
            .clipShape(RoundedRectangle(cornerRadius: tier == .now ? 10 : 6))
        }
        .buttonStyle(.plain)
        .disabled(!isTappable)
    }

    private func compactCard(_ event: EKEvent, tier: EventTier) -> some View {
        let matched = resolveArena(event)
        let accent = matched.map { Color(hex: $0.color) } ?? Color(hex: "#60A5FA").opacity(0.5)
        let dur = event.startDate.minutesUntil(event.endDate)
        let isTappable = matched != nil && tier != .past

        return Button {
            guard let arena = matched else { return }
            onTapArenaEvent?(arena, dur, CalendarManager.shared.stripBracketPrefix(event.title ?? "", arena: arena))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(formatTime(event.startDate))
                        .font(.system(size: 7, weight: .semibold, design: .monospaced))
                        .foregroundStyle(tier == .now ? accent : Color.white.opacity(0.3))
                    if tier == .now {
                        Text("NOW")
                            .font(.system(size: 6, weight: .bold, design: .monospaced))
                            .foregroundStyle(accent)
                            .kerning(1)
                    }
                    Spacer()
                    if let m = matched {
                        Text(m.icon).font(.system(size: 10))
                            .foregroundStyle(accent.opacity(0.6))
                    }
                }
                Text(event.title ?? "Untitled")
                    .font(.system(size: tier == .now ? 10 : 9, weight: tier == .now ? .bold : .medium, design: .monospaced))
                    .foregroundStyle(tier == .now ? accent : Color.white.opacity(tier == .later ? 0.25 : 0.5))
                    .lineLimit(1)
                Text("\(dur)m")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.15))
            }
            .padding(8)
            .background(rowBackground(tier: tier, accent: accent))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(tier == .now ? accent.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!isTappable)
    }

    // MARK: - Styling Helpers

    private func barColor(tier: EventTier, accent: Color) -> Color {
        switch tier {
        case .past:     return accent.opacity(0.12)
        case .now:      return accent
        case .upcoming: return accent.opacity(0.6)
        case .later:    return Color.white.opacity(0.06)
        }
    }

    private func rowBackground(tier: EventTier, accent: Color) -> Color {
        switch tier {
        case .past:     return Color.white.opacity(0.005)
        case .now:      return accent.opacity(0.06)
        case .upcoming: return Color.white.opacity(0.015)
        case .later:    return Color.white.opacity(0.005)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm"
        fmt.timeZone = TimeZone(identifier: store.settings.clockTimezone) ?? .current
        return fmt.string(from: date)
    }
}
