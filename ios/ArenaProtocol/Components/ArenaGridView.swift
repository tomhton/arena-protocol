// ArenaGridView.swift — Arena Protocol
// Edit toggle + two-column grid + reorder list, extracted from HomeView

import SwiftUI

struct ArenaGridView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void
    @Binding var editMode: Bool
    @Binding var hapticMedium: Int
    @Binding var hapticLight: Int

    @State private var longPressedArenaId: String? = nil
    @State private var draggingId: String? = nil
    @State private var dragTargetIdx: Int = -1
    private let reorderRowH: CGFloat = 62

    private var arenas: [Arena] { store.letteredArenas }
    private var sessions: [Session] { store.sessions }

    var body: some View {
        VStack(spacing: 0) {
            editToggle
            arenaGrid
                .padding(.bottom, 20)
        }
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
                    .padding(.horizontal, 12).padding(.vertical, 4)
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

        return VStack(spacing: 7) {
            HStack(alignment: .top, spacing: 7) {
                VStack(spacing: 7) {
                    ForEach(left) { arena in
                        arenaCardWithExpansion(arena: arena)
                    }
                }
                VStack(spacing: 7) {
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
            hapticMedium += 1
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
                                hapticMedium += 1
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
                                hapticLight += 1
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
                        .foregroundStyle(c.opacity(0.55))
                        .kerning(1)
                }
            }

            Spacer()

            Button { navigate(.editArena(arena)) } label: {
                Text("EDIT")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(c.opacity(0.65))
                    .kerning(2)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(c.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
}
