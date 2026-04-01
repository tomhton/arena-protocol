// InventoryView.swift — Arena Protocol
// Egg incubation progress, hatched item grid, locked item preview.

import SwiftUI

// MARK: - Inventory filter tabs

private enum InventoryFilter: String, CaseIterable {
    case all      = "ALL"
    case skins    = "SKINS"
    case titles   = "TITLES"
    case glyphs   = "GLYPHS"
    case auras    = "AURAS"
    case echo     = "ECHO"

    func matches(_ item: InventoryItem) -> Bool {
        switch self {
        case .all:    return true
        case .skins:  return item.type == .skin
        case .titles: return item.type == .title || item.type == .fragment
        case .glyphs: return item.type == .glyph || item.type == .badge
        case .auras:  return item.type == .aura
        case .echo:   return item.type == .echo
        }
    }
}

// MARK: - View

struct InventoryView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var filter: InventoryFilter = .all
    @State private var hatchConfirm: InventoryEgg? = nil
    @State private var justHatched: InventoryItem? = nil

    private var incubating: [InventoryEgg] { store.eggs.filter { !$0.isHatched } }
    private var hatched: [InventoryItem] { store.inventory.filter { filter.matches($0) } }

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
                Text("FORGE INVENTORY")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(7)
                    .padding(.bottom, 4)
                Text("INVENTORY")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .kerning(2)
                Text("Eggs progress over sessions.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.28))
                    .padding(.top, 4)
                    .padding(.bottom, 32)

                // INCUBATING
                incubatingSection

                // HATCHED
                if !store.inventory.isEmpty {
                    hatchedSection
                }

                // WHAT IS POSSIBLE
                possibleSection
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 40)
        }
        .overlay {
            if let item = justHatched {
                hatchReveal(item: item)
            }
        }
        .confirmationDialog(
            "HATCH THIS EGG?",
            isPresented: Binding(
                get: { hatchConfirm != nil },
                set: { if !$0 { hatchConfirm = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let egg = hatchConfirm {
                Button("Hatch \(egg.rarity.displayName) Egg") {
                    store.hatchEgg(egg)
                    justHatched = store.inventory.last
                    hatchConfirm = nil
                }
                Button("Cancel", role: .cancel) { hatchConfirm = nil }
            }
        } message: {
            if let egg = hatchConfirm {
                Text("You'll receive a \(egg.rarity.displayName.lowercased()) reward. This can't be undone.")
            }
        }
    }

    // MARK: - Incubating Section

    private var incubatingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("INCUBATING", count: incubating.count)

            if incubating.isEmpty {
                Text("No eggs incubating. Complete sessions to earn drops.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(incubating) { egg in
                    eggCard(egg)
                }
            }
        }
        .padding(.bottom, 32)
    }

    private func eggCard(_ egg: InventoryEgg) -> some View {
        let progress  = store.eggProgress(egg)
        let threshold = egg.hatchThreshold
        let fraction  = min(1.0, Double(progress) / Double(max(1, threshold)))
        let ready     = store.isEggReady(egg)
        let color     = Color(hex: egg.rarity.hexColor)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(egg.rarity.glyph)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.7), radius: 6)
                VStack(alignment: .leading, spacing: 3) {
                    Text(egg.rarity.displayName)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                        .kerning(3)
                    Text(ready ? "READY TO HATCH" : "\(progress) / \(threshold) sessions")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(ready ? color : Color.white.opacity(0.3))
                        .kerning(2)
                }
                Spacer()
                if !egg.sourceTrigger.isEmpty {
                    Text(egg.sourceTrigger
                            .replacingOccurrences(of: "egg_", with: "")
                            .replacingOccurrences(of: "_", with: " ")
                            .uppercased())
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .kerning(1)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ready ? color : color.opacity(0.6))
                        .frame(width: geo.size.width * CGFloat(fraction), height: 5)
                        .animation(.easeInOut(duration: 0.4), value: fraction)
                }
            }
            .frame(height: 5)

            if ready {
                Button { hatchConfirm = egg } label: {
                    Text("HATCH →")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(4)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(color)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(color.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(color.opacity(ready ? 0.6 : 0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.3), value: ready)
    }

    // MARK: - Hatched Section

    private var hatchedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("HATCHED", count: store.inventory.count)

            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(InventoryFilter.allCases, id: \.self) { f in
                        Button { filter = f } label: {
                            Text(f.rawValue)
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(filter == f ? Color(hex: "#080810") : Color.white.opacity(0.4))
                                .kerning(3)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(filter == f ? Color.white.opacity(0.85) : Color.white.opacity(0.05))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 4)

            if hatched.isEmpty {
                Text("No items in this category.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(hatched) { item in
                        inventoryItemCard(item)
                    }
                }
            }
        }
        .padding(.bottom, 32)
    }

    private func inventoryItemCard(_ item: InventoryItem) -> some View {
        let color   = Color(hex: item.rarity.hexColor)
        let equipped = item.isEquipped

        return VStack(spacing: 10) {
            Text(item.glyph)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.6), radius: 8)

            VStack(spacing: 3) {
                Text(item.name)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .kerning(2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(item.rarity.displayName)
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(2)
            }

            if item.type == .skin {
                skinEquipSection(item: item, color: color)
            } else if item.type == .title || item.type == .aura {
                Button {
                    if equipped { store.unequipItem(item) } else { store.equipItem(item) }
                } label: {
                    Text(equipped ? "✓ EQUIPPED" : "EQUIP")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(equipped ? Color(hex: "#080810") : color)
                        .kerning(2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(equipped ? color : color.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: equipped)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(color.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .strokeBorder(equipped ? color.opacity(0.7) : color.opacity(0.18), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    /// Per-arena equip picker for skin items
    private func skinEquipSection(item: InventoryItem, color: Color) -> some View {
        let allArenas = store.letteredArenas + [store.socialArena]
        let assignedTo = store.playerProfile.equippedSkins.filter { $0.value == item.name }.map(\.key)

        return VStack(spacing: 6) {
            if assignedTo.isEmpty {
                Text("TAP ARENA TO EQUIP")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .kerning(2)
            } else {
                Text("EQUIPPED")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.7))
                    .kerning(2)
            }

            // Arena icon row
            HStack(spacing: 4) {
                ForEach(allArenas, id: \.id) { arena in
                    let isAssigned = assignedTo.contains(arena.id)
                    let arenaColor = Color(hex: arena.color)
                    Button {
                        if isAssigned {
                            store.unequipSkin(from: arena.id)
                        } else {
                            store.equipSkin(item.name, to: arena.id)
                        }
                    } label: {
                        Text(arena.icon)
                            .font(.system(size: 12))
                            .frame(width: 26, height: 26)
                            .background(isAssigned ? arenaColor.opacity(0.25) : Color.white.opacity(0.04))
                            .overlay(RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(isAssigned ? arenaColor.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - What Is Possible

    private var possibleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("WHAT IS POSSIBLE", count: nil)

            VStack(spacing: 10) {
                ForEach([EggRarity.epic, .legendary, .echo], id: \.self) { rarity in
                    lockedPreviewRow(rarity: rarity)
                }
            }

            Text("Reach Rebirth Island 10 to unlock Echo →")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: "#34D399").opacity(0.4))
                .kerning(2)
                .padding(.top, 8)
        }
        .padding(.bottom, 32)
    }

    private func lockedPreviewRow(rarity: EggRarity) -> some View {
        let color = Color(hex: rarity.hexColor)
        let alreadyHatched = store.inventory.contains { $0.rarity == rarity }
        return HStack(spacing: 14) {
            Text(rarity.glyph)
                .font(.system(size: 18))
                .foregroundStyle(color.opacity(alreadyHatched ? 0.8 : 0.2))
            VStack(alignment: .leading, spacing: 3) {
                Text(rarity.displayName)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(alreadyHatched ? 0.9 : 0.25))
                    .kerning(3)
                Text(alreadyHatched ? "Unlocked" : "Locked — keep going")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .kerning(1)
            }
            Spacer()
            Text(alreadyHatched ? "✓" : "?")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(color.opacity(alreadyHatched ? 0.7 : 0.15))
        }
        .padding(16)
        .background(color.opacity(alreadyHatched ? 0.07 : 0.03))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(color.opacity(alreadyHatched ? 0.25 : 0.08), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Hatch reveal overlay

    private func hatchReveal(item: InventoryItem) -> some View {
        let color = Color(hex: item.rarity.hexColor)
        return ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("EGG HATCHED")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(color.opacity(0.7))
                    .kerning(7)
                Text(item.glyph)
                    .font(.system(size: 64))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.8), radius: 20)
                VStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                        .kerning(4)
                    Text(item.rarity.displayName)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(color.opacity(0.6))
                        .kerning(5)
                    Text(item.description)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 32)
                        .padding(.top, 4)
                }
                Button { withAnimation(.easeOut(duration: 0.2)) { justHatched = nil } } label: {
                    Text("CLAIM")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(color)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 40)
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
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
