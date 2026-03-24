// CalendarDayView.swift — Arena Protocol
// Compact day-view of today's calendar events for the hub menu

import SwiftUI
import EventKit

struct CalendarDayView: View {
    @Environment(DataStore.self) private var store
    @State private var events: [EKEvent] = []

    var body: some View {
        if CalendarManager.shared.isReadAuthorized && !events.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text("📅").font(.system(size: 10))
                    Text("TODAY")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.22))
                        .kerning(5)
                    Spacer()
                    Text(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .kerning(1)
                }
                .padding(.bottom, 10)

                VStack(spacing: 4) {
                    ForEach(events.prefix(5), id: \.eventIdentifier) { event in
                        let matched = CalendarManager.shared.matchArena(for: event, arenas: store.arenas)
                        let accent: Color = matched.map { Color(hex: $0.color) } ?? Color(hex: "#60A5FA").opacity(0.5)
                        let dur = event.startDate.minutesUntil(event.endDate)
                        let isPast = event.endDate < Date()

                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(accent)
                                .frame(width: 3, height: 28)
                                .opacity(isPast ? 0.3 : 1)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.title ?? "Untitled")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(isPast ? Color.white.opacity(0.25) : accent)
                                    .lineLimit(1)
                                HStack(spacing: 4) {
                                    Text(event.startDate.relativeShort())
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(isPast ? 0.15 : 0.3))
                                    Text("·").foregroundStyle(Color.white.opacity(0.15))
                                    Text("\(dur)m")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(isPast ? 0.15 : 0.3))
                                }
                            }

                            Spacer()

                            if let m = matched, !isPast {
                                Text(m.icon)
                                    .font(.system(size: 10))
                                    .foregroundStyle(accent.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(isPast ? 0.01 : 0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.02))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .onAppear { refreshEvents() }
        } else {
            EmptyView()
                .onAppear { refreshEvents() }
        }
    }

    private func refreshEvents() {
        guard CalendarManager.shared.isReadAuthorized else { return }
        events = CalendarManager.shared.upcomingEvents(hours: 12)
    }
}
