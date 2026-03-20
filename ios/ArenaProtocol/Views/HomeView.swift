// HomeView.swift — Arena Protocol
// Main dashboard with arena grid, shortcuts, and navigation

import SwiftUI
import EventKit

private enum HomeViewMode { case home, session }

struct HomeView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void
    @Binding var pendingDrop: EmberDrop?

    @State private var editMode = false
    @State private var nextBlock: EKEvent? = nil
    @State private var socialActive = false
    @State private var sessionNow: Date = Date()
    @State private var viewMode: HomeViewMode = .home

    // Long-press gate — prevents button tap firing after a long-press activates edit mode
    @State private var longPressedArenaId: String? = nil

    // Drag-to-reorder state
    @State private var draggingId: String? = nil
    @State private var dragTargetIdx: Int = -1
    private let reorderRowH: CGFloat = 62

    private let socialColor = Color(hex: "#B794F4")

    private var arenas: [Arena] { store.letteredArenas }
    private var sessions: [Session] { store.sessions }
    private var hasSession: Bool { store.activeSession != nil || !store.stackedSessions.isEmpty }

    private var currentlyRunningArena: Arena? {
        store.activeSession?.currentSlot(now: sessionNow)?.arena
            ?? store.stackedSessions.first?.currentSlot(now: sessionNow)?.arena
            ?? store.stackedSessions.first?.arena
    }

    // Binding<Int> that drives the TabView and stays in sync with viewMode
    private var pageBinding: Binding<Int> {
        Binding(
            get: { viewMode == .home ? 0 : 1 },
            set: { viewMode = $0 == 0 ? .home : .session }
        )
    }

    var body: some View {
        ZStack {
            EmberParticles()

            if let runningArena = currentlyRunningArena {
                Color(hex: runningArena.color)
                    .opacity(0.22)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.5), value: runningArena.id)
            }

            VStack(spacing: 0) {
                // Compact session strip — shows timer inline when session running
                if hasSession {
                    compactSessionStrip
                }

                // View selector — tap for menu, swipe pages via TabView below
                if hasSession {
                    viewSelectorMenu
                }

                // Content — TabView enables native horizontal page-swipe when session running
                if hasSession {
                    TabView(selection: pageBinding) {
                        ScrollView(showsIndicators: false) {
                            homeContent
                        }
                        .tag(0)

                        ScrollView(showsIndicators: false) {
                            sessionContent
                        }
                        .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    ScrollView(showsIndicators: false) {
                        homeContent
                    }
                }
            }

            if let drop = pendingDrop {
                EmberDropModal(drop: drop) { pendingDrop = nil }
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: pendingDrop?.id)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: hasSession)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: store.stackedSessions.count)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { t in
            guard store.activeSession != nil || !store.stackedSessions.isEmpty else { return }
            sessionNow = t
            store.tickSession(now: t)
            #if canImport(ActivityKit)
            store.syncLiveActivity(now: t)
            #endif
        }
        .onChange(of: store.pendingCompletion) { _, completion in
            guard let c = completion else { return }
            store.pendingCompletion = nil
            navigate(.complete(c.arena, c.durationMins, c.note, c.social))
        }
        .onAppear {
            refreshNextBlock()
            if hasSession { viewMode = .session }
            if store.activeSession == nil && store.stackedSessions.isEmpty {
                #if canImport(ActivityKit)
                store.startIdleActivity()
                #endif
            }
        }
        .onChange(of: hasSession) { _, new in
            if new { withAnimation(.spring(response: 0.3)) { viewMode = .session } }
        }
    }

    private func refreshNextBlock() {
        guard CalendarManager.shared.isReadAuthorized else { nextBlock = nil; return }
        let upcoming = CalendarManager.shared.upcomingEvents(hours: 2)
        nextBlock = upcoming.first(where: { Int($0.startDate.timeIntervalSinceNow / 60) <= 90 })
    }

    // MARK: - Compact Session Strip

    private var compactSessionStrip: some View {
        let active    = store.activeSession
        let stacked   = store.stackedSessions
        let src: ActiveSessionState? = active ?? stacked.first
        let curSlot   = src?.currentSlot(now: sessionNow)
        let liveArena = curSlot?.arena ?? active?.arena ?? stacked.first?.arena ?? DEFAULT_ARENAS[0]
        let liveColor = Color(hex: liveArena.color)
        let liveEnd   = curSlot?.end ?? active?.endTime ?? stacked.first?.endTime ?? Date()

        return VStack(spacing: 0) {
            Rectangle()
                .fill(liveColor)
                .frame(height: 2)

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3)) { viewMode = .session }
                } label: {
                    HStack(spacing: 8) {
                        Text(liveArena.icon)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(liveArena.label)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .kerning(2)
                            Text("ENDS  \(formattedStartTime(liveEnd))")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(liveColor.opacity(0.55))
                                .kerning(2)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if let a = active, a.isPaused {
                    let s = Int(a.pausedRemaining)
                    Text(String(format: "%d:%02d", s / 60, s % 60))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(liveColor.opacity(0.55))
                        .monospacedDigit()
                } else if liveEnd > sessionNow {
                    Text(liveEnd, style: .timer)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(liveColor)
                        .monospacedDigit()
                } else {
                    Text("0:00")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(liveColor.opacity(0.5))
                        .monospacedDigit()
                }

                if let a = active {
                    Button { store.togglePause() } label: {
                        Text(a.isPaused ? "▶" : "⏸")
                            .font(.system(size: 13))
                            .foregroundStyle(liveColor)
                            .frame(width: 32, height: 32)
                            .background(liveColor.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(liveColor.opacity(0.10))
        }
        .animation(.easeInOut(duration: 0.5), value: liveColor.description)
    }

    // MARK: - View Selector Menu

    private var viewSelectorMenu: some View {
        let liveColor = Color(hex: currentlyRunningArena?.color ?? "#E8C547")

        return HStack(spacing: 0) {
            Menu {
                Button {
                    withAnimation(.spring(response: 0.3)) { viewMode = .home }
                } label: {
                    Label("Home", systemImage: "square.grid.2x2")
                }
                Button {
                    withAnimation(.spring(response: 0.3)) { viewMode = .session }
                } label: {
                    Label("Currently In", systemImage: "timer")
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewMode == .home ? "HOME" : "CURRENTLY IN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(viewMode == .session ? liveColor.opacity(0.8) : Color.white.opacity(0.45))
                        .kerning(3)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
            }
            .menuStyle(.automatic)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.18))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
        }
    }

    // MARK: - Nav Buttons Row

    private var navButtonsRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if store.todaySessions > 0 {
                    Text("● \(store.todaySessions) SESSION\(store.todaySessions != 1 ? "S" : "") TODAY")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.22))
                        .kerning(3)
                }
                if let title = getActiveTitle(sessions: sessions) {
                    let titleColor = title.arenaId != nil
                        ? Color(hex: arenas.first { $0.id == title.arenaId }?.color ?? "#E8C547")
                        : Color(hex: "#E8C547")
                    Text(title.label)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(titleColor.opacity(0.7))
                        .kerning(4)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 7) {
                topButton("IDEA !", color: "#E8C547")  { navigate(.notes)     }
                topButton("STATS",  color: "#B794F4")  { navigate(.history)   }
                topButton("BAG",    color: "#34D399")  { navigate(.inventory) }
                topButton("⚙",      color: "rgba(255,255,255,0.4)") { navigate(.settings) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Home Content

    private var homeContent: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ARENA PROTOCOL")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.22))
                        .kerning(6)
                    if !hasSession {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("ENTER THE")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.9))
                                .kerning(2)
                            Text("ARENA")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: "#E8C547"))
                                .kerning(2)
                        }
                    }
                    if let title = getActiveTitle(sessions: sessions) {
                        let titleColor = title.arenaId != nil
                            ? Color(hex: arenas.first { $0.id == title.arenaId }?.color ?? "#E8C547")
                            : Color(hex: "#E8C547")
                        Text(title.label)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(titleColor.opacity(0.75))
                            .kerning(4)
                    }
                    if store.todaySessions > 0 {
                        Text("● \(store.todaySessions) SESSION\(store.todaySessions != 1 ? "S" : "") TODAY")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .kerning(3)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 7) {
                    topButton("IDEA !", color: "#E8C547")  { navigate(.notes)     }
                    topButton("STATS",  color: "#B794F4")  { navigate(.history)   }
                    topButton("BAG",    color: "#34D399")  { navigate(.inventory) }
                    topButton("⚙",      color: "rgba(255,255,255,0.4)") { navigate(.settings) }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, hasSession ? 12 : 44)
            .padding(.bottom, 12)

            if let event = nextBlock { nextBlockBanner(event: event) }
            editToggle
            arenaGrid
            socialSection
            AppShortcutsBar()
            intervalsSection
            bottomButtons
            footer
        }
    }

    // MARK: - Session Content

    private var sessionContent: some View {
        let active   = store.activeSession
        let stacked  = store.stackedSessions
        let src: ActiveSessionState? = active ?? stacked.first
        let curSlot  = src?.currentSlot(now: sessionNow)

        let liveArena: Arena = curSlot?.arena ?? active?.arena ?? stacked.first?.arena ?? DEFAULT_ARENAS[0]
        let liveColor = Color(hex: liveArena.color)
        let liveEnd: Date = curSlot?.end ?? active?.endTime ?? stacked.first?.endTime ?? Date()
        let jointEntries: [JointArenaEntry] = active?.jointEntries ?? []
        let totalCount = (active != nil ? 1 : 0) + jointEntries.count + stacked.count
        let totalMins  = (active?.durationMins ?? 0) + jointEntries.reduce(0) { $0 + $1.minutes }

        let futureSlots: [(arena: Arena, start: Date, end: Date)] =
            src?.timeline.filter { $0.start > sessionNow } ?? []
        let subStacked: [ActiveSessionState] = active != nil ? stacked : Array(stacked.dropFirst())

        return VStack(alignment: .leading, spacing: 0) {

            navButtonsRow
                .padding(.top, 8)

            // ── CURRENT ARENA BLOCK ──────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text("CURRENTLY IN")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(liveColor.opacity(0.8))
                        .kerning(5)
                    if totalCount > 1 {
                        Text("·  \(totalCount) ARENAS")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(liveColor.opacity(0.4))
                            .kerning(3)
                    }
                }
                .padding(.bottom, 12)

                if let a = active {
                    Button { navigate(.active(a.arena, a.durationMins, a.note, a.social)) } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 8) {
                                    Text(liveArena.icon).font(.system(size: 22))
                                    Text(liveArena.label)
                                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .kerning(2)
                                }
                                Text(liveArena.subtitle)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.35))
                                    .kerning(2)
                                if !jointEntries.isEmpty {
                                    Text("TOTAL  \(totalMins)m")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundStyle(liveColor.opacity(0.45))
                                        .kerning(2)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                if a.isPaused {
                                    let s = Int(a.pausedRemaining)
                                    Text(String(format: "%d:%02d", s / 60, s % 60))
                                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                                        .foregroundStyle(liveColor)
                                        .monospacedDigit()
                                } else if liveEnd > sessionNow {
                                    Text(liveEnd, style: .timer)
                                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                                        .foregroundStyle(liveColor)
                                        .monospacedDigit()
                                } else {
                                    Text("0:00")
                                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                                        .foregroundStyle(liveColor.opacity(0.5))
                                        .monospacedDigit()
                                }
                                Text("ENDS  \(formattedStartTime(liveEnd))")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(liveColor.opacity(0.55))
                                    .kerning(2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } else if let first = stacked.first {
                    let firstSlot  = first.currentSlot(now: sessionNow)
                    let firstArena = firstSlot?.arena ?? first.arena
                    let firstColor = Color(hex: firstArena.color)
                    let firstEnd   = firstSlot?.end ?? first.endTime
                    Button {
                        store.unstashSession(arenaId: first.arena.id)
                        if let a = store.activeSession {
                            navigate(.active(a.arena, a.durationMins, a.note, a.social))
                        }
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 8) {
                                    Text(firstArena.icon).font(.system(size: 22))
                                        .foregroundStyle(firstColor.opacity(0.6))
                                    Text(firstArena.label)
                                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .kerning(2)
                                }
                                Text("STACKED  —  TAP TO RESUME")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(firstColor.opacity(0.6))
                                    .kerning(3)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                if firstEnd > sessionNow {
                                    Text(firstEnd, style: .timer)
                                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                                        .foregroundStyle(firstColor.opacity(0.55))
                                        .monospacedDigit()
                                } else {
                                    Text("0:00")
                                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                                        .foregroundStyle(firstColor.opacity(0.35))
                                        .monospacedDigit()
                                }
                                Text("ENDS  \(formattedStartTime(firstEnd))")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(firstColor.opacity(0.4))
                                    .kerning(2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                if let a = active {
                    HStack(spacing: 12) {
                        Button { store.togglePause() } label: {
                            Text(a.isPaused ? "▶  RESUME" : "⏸  PAUSE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(liveColor)
                                .kerning(2)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(liveColor.opacity(0.15))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(liveColor.opacity(0.5), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button { navigate(.active(a.arena, a.durationMins, a.note, a.social)) } label: {
                            Text("OPEN →")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.25))
                                .kerning(3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(liveColor.opacity(0.10))
            .animation(.easeInOut(duration: 0.5), value: liveColor.description)

            // ── FULL TIMELINE ────────────────────────────────────────────
            if !futureSlots.isEmpty {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                Text("TIMELINE")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(4)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                ForEach(Array(futureSlots.enumerated()), id: \.offset) { _, slot in
                    let sc       = Color(hex: slot.arena.color)
                    let slotMins = max(1, Int(slot.end.timeIntervalSince(slot.start) / 60))
                    HStack(spacing: 10) {
                        Text(slot.arena.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(sc.opacity(0.65))
                        Text(slot.arena.label)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(sc.opacity(0.75))
                            .kerning(2)
                        Text("·  \(slotMins)m")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(sc.opacity(0.35))
                        Spacer()
                        Text("\(formattedStartTime(slot.start))  →  \(formattedStartTime(slot.end))")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(sc.opacity(0.65))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }

            // ── STACKED SESSIONS ─────────────────────────────────────────
            if !subStacked.isEmpty {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.top, futureSlots.isEmpty ? 12 : 4)
                Text("STACKED")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(4)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 2)
                ForEach(subStacked, id: \.arena.id) { s in
                    let sSlot  = s.currentSlot(now: sessionNow)
                    let sArena = sSlot?.arena ?? s.arena
                    let sColor = Color(hex: sArena.color)
                    let sEnd   = sSlot?.end ?? s.endTime
                    Button {
                        store.unstashSession(arenaId: s.arena.id)
                        if let a = store.activeSession {
                            navigate(.active(a.arena, a.durationMins, a.note, a.social))
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text(sArena.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(sColor)
                            Text(sArena.label)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(sColor.opacity(0.8))
                                .kerning(2)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                if sEnd > sessionNow {
                                    Text(sEnd, style: .timer)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(sColor.opacity(0.7))
                                        .monospacedDigit()
                                } else {
                                    Text("0:00")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(sColor.opacity(0.45))
                                        .monospacedDigit()
                                }
                                Text("ENDS  \(formattedStartTime(sEnd))")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(sColor.opacity(0.45))
                                    .kerning(1)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 32)
        }
    }

    // MARK: - Helpers

    private func formattedStartTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        fmt.timeZone = TimeZone(identifier: store.settings.clockTimezone) ?? .current
        return fmt.string(from: date)
    }

    // MARK: - Calendar Banner

    @ViewBuilder
    private func nextBlockBanner(event: EKEvent) -> some View {
        let dur     = event.startDate.minutesUntil(event.endDate)
        let when    = event.startDate.relativeShort()
        let matched = CalendarManager.shared.matchArena(for: event, arenas: store.arenas)
        let accent: Color = matched.map { Color(hex: $0.color) } ?? Color(hex: "#60A5FA")

        Button {
            if let arena = matched { navigate(.select(arena, socialActive)) }
        } label: {
            HStack(spacing: 12) {
                Text("📅").font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text((event.title ?? "Upcoming Block").uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent).kerning(2).lineLimit(1)
                    Text("\(when)  ·  \(dur)m\(matched != nil ? "  ·  \(matched!.label)" : "")")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35)).kerning(1)
                }
                Spacer()
                if matched != nil {
                    Text("START →")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent.opacity(0.7)).kerning(3)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(accent.opacity(0.07))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accent.opacity(0.2), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.bottom, 10)
        .disabled(matched == nil)
    }

    private func topButton(_ label: String, color: String, action: @escaping () -> Void) -> some View {
        let c = color.hasPrefix("rgba") ? Color.white.opacity(0.4) : Color(hex: color)
        return Button(action: action) {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(c).kerning(2)
                .padding(.horizontal, 11).padding(.vertical, 7)
                .background(c.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(c.opacity(0.4), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Edit Toggle

    private var editToggle: some View {
        HStack {
            Spacer()
            Button { withAnimation(.spring(response: 0.35)) { editMode.toggle() } } label: {
                Text(editMode ? "DONE" : "EDIT ARENAS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(editMode ? Color(hex: "#E8C547") : Color.white.opacity(0.25))
                    .kerning(3)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(editMode ? Color(hex: "#E8C547").opacity(0.15) : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(editMode ? Color(hex: "#E8C547").opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
    }

    // MARK: - Arena Grid (grid in normal mode; reorder list in edit mode)

    @ViewBuilder
    private var arenaGrid: some View {
        if editMode {
            arenaReorderList
                .transition(.opacity.combined(with: .offset(y: 6)))
        } else {
            twoColumnGrid
                .transition(.opacity)
        }
    }

    // MARK: - Two-column grid (normal view)

    private var twoColumnGrid: some View {
        let left  = Array(arenas.prefix(Int(ceil(Double(arenas.count) / 2))))
        let right = Array(arenas.suffix(arenas.count - left.count))

        return VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 10) {
                    ForEach(left) { arena in
                        ArenaCardView(
                            arena: arena,
                            sessCount: sessions.filter { $0.arenaId == arena.id && $0.date == todayString() }.count,
                            streak: store.streak(for: arena.id),
                            editMode: false,
                            onTap: {
                                guard longPressedArenaId != arena.id else {
                                    longPressedArenaId = nil
                                    return
                                }
                                navigate(.select(arena, socialActive))
                            },
                            sessions: sessions
                        )
                        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                            longPressedArenaId = arena.id
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.35)) { editMode = true }
                        })
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 18)),
                            removal: .opacity
                        ))
                    }
                }
                VStack(spacing: 10) {
                    ForEach(right) { arena in
                        ArenaCardView(
                            arena: arena,
                            sessCount: sessions.filter { $0.arenaId == arena.id && $0.date == todayString() }.count,
                            streak: store.streak(for: arena.id),
                            editMode: false,
                            onTap: {
                                guard longPressedArenaId != arena.id else {
                                    longPressedArenaId = nil
                                    return
                                }
                                navigate(.select(arena, socialActive))
                            },
                            sessions: sessions
                        )
                        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                            longPressedArenaId = arena.id
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.35)) { editMode = true }
                        })
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 18)),
                            removal: .opacity
                        ))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Reorder list (edit mode)

    private var arenaReorderList: some View {
        VStack(spacing: 4) {
            ForEach(Array(store.letteredArenas.enumerated()), id: \.element.id) { idx, arena in
                reorderRow(arena: arena, idx: idx, total: store.arenas.count)
            }
            AddArenaCardView { navigate(.newArena) }
                .padding(.top, 4)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.25), value: dragTargetIdx)
    }

    private func reorderRow(arena: Arena, idx: Int, total: Int) -> some View {
        let isDragging = draggingId == arena.id
        let isTarget   = !isDragging && dragTargetIdx == idx && draggingId != nil
        let c          = Color(hex: arena.color)

        return HStack(spacing: 12) {
            // Drag handle — gesture lives here so scrolling still works on the row body
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(isDragging ? 0.6 : 0.25))
                .frame(width: 28, height: reorderRowH)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 4, coordinateSpace: .local)
                        .onChanged { val in
                            if draggingId == nil {
                                draggingId = arena.id
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            let delta = Int((val.translation.height / reorderRowH).rounded())
                            dragTargetIdx = max(0, min(total - 1, idx + delta))
                        }
                        .onEnded { _ in
                            if let id = draggingId,
                               let fromIdx = store.arenas.firstIndex(where: { $0.id == id }) {
                                let toIdx   = dragTargetIdx
                                let insertAt = fromIdx <= toIdx ? toIdx + 1 : toIdx
                                withAnimation(.spring(response: 0.3)) {
                                    store.moveArena(from: IndexSet(integer: fromIdx), to: insertAt)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            draggingId    = nil
                            dragTargetIdx = -1
                        }
                )

            Text(arena.icon).font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(arena.label)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .kerning(2)
                if !arena.subtitle.isEmpty {
                    Text(arena.subtitle)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(c.opacity(0.5))
                        .kerning(1)
                }
            }

            Spacer()

            Button { navigate(.editArena(arena)) } label: {
                Text("EDIT")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(c.opacity(0.65))
                    .kerning(2)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(c.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: reorderRowH)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDragging ? c.opacity(0.18)
                      : isTarget  ? c.opacity(0.07)
                      : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isDragging ? c.opacity(0.55)
                                      : isTarget  ? c.opacity(0.3)
                                      : Color.white.opacity(0.07),
                                      lineWidth: isDragging ? 1.5 : 1)
                )
        )
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .opacity(isDragging ? 0.65 : 1.0)
        .animation(.spring(response: 0.2), value: isDragging)
        .animation(.spring(response: 0.2), value: isTarget)
    }

    // MARK: - Social Section

    private var socialSection: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { socialActive.toggle() }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 12) {
                    Text("🤝")
                        .font(.system(size: 18))
                        .shadow(color: socialActive ? socialColor.opacity(0.6) : .clear, radius: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SOCIAL")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(socialActive ? socialColor : Color.white.opacity(0.45))
                            .kerning(4)
                        Text(socialActive ? "active — pick an arena or start solo" : "tap to add social to any session")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(socialActive ? 0.4 : 0.2))
                            .kerning(1)
                    }
                    Spacer()
                    ZStack {
                        Capsule()
                            .fill(socialActive ? socialColor : Color.white.opacity(0.08))
                            .frame(width: 44, height: 24)
                        Circle().fill(.white).frame(width: 18, height: 18)
                            .offset(x: socialActive ? 10 : -10)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(socialActive ? socialColor.opacity(0.1) : Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(socialActive ? socialColor.opacity(0.5) : Color.white.opacity(0.07),
                                  lineWidth: socialActive ? 1.5 : 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            if socialActive {
                Button { navigate(.select(SOCIAL_ARENA, true)) } label: {
                    HStack(spacing: 10) {
                        Text("🤝").font(.system(size: 14))
                        Text("SOCIAL ONLY SESSION →")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(socialColor).kerning(3)
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(socialColor.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(socialColor.opacity(0.35), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .offset(y: -6)))
            }
        }
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    // MARK: - Intervals Section

    private var intervalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("INTERVALS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22)).kerning(6)
                Text("— mindless periods")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.12))
            }
            .padding(.horizontal, 14)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(INTERVAL_PRESETS, id: \.label) { preset in
                        Button { navigate(.interval(preset.label, preset.minutes)) } label: {
                            VStack(spacing: 4) {
                                Text(preset.icon).font(.system(size: 18))
                                Text(preset.label)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#4ECDC4")).kerning(2)
                                Text("\(preset.minutes)m")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.3))
                            }
                            .frame(width: 68, height: 72)
                            .background(Color(hex: "#4ECDC4").opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(hex: "#4ECDC4").opacity(0.18), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .padding(.bottom, 10)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 8) {
            Button { navigate(.protocols) } label: {
                HStack(spacing: 10) {
                    Text("◈").font(.system(size: 11)).foregroundStyle(Color(hex: "#708090"))
                    Text("PROTOCOLS").font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#708090")).kerning(4)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color(hex: "#708090").opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#708090").opacity(0.2), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button { navigate(.stuck) } label: {
                    HStack(spacing: 8) {
                        Text("⚡").font(.system(size: 13)).foregroundStyle(Color(hex: "#FF8FA3"))
                        Text("I AM STUCK").font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#FF8FA3")).kerning(4)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(hex: "#FF8FA3").opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#FF8FA3").opacity(0.25), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button { navigate(.profile) } label: {
                    HStack(spacing: 8) {
                        Text("◈").font(.system(size: 11)).foregroundStyle(Color(hex: "#E8C547"))
                        Text("PROFILE").font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#E8C547")).kerning(4)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(hex: "#E8C547").opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#E8C547").opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).padding(.bottom, 10)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("SELECT AN ARENA")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.3)).kerning(2)
            Spacer()
            Button { navigate(.checkin) } label: {
                Text("☀ MORNING")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2)).kerning(2)
            }
            .buttonStyle(.plain)
            Button { navigate(.winddown) } label: {
                Text("☾ WIND DOWN")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2)).kerning(2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
        .overlay(alignment: .top) { Divider().background(Color.white.opacity(0.05)) }
        .padding(.bottom, 8)
    }
}

// MARK: - Ember Particles

struct EmberParticles: View {
    private struct Particle: Identifiable {
        let id = UUID()
        let xFraction: Double; let delay: Double; let duration: Double; let color: String
    }
    private let particles: [Particle] = [
        Particle(xFraction: 0.12, delay: 0.0, duration: 7.0,  color: "#E8C547"),
        Particle(xFraction: 0.28, delay: 1.8, duration: 9.0,  color: "#C0392B"),
        Particle(xFraction: 0.55, delay: 0.6, duration: 8.0,  color: "#D4A017"),
        Particle(xFraction: 0.72, delay: 3.0, duration: 6.5,  color: "#E8C547"),
        Particle(xFraction: 0.88, delay: 1.2, duration: 10.0, color: "#B87333"),
        Particle(xFraction: 0.42, delay: 4.0, duration: 7.5,  color: "#708090"),
    ]
    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                EmberParticle(color: Color(hex: p.color),
                              xPos: geo.size.width * p.xFraction,
                              delay: p.delay, duration: p.duration, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct EmberParticle: View {
    let color: Color; let xPos: CGFloat; let delay: Double; let duration: Double; let height: CGFloat
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0.22
    var body: some View {
        Circle().fill(color).frame(width: 3, height: 3)
            .blur(radius: 0.5).shadow(color: color, radius: 3)
            .position(x: xPos, y: height - 10 + offset).opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeIn(duration: duration)
                    .repeatForever(autoreverses: false).delay(delay)) {
                    offset = -height * 1.1; opacity = 0
                }
            }
    }
}
