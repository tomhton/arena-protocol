// ProfileView.swift — Arena Protocol
// Player profile: equipped title, global streak, arena breakdown, rebirth path.

import SwiftUI

struct ProfileView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Back
                Button { navigate(.home) } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 48)
                .padding(.bottom, 28)

                // Header
                headerSection

                Divider()
                    .background(Color.white.opacity(0.06))
                    .padding(.vertical, 28)

                // Arena breakdown
                arenasSection

                Divider()
                    .background(Color.white.opacity(0.06))
                    .padding(.vertical, 28)

                // Rebirth path
                rebirthSection

                // Inventory link
                inventoryLink
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        let profile  = store.sessionProfile
        let title    = store.playerProfile.equippedTitle
        let equipped = store.inventory.first { $0.isEquipped && $0.type == .title }

        return VStack(alignment: .leading, spacing: 4) {
            Text("FORGE PROFILE")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(7)
                .padding(.bottom, 4)

            if let t = title ?? equipped?.name {
                Text(t.uppercased())
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#E8C547"))
                    .kerning(3)
            } else {
                Text("UNNAMED FORGE")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .kerning(3)
            }

            Text("\(profile.totalSessions) SESSIONS TOTAL")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.28))
                .kerning(3)
                .padding(.top, 2)

            // Global streak
            if profile.currentGlobalStreak > 0 {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 13))
                    Text("\(profile.currentGlobalStreak)-DAY STREAK")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#E8C547"))
                        .kerning(3)
                    if profile.longestGlobalStreak > profile.currentGlobalStreak {
                        Text("· BEST \(profile.longestGlobalStreak)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.22))
                            .kerning(2)
                    }
                }
                .padding(.top, 6)
            }

            // Archetype badge
            archetypeBadge(profile.archetype)
                .padding(.top, 8)
        }
    }

    private func archetypeBadge(_ archetype: UserArchetype) -> some View {
        let (label, color) = archetypeInfo(archetype)
        return Text(label)
            .font(.system(size: 8, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color(hex: color))
            .kerning(3)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: color).opacity(0.12))
            .overlay(Capsule().strokeBorder(Color(hex: color).opacity(0.3), lineWidth: 1))
            .clipShape(Capsule())
    }

    private func archetypeInfo(_ a: UserArchetype) -> (String, String) {
        switch a {
        case .newcomer:     return ("NEWCOMER",      "#708090")
        case .returning:    return ("RETURNING",     "#B794F4")
        case .recovering:   return ("RECOVERING",    "#FF8FA3")
        case .sprinter:     return ("SPRINTER",      "#E8C547")
        case .deepWorker:   return ("DEEP WORKER",   "#34D399")
        case .streakChaser: return ("STREAK CHASER", "#F97316")
        case .specialist:   return ("SPECIALIST",    "#60A5FA")
        case .balancer:     return ("BALANCER",      "#A78BFA")
        case .veteran:      return ("VETERAN",       "#E8C547")
        case .surging:      return ("SURGING",       "#34D399")
        }
    }

    // MARK: - Arenas Section

    private var arenasSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("ARENAS", count: store.arenas.count)

            VStack(spacing: 8) {
                ForEach(store.arenas) { arena in
                    arenaRow(arena)
                }
            }
        }
    }

    private func arenaRow(_ arena: Arena) -> some View {
        let color      = Color(hex: arena.color)
        let count      = store.sessions.filter { $0.arenaId == arena.id }.count
        let streak     = store.streak(for: arena.id)
        let rebirth    = store.rebirthState(for: arena.id)
        let islandLvl  = rebirth?.islandLevel ?? 0
        let equippedGlyph = store.equippedGlyph(for: arena.id)

        return HStack(spacing: 12) {
            // Letter badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Text(arena.letter)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(arena.label)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .kerning(1)
                    if let glyph = equippedGlyph {
                        Text(glyph)
                            .font(.system(size: 11))
                    }
                    if islandLvl > 0 {
                        Text("ISLAND \(islandLvl)")
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .foregroundStyle(color.opacity(0.7))
                            .kerning(2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 10) {
                    Text("\(count) SESSIONS")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.28))
                        .kerning(2)
                    if streak > 0 {
                        Text("· \(streak)🔥")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(color.opacity(0.6))
                            .kerning(1)
                    }
                }
            }

            Spacer()

            // Mini progress toward next rebirth
            if count > 0 {
                let sessionsThisLife = count - (rebirth?.totalSessionsAllTime ?? 0)
                let fraction = min(1.0, Double(sessionsThisLife) / 111.0)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(fraction * 100))%")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(color.opacity(0.4))
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 40, height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.6))
                            .frame(width: 40 * CGFloat(fraction), height: 3)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.025))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(color.opacity(0.12), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Rebirth Section

    private var rebirthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("REBIRTH PATH", count: nil)

            Text("Each arena rebirths after 111 sessions. Reach Island 10 to unlock the Echo egg tier.")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.25))
                .lineSpacing(5)
                .padding(.bottom, 4)

            VStack(spacing: 8) {
                ForEach(store.rebirthStates.sorted { $0.islandLevel > $1.islandLevel }, id: \.arenaId) { state in
                    rebirthRow(state)
                }
            }

            if store.rebirthStates.isEmpty {
                Text("No rebirths yet. Keep forging.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.15))
                    .padding(.vertical, 12)
            }
        }
    }

    private func rebirthRow(_ state: RebirthState) -> some View {
        let arena = store.arenas.first { $0.id == state.arenaId }
        let color = arena.map { Color(hex: $0.color) } ?? Color.white
        let maxIsland = state.islandLevel >= 10

        return HStack(spacing: 12) {
            Text("◈")
                .font(.system(size: 14))
                .foregroundStyle(color.opacity(0.7))

            VStack(alignment: .leading, spacing: 3) {
                Text(arena?.label ?? state.arenaId)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .kerning(1)
                Text("\(state.rebirthDates.count) REBIRTHS · \(state.totalSessionsAllTime) LIFETIME SESSIONS")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("ISLAND \(state.islandLevel)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(maxIsland ? Color(hex: "#34D399") : color)
                    .kerning(2)
                if maxIsland {
                    Text("MAX")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(Color(hex: "#34D399").opacity(0.6))
                        .kerning(2)
                }
            }
        }
        .padding(14)
        .background(color.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(color.opacity(0.15), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Inventory Link

    private var inventoryLink: some View {
        Button { navigate(.inventory) } label: {
            HStack(spacing: 10) {
                Text("⬡").font(.system(size: 13)).foregroundStyle(Color(hex: "#B794F4"))
                Text("OPEN INVENTORY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#B794F4"))
                    .kerning(4)
                Spacer()
                Text("\(store.inventory.count) ITEMS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color(hex: "#B794F4").opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(hex: "#B794F4").opacity(0.2), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, count: Int?) -> some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(6)
            if let n = count, n > 0 {
                Text("\(n)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
    }
}
