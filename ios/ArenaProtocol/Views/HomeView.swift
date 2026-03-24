// HomeView.swift — Arena Protocol
// Single-page hub: expandable arena cards, inline session display, completion overlay

import SwiftUI
import EventKit
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

struct HomeView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void
    @Binding var pendingDrop: EmberDrop?
    @Binding var pendingForgeResult: ForgeDropResult?



    @State private var editMode = false
    @State private var socialActive = false
    @State private var sessionNow: Date = Date()

    // Session display collapse (swipe up/down)
    @State private var sessionCollapsed = false

    // Completion overlay
    @State private var completionArena: Arena? = nil
    @State private var completionDuration: Int = 0
    @State private var completionNote: String = ""
    @State private var completionSocial: Bool = false
    @State private var showCompletion = false

    // Concurrent session confirmation
    @State private var pendingConcurrentArena: Arena? = nil
    @State private var pendingConcurrentDuration: Int = 0
    @State private var pendingConcurrentNote: String = ""
    @State private var pendingConcurrentSocial: Bool = false
    @State private var showConcurrentConfirm = false

    // Long-press gate
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

            // Main content
            VStack(spacing: 0) {
                // Session display at top (when active)
                if hasSession {
                    if sessionCollapsed {
                        collapsedSessionStrip
                    } else {
                        SessionDisplayView(
                            sessionNow: sessionNow,
                            onDone: { arena, duration, note, social in
                                showSessionCompletion(arena: arena, duration: duration, note: note, social: social)
                            },
                            navigate: navigate
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Swipe hint
                    swipeHint
                }

                // Scrollable menu
                ScrollView(showsIndicators: false) {
                    menuContent
                }
                .opacity(hasSession && !sessionCollapsed ? 0.6 : 1.0)
            }
            .gesture(sessionSwipeGesture)

            // Expanded arena card overlay
            if let expandedId = store.expandedArenaId,
               let arena = arenas.first(where: { $0.id == expandedId }) {
                expandedArenaOverlay(arena: arena)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }

            // Completion overlay
            if showCompletion, let arena = completionArena {
                CompletionOverlay(arena: arena, duration: completionDuration, note: completionNote) {
                    let s = Session(arenaId: arena.id, duration: completionDuration,
                                    date: todayString(), note: completionNote,
                                    ts: Date().timeIntervalSince1970 * 1000,
                                    social: completionSocial)
                    store.addSession(s)
                    let result = store.checkAndClaimForgeResult()
                    pendingDrop = result.narrative
                    if result.hasContent { pendingForgeResult = result }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showCompletion = false
                        completionArena = nil
                    }
                }
                .transition(.opacity)
                .zIndex(200)
            }

            // Forge/Ember drop modals
            if let result = pendingForgeResult, result.hasContent {
                ForgeDropModal(result: result) {
                    pendingForgeResult = nil
                    pendingDrop = nil
                }
                .transition(.opacity)
                .zIndex(999)
            } else if let drop = pendingDrop {
                EmberDropModal(drop: drop) { pendingDrop = nil }
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: pendingForgeResult?.id)
        .animation(.easeInOut(duration: 0.25), value: pendingDrop?.id)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hasSession)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: store.expandedArenaId)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showCompletion)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: sessionCollapsed)
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
            showSessionCompletion(arena: c.arena, duration: c.durationMins, note: c.note, social: c.social)
        }
        .onAppear {
            if store.activeSession == nil && store.stackedSessions.isEmpty {
                #if canImport(ActivityKit)
                store.startIdleActivity()
                #endif
            }
        }
        .confirmationDialog("You already have a session running", isPresented: $showConcurrentConfirm) {
            Button("Start Concurrent") {
                store.stashSession()
                launchSession(arena: pendingConcurrentArena!, duration: pendingConcurrentDuration,
                              note: pendingConcurrentNote, social: pendingConcurrentSocial)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Start a concurrent session? Your current session will be stacked.")
        }
    }

    // MARK: - Session Completion Helper

    private func showSessionCompletion(arena: Arena, duration: Int, note: String, social: Bool) {
        completionArena = arena
        completionDuration = duration
        completionNote = note
        completionSocial = social
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showCompletion = true
        }
    }

    // MARK: - Session Swipe Gesture

    private var sessionSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { val in
                guard hasSession else { return }
                if val.translation.height < -40 && abs(val.translation.width) < 80 {
                    // Swipe up → collapse
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        sessionCollapsed = true
                    }
                } else if val.translation.height > 40 && abs(val.translation.width) < 80 {
                    // Swipe down → expand
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        sessionCollapsed = false
                    }
                }
            }
    }

    // MARK: - Collapsed Session Strip

    private var collapsedSessionStrip: some View {
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
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        sessionCollapsed = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(liveArena.icon).font(.system(size: 16))
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

    // MARK: - Swipe Hint

    private var swipeHint: some View {
        HStack {
            Spacer()
            Text(sessionCollapsed ? "↓ swipe down to expand" : "↑ swipe up to collapse")
                .font(.system(size: 7, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.12))
                .kerning(2)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Menu Content

    private var menuContent: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(.top, hasSession ? 8 : 44)

            // 1. Calendar day view
            CalendarDayView()

            // 2. Protocols inline section
            protocolsInlineSection

            // 3. Arena grid
            editToggle
            arenaGrid

            // 4. Quick actions
            quickActionRow

            // Social toggle
            socialSection

            // Intervals
            intervalsSection

            // App dock
            AppShortcutsBar()

            // Egg strip
            eggStrip

            // 5. Quick tools
            quickToolsRow

            // Footer
            footer
        }
    }

    // MARK: - Header

    private var headerSection: some View {
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
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Protocols Inline Section

    private var protocolsInlineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PROTOCOLS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(6)
                Spacer()
                Button { navigate(.protocols) } label: {
                    Text("VIEW ALL →")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#708090").opacity(0.6))
                        .kerning(2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.protocols) { proto in
                        Button { navigate(.activeProtocol(proto)) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(proto.glyph)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: proto.color))
                                    Text(proto.name)
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color(hex: proto.color))
                                        .kerning(2)
                                        .lineLimit(1)
                                }
                                Text("\(proto.blocks.count) blocks · \(proto.blocks.reduce(0) { $0 + $1.duration })m")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.3))
                                    .kerning(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(minWidth: 140, alignment: .leading)
                            .background(Color(hex: proto.color).opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(hex: proto.color).opacity(0.2), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Quick Action Row

    private var quickActionRow: some View {
        HStack(spacing: 8) {
            quickActionButton(icon: "☀", label: "MORNING", color: "#E8C547") { navigate(.checkin) }
            quickActionButton(icon: "☾", label: "WIND DOWN", color: "#A78BFA") { navigate(.winddown) }
            quickActionButton(icon: "⚡", label: "STUCK", color: "#FF8FA3") { navigate(.stuck) }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private func quickActionButton(icon: String, label: String, color: String, action: @escaping () -> Void) -> some View {
        let c = Color(hex: color)
        return Button(action: action) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 12))
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(c).kerning(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(c.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(c.opacity(0.2), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Tools Row

    private var quickToolsRow: some View {
        HStack(spacing: 0) {
            toolIcon("⚙", label: "SETTINGS", color: Color.white.opacity(0.35)) { navigate(.settings) }
            toolIcon("◈", label: "STATS", color: Color(hex: "#B794F4")) { navigate(.history) }
            toolIcon("✦", label: "BAG", color: Color(hex: "#34D399")) { navigate(.inventory) }
            toolIcon("◉", label: "PROFILE", color: Color(hex: "#E8C547")) { navigate(.profile) }
            toolIcon("⏰", label: "SCHEDULE", color: Color(hex: "#4ECDC4")) { navigate(.schedule) }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private func toolIcon(_ icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.6))
                    .kerning(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Arena Card Overlay

    @ViewBuilder
    private func expandedArenaOverlay(arena: Arena) -> some View {
        let arenaColor = Color(hex: arena.color)

        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        store.expandedArenaId = nil
                    }
                }

            // Expanded card content
            VStack(spacing: 0) {
                // Arena color bar
                Rectangle()
                    .fill(arenaColor)
                    .frame(height: 3)

                InlineSessionConfig(
                    arena: arena,
                    social: socialActive,
                    onStart: { arena, duration, note, social in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            store.expandedArenaId = nil
                        }
                        // Check for concurrent session
                        if store.activeSession != nil {
                            pendingConcurrentArena = arena
                            pendingConcurrentDuration = duration
                            pendingConcurrentNote = note
                            pendingConcurrentSocial = social
                            showConcurrentConfirm = true
                        } else {
                            launchSession(arena: arena, duration: duration, note: note, social: social)
                        }
                    },
                    onCollapse: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            store.expandedArenaId = nil
                        }
                    }
                )
            }
            .background(Color(hex: "#080810"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(arenaColor.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 60)
        }
    }

    // MARK: - Launch Session

    private func launchSession(arena: Arena, duration: Int, note: String, social: Bool) {
        scheduleNotification(id: "session_1", title: "\(arena.label) session complete",
                             body: "Your focus block has ended.",
                             secondsFromNow: TimeInterval(duration * 60))
        // End idle Live Activity, start session
        #if canImport(ActivityKit)
        store.endIdleActivity()
        #endif
        store.startSession(arena: arena, durationMins: duration, note: note, social: social)

        // Write to shared store for widget
        let endTime = Date().addingTimeInterval(TimeInterval(duration * 60))
        SharedStore.writeActiveSession(arenaName: arena.label, arenaColor: arena.color, endsAt: endTime)
        WidgetCenter.shared.reloadAllTimelines()

        // Calendar event
        addToGCal(arena: arena, start: Date(), end: endTime, note: note, isSocial: social)

        // Start Live Activity
        #if canImport(ActivityKit)
        startLiveActivity(arena: arena, duration: duration, note: note, social: social, endTime: endTime)
        #endif

        sessionCollapsed = false
    }

    private func addToGCal(arena: Arena, start: Date, end: Date, note: String, isSocial: Bool) {
        let trimmed = note.trimmingCharacters(in: .whitespaces)
        let socialTag = isSocial ? " ◎" : ""
        let title = trimmed.isEmpty
            ? "[\(arena.label)]\(socialTag)"
            : "[\(arena.label)] \(trimmed)\(socialTag)"
        let desc = arena.description
        Task { @MainActor in
            if !CalendarManager.shared.isReadAuthorized {
                _ = await CalendarManager.shared.requestFullAccess()
            }
            let id = CalendarManager.shared.addEvent(title: title, start: start, end: end, notes: desc)
            store.activeSession?.calEventId = id
        }
    }

    #if canImport(ActivityKit)
    private func startLiveActivity(arena: Arena, duration: Int, note: String, social: Bool, endTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let normalizedColor: String = {
            let c = arena.color.trimmingCharacters(in: .whitespacesAndNewlines)
            return c.hasPrefix("#") ? c : "#\(c)"
        }()
        let socialNote: String = {
            if social && !note.isEmpty { return "◎ \(note)" }
            if social { return "◎ Social" }
            return note
        }()
        let sessionStart = Date()
        let attrs = ArenaLiveActivityAttributes(
            arenaId: arena.id,
            questNote: socialNote,
            startTime: sessionStart
        )
        let contentState = ArenaLiveActivityAttributes.ContentState(
            endTime: endTime,
            isPaused: false,
            pausedRemaining: 0,
            arenaLabel: arena.label,
            arenaColor: normalizedColor,
            arenaIcon: arena.icon.isEmpty ? "◉" : arena.icon,
            currentArenaStart: sessionStart,
            sessionEndTime: endTime
        )
        Task {
            for stale in Activity<ArenaLiveActivityAttributes>.activities {
                await stale.end(nil, dismissalPolicy: .immediate)
            }
            do {
                let _ = try Activity<ArenaLiveActivityAttributes>.request(
                    attributes: attrs,
                    content: .init(state: contentState, staleDate: endTime),
                    pushType: nil
                )
            } catch {
                print("[LiveActivity] REQUEST FAILED: \(error)")
            }
        }
        store.liveArenaId = arena.id
    }
    #endif

    // MARK: - Helpers

    private func formattedStartTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        fmt.timeZone = TimeZone(identifier: store.settings.clockTimezone) ?? .current
        return fmt.string(from: date)
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

    // MARK: - Arena Grid

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

    // MARK: - Two-column grid

    private var twoColumnGrid: some View {
        let left  = Array(arenas.prefix(Int(ceil(Double(arenas.count) / 2))))
        let right = Array(arenas.suffix(arenas.count - left.count))

        return VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 10) {
                    ForEach(left) { arena in
                        arenaCardWithExpansion(arena: arena)
                    }
                }
                VStack(spacing: 10) {
                    ForEach(right) { arena in
                        arenaCardWithExpansion(arena: arena)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func arenaCardWithExpansion(arena: Arena) -> some View {
        return ArenaCardView(
            arena: arena,
            sessCount: sessions.filter { $0.arenaId == arena.id && $0.date == todayString() }.count,
            streak: store.streak(for: arena.id),
            rankTier: store.rankState(for: arena.id).achievedRank,
            editMode: false,
            onTap: {
                guard longPressedArenaId != arena.id else {
                    longPressedArenaId = nil
                    return
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    store.expandedArenaId = arena.id
                }
            },
            sessions: sessions
        )
        .opacity(store.expandedArenaId != nil && store.expandedArenaId != arena.id ? 0.3 : 1.0)
        .scaleEffect(store.expandedArenaId != nil && store.expandedArenaId != arena.id ? 0.95 : 1.0)
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
                                let toIdx = dragTargetIdx
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
                    Button { navigate(.editArena(store.socialArena)) } label: {
                        Text("✎")
                            .font(.system(size: 12))
                            .foregroundStyle(socialColor.opacity(0.45))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
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
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        store.expandedArenaId = store.socialArena.id
                    }
                } label: {
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

    // MARK: - Egg Strip

    @ViewBuilder
    private var eggStrip: some View {
        let incubating = store.eggs.filter { !$0.isHatched }
        if !incubating.isEmpty {
            Button { navigate(.inventory) } label: {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(incubating) { egg in
                            let color = Color(hex: egg.rarity.hexColor)
                            let progress = store.eggProgress(egg)
                            let fraction = min(1.0, Double(progress) / Double(max(1, egg.hatchThreshold)))
                            let ready = store.isEggReady(egg)

                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(color.opacity(0.15), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    Circle()
                                        .trim(from: 0, to: fraction)
                                        .stroke(color.opacity(ready ? 1 : 0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                        .frame(width: 24, height: 24)
                                        .rotationEffect(.degrees(-90))
                                    Text(egg.rarity.glyph)
                                        .font(.system(size: 9))
                                        .foregroundStyle(color)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(egg.rarity.displayName)
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundStyle(color.opacity(0.8))
                                        .kerning(1)
                                    Text(ready ? "READY" : "\(progress)/\(egg.hatchThreshold)")
                                        .font(.system(size: 7, design: .monospaced))
                                        .foregroundStyle(ready ? color : Color.white.opacity(0.25))
                                        .kerning(1)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(color.opacity(ready ? 0.12 : 0.05))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(color.opacity(ready ? 0.4 : 0.12), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .animation(.easeInOut(duration: 0.3), value: ready)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("SELECT AN ARENA")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.3)).kerning(2)
            Spacer()
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
