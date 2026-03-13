// HomeView.swift — Arena Protocol
// Main dashboard with arena grid, shortcuts, and navigation

import SwiftUI

struct HomeView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void
    @Binding var pendingDrop: EmberDrop?

    @State private var editMode = false

    private var arenas: [Arena] { store.letteredArenas }
    private var sessions: [Session] { store.sessions }

    var body: some View {
        ZStack {
            // Ember particles background
            EmberParticles()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    editToggle
                    arenaGrid
                    AppShortcutsBar()
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
        }
        .animation(.easeInOut(duration: 0.25), value: pendingDrop?.id)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ARENA PROTOCOL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(6)

                Button { navigate(.home) } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ENTER THE")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .kerning(2)
                        Text("ARENA")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#E8C547"))
                            .kerning(2)
                    }
                }
                .buttonStyle(.plain)

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
        let left  = Array(arenas.prefix(Int(ceil(Double(arenas.count) / 2))))
        let right = Array(arenas.suffix(arenas.count - left.count))

        return HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 10) {
                ForEach(left) { arena in
                    ArenaCardView(
                        arena: arena,
                        sessCount: sessions.filter { $0.arenaId == arena.id && $0.date == todayString() }.count,
                        streak: store.streak(for: arena.id),
                        editMode: editMode,
                        onTap: { editMode ? navigate(.editArena(arena)) : navigate(.select(arena)) },
                        sessions: sessions
                    )
                    .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 18)), removal: .opacity))
                }
                if editMode {
                    AddArenaCardView { navigate(.newArena) }
                }
            }
            VStack(spacing: 10) {
                ForEach(right) { arena in
                    ArenaCardView(
                        arena: arena,
                        sessCount: sessions.filter { $0.arenaId == arena.id && $0.date == todayString() }.count,
                        streak: store.streak(for: arena.id),
                        editMode: editMode,
                        onTap: { editMode ? navigate(.editArena(arena)) : navigate(.select(arena)) },
                        sessions: sessions
                    )
                    .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 18)), removal: .opacity))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.4), value: editMode)
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
