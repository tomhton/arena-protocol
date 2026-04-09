// HomeView.swift — Arena Protocol
// Single-page hub: expandable arena cards, inline session display, completion overlay

import SwiftUI
import EventKit
import WidgetKit
import TipKit
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

    // Calendar auto-start
    @State private var lastCalCheck: Date = .distantPast
    @State private var showCalPrompt = false

    // Haptic triggers (for .sensoryFeedback)
    @State private var hapticMedium: Int = 0
    @State private var hapticLight: Int = 0

    private var arenas: [Arena] { store.letteredArenas }
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

            // Persistent bottom-left checklist tab
            if store.expandedArenaId == nil && !showCompletion {
                ChecklistTabView()
            }

            // Expanded arena card overlay
            if let expandedId = store.expandedArenaId,
               let arena = arenas.first(where: { $0.id == expandedId })
                            ?? (expandedId == store.socialArena.id ? store.socialArena : nil) {
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
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticMedium)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticLight)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { t in
            // Session tick
            if store.activeSession != nil || !store.stackedSessions.isEmpty {
                sessionNow = t
                store.tickSession(now: t)
                #if canImport(ActivityKit)
                store.syncLiveActivity(now: t)
                #endif
            }
            // Calendar auto-start check (every 30 seconds)
            if store.settings.calendarAutoStart,
               t.timeIntervalSince(lastCalCheck) >= 30 {
                lastCalCheck = t
                checkCalendarAutoStart()
            }
        }
        .onChange(of: store.pendingCompletion) { _, completion in
            guard let c = completion else { return }
            store.pendingCompletion = nil
            showSessionCompletion(arena: c.arena, duration: c.durationMins, note: c.note, social: c.social)
        }
        .onChange(of: store.pendingCalSession) { _, session in
            if session != nil { showCalPrompt = true }
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
                guard let arena = pendingConcurrentArena else { return }
                store.stashSession()
                launchSession(arena: arena, duration: pendingConcurrentDuration,
                              note: pendingConcurrentNote, social: pendingConcurrentSocial)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Start a concurrent session? Your current session will be stacked.")
        }
        .sheet(isPresented: $showCalPrompt) {
            if let session = store.pendingCalSession {
                calSessionPrompt(session: session)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Calendar Auto-Start

    private func checkCalendarAutoStart() {
        guard store.activeSession == nil else { return }
        let pending = CalendarSyncManager.shared.syncBracketEvents(
            arenas: store.letteredArenas,
            socialArena: store.socialArena
        )
        if let ready = CalendarSyncManager.shared.readySession(from: pending) {
            store.pendingCalSession = ready
        }
    }

    private func calSessionPrompt(session: PendingCalSession) -> some View {
        let arenaColor = Color(hex: session.arena.color)
        return VStack(spacing: 20) {
            Text(session.arena.icon)
                .font(.system(size: 40))
                .shadow(color: arenaColor, radius: 12)

            VStack(spacing: 6) {
                Text("CALENDAR BLOCK")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(5)
                Text(session.arena.label)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(arenaColor)
                    .kerning(3)
                if !session.note.isEmpty {
                    Text(session.note)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .lineLimit(1)
                }
                Text("\(session.durationMins) MINUTES")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .kerning(2)
            }

            HStack(spacing: 14) {
                Button {
                    CalendarSyncManager.shared.markProcessed(session.id)
                    store.pendingCalSession = nil
                    showCalPrompt = false
                } label: {
                    Text("DISMISS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .kerning(3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    CalendarSyncManager.shared.markProcessed(session.id)
                    store.pendingCalSession = nil
                    showCalPrompt = false
                    launchSession(arena: session.arena, duration: session.durationMins,
                                  note: session.note, social: false)
                } label: {
                    Text("ENTER THE ARENA")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(arenaColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(24)
        .background(Color(hex: "#080810"))
    }

    // MARK: - Session Completion Helper

    private func showSessionCompletion(arena: Arena, duration: Int, note: String, social: Bool) {
        completionArena = arena
        completionDuration = duration
        completionNote = note
        completionSocial = social
        SiriShortcutsTip.hasCompletedSession = true
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
            HomeHeaderView(hasSession: hasSession)
                .padding(.top, hasSession ? 8 : 44)

            // Calendar
            CalendarDayView(onTapArenaEvent: { arena, duration, note in
                if store.activeSession != nil {
                    pendingConcurrentArena = arena
                    pendingConcurrentDuration = duration
                    pendingConcurrentNote = note
                    pendingConcurrentSocial = false
                    showConcurrentConfirm = true
                } else {
                    launchSession(arena: arena, duration: duration, note: note, social: false)
                }
            })

            // Quick actions
            quickActionRow
                .padding(.bottom, 16)

            // Social toggle — above arenas
            SocialSectionView(navigate: navigate, socialActive: $socialActive, hapticLight: $hapticLight)
                .padding(.bottom, 16)

            // Arenas
            ArenaGridView(navigate: navigate, editMode: $editMode,
                          hapticMedium: $hapticMedium, hapticLight: $hapticLight)

            // Protocols (inset panel)
            ProtocolsInlineView(navigate: navigate, hapticMedium: $hapticMedium)
                .padding(.bottom, 20)

            // Tools & inventory
            quickToolsRow
                .padding(.bottom, 8)
            eggStrip
                .padding(.bottom, 8)
            AppShortcutsBar()
                .padding(.bottom, 16)

            footer
        }
    }

    // MARK: - (Sections extracted to Components: HomeHeaderView, ProtocolsInlineView, ArenaGridView, ChecklistTabView)

    // MARK: - Quick Action Row

    private var quickActionRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                quickActionButton(icon: "☀", label: "MORNING", color: "#E8C547") { navigate(.checkin) }
                quickActionButton(icon: "☾", label: "WIND DOWN", color: "#A78BFA") { navigate(.winddown) }
                quickActionButton(icon: "⚡", label: "STUCK", color: "#FF8FA3") { navigate(.stuck) }
            }
            quickActionButton(icon: "⏰", label: "SCHEDULE", color: "#4ECDC4") { navigate(.schedule) }
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
        sessionNow = Date()  // Sync immediately so background color resolves without waiting for next tick

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
                            .padding(.vertical, 8)
                            .background(color.opacity(ready ? 0.12 : 0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(color.opacity(ready ? 0.4 : 0.12), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
        VStack(spacing: 0) {
            TipView(SiriShortcutsTip(), arrowEdge: .bottom)
                .tipBackground(Color(hex: "#0C0C18"))
                .padding(.horizontal, 16)

            HStack {
                Text("SELECT AN ARENA")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.3)).kerning(2)
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .overlay(alignment: .top) { Divider().background(Color.white.opacity(0.05)) }
        }
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
