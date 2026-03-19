// HomeView.swift — Arena Protocol
// Main dashboard with arena grid, shortcuts, and navigation

import SwiftUI
import EventKit

struct HomeView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void
    @Binding var pendingDrop: EmberDrop?

    @State private var editMode = false
    @State private var showAbandonConfirm = false
    @State private var nextBlock: EKEvent? = nil

    private var arenas: [Arena] { store.letteredArenas }
    private var sessions: [Session] { store.sessions }

    var body: some View {
        ZStack {
            // Ember particles background
            EmberParticles()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    if let event = nextBlock { nextBlockBanner(event: event) }
                    editToggle
                    arenaGrid
                    AppShortcutsBar()
                    intervalsSection
                    bottomButtons
                    footer
                }
            }

            // Ember drop overlay
            if let drop = pendingDrop {
                EmberDropModal(drop: drop) { pendingDrop = nil }
                    .transition(.opacity)
                    .zIndex(999)
            }

            // Session tray — foreground pill + stashed pills
            if store.activeSession != nil || !store.stackedSessions.isEmpty {
                VStack {
                    Spacer()
                    VStack(spacing: 6) {
                        // Egg bonus badge when multiple arenas stacked
                        if store.stackedSessions.count >= 1 {
                            HStack(spacing: 6) {
                                Text("◆")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color(hex: "#E8C547"))
                                Text("EGG BONUS ACTIVE — \(store.stackedSessions.count + (store.activeSession != nil ? 1 : 0)) ARENAS")
                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#E8C547").opacity(0.8))
                                    .kerning(2)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#E8C547").opacity(0.08))
                            .overlay(Capsule().strokeBorder(Color(hex: "#E8C547").opacity(0.25), lineWidth: 1))
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                        }

                        // Stashed sessions (shown above foreground)
                        ForEach(store.stackedSessions, id: \.arena.id) { stashed in
                            stackedPill(stashed)
                                .frame(maxWidth: .infinity)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Foreground session pill
                        if let active = store.activeSession {
                            timerPill(active)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: pendingDrop?.id)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: store.activeSession != nil)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: store.stackedSessions.count)
        .confirmationDialog("Abandon session?", isPresented: $showAbandonConfirm, titleVisibility: .visible) {
            Button("Abandon", role: .destructive) { store.endSession() }
            Button("Cancel", role: .cancel) { }
        }
        .onAppear {
            refreshNextBlock()
            // Start idle Live Activity when no session is running
            if store.activeSession == nil {
                #if canImport(ActivityKit)
                store.startIdleActivity()
                #endif
            }
        }
    }

    private func refreshNextBlock() {
        guard CalendarManager.shared.isReadAuthorized else { nextBlock = nil; return }
        // Show only events starting within the next 90 minutes or already in progress
        let upcoming = CalendarManager.shared.upcomingEvents(hours: 2)
        nextBlock = upcoming.first(where: { event in
            let minsUntil = Int(event.startDate.timeIntervalSinceNow / 60)
            return minsUntil <= 90
        })
    }

    @ViewBuilder
    private func nextBlockBanner(event: EKEvent) -> some View {
        let dur = event.startDate.minutesUntil(event.endDate)
        let when = event.startDate.relativeShort()
        let matched = CalendarManager.shared.matchArena(for: event, arenas: store.arenas)
        let accent: Color = matched.map { Color(hex: $0.color) } ?? Color(hex: "#60A5FA")

        Button {
            if let arena = matched {
                navigate(.select(arena))
            }
        } label: {
            HStack(spacing: 12) {
                Text("📅")
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text((event.title ?? "Upcoming Block").uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent)
                        .kerning(2)
                        .lineLimit(1)
                    Text("\(when)  ·  \(dur)m\(matched != nil ? "  ·  \(matched!.label)" : "")")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(1)
                }
                Spacer()
                if matched != nil {
                    Text("START →")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent.opacity(0.7))
                        .kerning(3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(accent.opacity(0.07))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accent.opacity(0.2), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .disabled(matched == nil)
    }

    // MARK: - Timer Pill

    private func timerPill(_ active: ActiveSessionState) -> some View {
        let arenaColor = Color(hex: active.arena.color)

        return HStack(spacing: 0) {
            // Left: dot + label
            HStack(spacing: 8) {
                Circle()
                    .fill(arenaColor)
                    .frame(width: 12, height: 12)
                Text(active.arena.label)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.leading, 16)

            Spacer()

            // Center separator
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 24)

            // Right: live countdown
            Text(active.endTime, style: .timer)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(arenaColor)
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
                .padding(.horizontal, 10)
        }
        .frame(width: 280, height: 56)
        .background(Color.cardBg)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(arenaColor, lineWidth: 1))
        .onTapGesture {
            navigate(.active(active.arena, active.durationMins, active.note))
        }
        .overlay(alignment: .trailing) {
            Button { showAbandonConfirm = true } label: {
                Text("✕")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .padding(.horizontal, 16)
                    .frame(height: 56)
            }
            .buttonStyle(.plain)
        }
    }

    private func stackedPill(_ session: ActiveSessionState) -> some View {
        let arenaColor = Color(hex: session.arena.color)
        return HStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(arenaColor.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text(session.arena.label)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.leading, 16)

            Spacer()

            Text(session.endTime, style: .timer)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(arenaColor.opacity(0.6))
                .monospacedDigit()
                .frame(width: 64)
                .padding(.horizontal, 10)
        }
        .frame(width: 280, height: 42)
        .background(Color.cardBg.opacity(0.7))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(arenaColor.opacity(0.35), lineWidth: 1))
        .onTapGesture {
            store.unstashSession(arenaId: session.arena.id)
            if let active = store.activeSession {
                navigate(.active(active.arena, active.durationMins, active.note))
            }
        }
        .overlay(alignment: .trailing) {
            Button {
                store.abandonStackedSession(arenaId: session.arena.id)
            } label: {
                Text("✕")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .padding(.horizontal, 14)
                    .frame(height: 42)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ARENA PROTOCOL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(6)

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
                topButton("IDEA !", color: "#E8C547")  { navigate(.notes)   }
                topButton("STATS",  color: "#B794F4")  { navigate(.history) }
                topButton("⚙",      color: "rgba(255,255,255,0.4)") { navigate(.settings) }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 44)
        .padding(.bottom, 12)
    }

    private func topButton(_ label: String, color: String, action: @escaping () -> Void) -> some View {
        let c = color.hasPrefix("rgba") ? Color.white.opacity(0.4) : Color(hex: color)
        return Button(action: action) {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(c)
                .kerning(2)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
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
            Button {
                withAnimation { editMode.toggle() }
            } label: {
                Text(editMode ? "DONE EDITING" : "EDIT ARENAS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(editMode ? Color(hex: "#E8C547") : Color.white.opacity(0.25))
                    .kerning(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(editMode ? Color(hex: "#E8C547").opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(editMode ? Color(hex: "#E8C547").opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Arena Grid

    private var arenaGrid: some View {
        Group {
            if editMode {
                editReorderList
            } else {
                twoColumnGrid
            }
        }
        .animation(.spring(response: 0.4), value: editMode)
    }

    private var editReorderList: some View {
        VStack(spacing: 0) {
            List {
                ForEach(arenas) { arena in
                    HStack(spacing: 12) {
                        Text(arena.icon)
                            .font(.system(size: 20))
                        Circle()
                            .fill(Color(hex: arena.color))
                            .frame(width: 7, height: 7)
                        Text(arena.label)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .kerning(1)
                        Spacer()
                        Button { navigate(.editArena(arena)) } label: {
                            Text("EDIT")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color(hex: arena.color).opacity(0.7))
                                .kerning(2)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.03))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(hex: arena.color).opacity(0.18), lineWidth: 1))
                            .padding(.vertical, 2)
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 3, leading: 12, bottom: 3, trailing: 12))
                }
                .onMove { from, to in
                    store.arenas.move(fromOffsets: from, toOffset: to)
                    store.saveArenas()
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .environment(\.editMode, .constant(.active))
            .frame(height: CGFloat(arenas.count) * 68)

            AddArenaCardView { navigate(.newArena) }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
    }

    private var twoColumnGrid: some View {
        let left  = Array(arenas.prefix(Int(ceil(Double(arenas.count) / 2))))
        let right = Array(arenas.suffix(arenas.count - left.count))

        return HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 10) {
                ForEach(left) { arena in
                    ArenaCardView(
                        arena: arena,
                        sessCount: sessions.filter { $0.arenaId == arena.id && $0.date == todayString() }.count,
                        streak: store.streak(for: arena.id),
                        editMode: false,
                        onTap: { navigate(.select(arena)) },
                        sessions: sessions
                    )
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                        withAnimation(.spring(response: 0.3)) { editMode = true }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    })
                    .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 18)), removal: .opacity))
                }
            }
            VStack(spacing: 10) {
                ForEach(right) { arena in
                    ArenaCardView(
                        arena: arena,
                        sessCount: sessions.filter { $0.arenaId == arena.id && $0.date == todayString() }.count,
                        streak: store.streak(for: arena.id),
                        editMode: false,
                        onTap: { navigate(.select(arena)) },
                        sessions: sessions
                    )
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                        withAnimation(.spring(response: 0.3)) { editMode = true }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    })
                    .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 18)), removal: .opacity))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Intervals Section

    private var intervalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("INTERVALS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(6)
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
                                Text(preset.icon)
                                    .font(.system(size: 18))
                                Text(preset.label)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#4ECDC4"))
                                    .kerning(2)
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
            // Protocols
            Button { navigate(.protocols) } label: {
                HStack(spacing: 10) {
                    Text("◈").font(.system(size: 11)).foregroundStyle(Color(hex: "#708090"))
                    Text("PROTOCOLS").font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#708090")).kerning(4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "#708090").opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#708090").opacity(0.2), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            // I AM STUCK
            Button { navigate(.stuck) } label: {
                HStack(spacing: 10) {
                    Text("⚡").font(.system(size: 13)).foregroundStyle(Color(hex: "#FF8FA3"))
                    Text("I AM STUCK").font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#FF8FA3")).kerning(4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#FF8FA3").opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#FF8FA3").opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("SELECT AN ARENA")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.3))
                .kerning(2)
            Spacer()
            Button { navigate(.checkin) } label: {
                Text("☀ MORNING")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .kerning(2)
            }
            .buttonStyle(.plain)
            Button { navigate(.winddown) } label: {
                Text("☾ WIND DOWN")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .kerning(2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .top) {
            Divider().background(Color.white.opacity(0.05))
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Ember Particles

struct EmberParticles: View {
    private struct Particle: Identifiable {
        let id = UUID()
        let xFraction: Double
        let delay: Double
        let duration: Double
        let color: String
    }

    private let particles: [Particle] = [
        Particle(xFraction: 0.12, delay: 0.0, duration: 7.0, color: "#E8C547"),
        Particle(xFraction: 0.28, delay: 1.8, duration: 9.0, color: "#C0392B"),
        Particle(xFraction: 0.55, delay: 0.6, duration: 8.0, color: "#D4A017"),
        Particle(xFraction: 0.72, delay: 3.0, duration: 6.5, color: "#E8C547"),
        Particle(xFraction: 0.88, delay: 1.2, duration: 10.0,color: "#B87333"),
        Particle(xFraction: 0.42, delay: 4.0, duration: 7.5, color: "#708090"),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                EmberParticle(color: Color(hex: p.color), xPos: geo.size.width * p.xFraction, delay: p.delay, duration: p.duration, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct EmberParticle: View {
    let color: Color
    let xPos: CGFloat
    let delay: Double
    let duration: Double
    let height: CGFloat

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0.22

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 3, height: 3)
            .blur(radius: 0.5)
            .shadow(color: color, radius: 3)
            .position(x: xPos, y: height - 10 + offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation.easeIn(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    offset = -height * 1.1
                    opacity = 0
                }
            }
    }
}
