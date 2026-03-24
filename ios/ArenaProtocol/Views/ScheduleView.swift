// ScheduleView.swift — Arena Protocol
// Manage scheduled session blocks and arena deadlines

import SwiftUI

// MARK: - Schedule View

struct ScheduleView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var showingAddBlock    = false
    @State private var showingAddDeadline = false

    private var upcomingBlocks: [ScheduledBlock] {
        store.scheduledBlocks
            .filter { $0.scheduledAt > Date() }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private var activeDeadlines: [ArenaDeadline] {
        store.deadlines
            .filter { !$0.isCompleted }
            .sorted { $0.targetDate < $1.targetDate }
    }

    private var completedDeadlines: [ArenaDeadline] {
        store.deadlines
            .filter { $0.isCompleted }
            .sorted { ($0.targetDate) > ($1.targetDate) }
    }

    var body: some View {
        ZStack {
            Color(hex: "#080810").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    if upcomingBlocks.isEmpty && activeDeadlines.isEmpty {
                        emptyState
                    } else {
                        if !upcomingBlocks.isEmpty { blocksSection }
                        if !activeDeadlines.isEmpty { deadlinesSection }
                        if !completedDeadlines.isEmpty { completedSection }
                    }

                    addButtons
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingAddBlock) {
            AddScheduledBlockSheet(arenas: store.arenas, protocols: store.protocols) { block in
                store.addScheduledBlock(block)
            }
        }
        .sheet(isPresented: $showingAddDeadline) {
            AddDeadlineSheet(arenas: store.arenas) { deadline in
                store.addDeadline(deadline)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button { navigate(.home) } label: {
                Text("← BACK")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .kerning(4)
            }
            .buttonStyle(.plain)
            .padding(.top, 48)
            .padding(.bottom, 28)

            Text("PLAN YOUR WORK")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.25))
                .kerning(7)
            Text("SCHEDULE")
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .kerning(2)
            Text("Scheduled sessions and arena deadlines.")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.3))
                .lineSpacing(4)
                .padding(.top, 4)
        }
        .padding(.bottom, 28)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("⏰")
                .font(.system(size: 32))
                .opacity(0.25)
                .padding(.top, 48)
            Text("NOTHING SCHEDULED")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.2))
                .kerning(4)
            Text("Add a scheduled block to get a notification\nat the right time, or set an arena deadline.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.15))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 36)
    }

    // MARK: - Upcoming Blocks

    private var blocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UPCOMING")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(6)

            ForEach(upcomingBlocks) { block in
                scheduledBlockCard(block)
            }
        }
        .padding(.bottom, 28)
    }

    private func scheduledBlockCard(_ block: ScheduledBlock) -> some View {
        let color = Color(hex: block.itemColor)
        let secsUntil = block.scheduledAt.timeIntervalSinceNow
        let when = block.scheduledAt.relativeShort()

        return HStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(block.itemGlyph)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
            }
            .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(block.itemLabel.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                        .kerning(2)
                    Text(block.kind == .arena ? "ARENA" : "PROTOCOL")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(color.opacity(0.6))
                        .kerning(2)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(color.opacity(0.12))
                        .clipShape(Capsule())
                }
                HStack(spacing: 8) {
                    Text(secsUntil < 86400 ? when : block.scheduledAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .kerning(1)
                    if block.durationMins > 0 {
                        Text("·  \(block.durationMins)m")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                    }
                }
                if !block.note.isEmpty {
                    Text(block.note)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                startButton(for: block)

                Button { store.removeScheduledBlock(id: block.id) } label: {
                    Text("×")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .frame(width: 28, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(color.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(color.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func startButton(for block: ScheduledBlock) -> some View {
        let color = Color(hex: block.itemColor)
        if block.kind == .arena,
           let arena = store.arenas.first(where: { $0.id == block.itemId }) {
            Button {
                store.removeScheduledBlock(id: block.id)
                store.expandedArenaId = arena.id
                navigate(.home)
            } label: {
                Text("START")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(color).kerning(2)
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
        } else if block.kind == .arenaProtocol,
                  let proto = store.protocols.first(where: { $0.id == block.itemId }) {
            Button {
                store.removeScheduledBlock(id: block.id)
                navigate(.activeProtocol(proto))
            } label: {
                Text("START")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(color).kerning(2)
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Deadlines

    private var deadlinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEADLINES")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(6)

            ForEach(activeDeadlines) { deadline in
                deadlineCard(deadline)
            }
        }
        .padding(.bottom, 28)
    }

    private func deadlineCard(_ deadline: ArenaDeadline) -> some View {
        let color = Color(hex: deadline.arenaColor)
        let done = store.sessions.filter { $0.arenaId == deadline.arenaId }.count
        let progress = min(1.0, Double(done) / Double(max(1, deadline.targetSessions)))
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: deadline.targetDate))
        let daysLeft = components.day ?? 0
        let isOverdue = deadline.targetDate < Date()
        let alertColor = isOverdue ? Color(hex: "#FF8FA3") : (daysLeft <= 2 ? Color(hex: "#F59E0B") : color)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(deadline.arenaLabel.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                        .kerning(2)
                    HStack(spacing: 8) {
                        Text("\(done) / \(deadline.targetSessions) sessions")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .kerning(1)
                        Text("·")
                            .foregroundStyle(Color.white.opacity(0.2))
                        Text(isOverdue ? "OVERDUE" : daysLeft == 0 ? "DUE TODAY" : "\(daysLeft)d left")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(alertColor)
                            .kerning(2)
                    }
                    if !deadline.note.isEmpty {
                        Text(deadline.note)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button { store.removeDeadline(id: deadline.id) } label: {
                    Text("×")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(alertColor.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(progress), height: 5)
                }
            }
            .frame(height: 5)

            Text("DUE  \(deadline.targetDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(alertColor.opacity(isOverdue ? 0.8 : 0.4))
                .kerning(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(color.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(alertColor.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Completed Deadlines

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPLETED")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.15))
                .kerning(6)

            ForEach(completedDeadlines.prefix(3)) { deadline in
                HStack(spacing: 12) {
                    Text("✓")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: deadline.arenaColor).opacity(0.5))
                    Text(deadline.arenaLabel.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(2)
                    Text("· \(deadline.targetSessions) sessions")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.15))
                    Spacer()
                    Button { store.removeDeadline(id: deadline.id) } label: {
                        Text("×")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.15))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.02))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.05), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.bottom, 28)
    }

    // MARK: - Add Buttons

    private var addButtons: some View {
        HStack(spacing: 8) {
            Button { showingAddBlock = true } label: {
                HStack(spacing: 6) {
                    Text("+").font(.system(size: 14, weight: .bold, design: .monospaced))
                    Text("SCHEDULE BLOCK")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .kerning(3)
                }
                .foregroundStyle(Color(hex: "#E8C547"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color(hex: "#E8C547").opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: "#E8C547").opacity(0.3), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Button { showingAddDeadline = true } label: {
                HStack(spacing: 6) {
                    Text("+").font(.system(size: 14, weight: .bold, design: .monospaced))
                    Text("DEADLINE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .kerning(3)
                }
                .foregroundStyle(Color.white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Add Scheduled Block Sheet

struct AddScheduledBlockSheet: View {
    let arenas: [Arena]
    let protocols: [ArenaProtocolModel]
    let onAdd: (ScheduledBlock) -> Void

    @Environment(\.dismiss) private var dismiss

    enum ItemKind: String, CaseIterable {
        case arena = "Arena"
        case arenaProtocol = "Protocol"
    }

    @State private var kind: ItemKind = .arena
    @State private var selectedArenaId:    String = ""
    @State private var selectedProtocolId: String = ""
    @State private var scheduledAt:  Date = Date().addingTimeInterval(3600)
    @State private var durationMins: Int  = 25
    @State private var note: String = ""

    private var effectiveArena: Arena? {
        arenas.first { $0.id == selectedArenaId } ?? arenas.first
    }
    private var effectiveProtocol: ArenaProtocolModel? {
        protocols.first { $0.id == selectedProtocolId } ?? protocols.first
    }
    private var protocolDuration: Int {
        effectiveProtocol?.blocks.reduce(0) { $0 + $1.duration } ?? 0
    }
    private var canAdd: Bool {
        kind == .arena ? !arenas.isEmpty : !protocols.isEmpty
    }

    var body: some View {
        ZStack {
            Color(hex: "#080810").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    HStack {
                        Text("SCHEDULE BLOCK")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .kerning(7)
                        Spacer()
                        Button { dismiss() } label: {
                            Text("×")
                                .font(.system(size: 20, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.35))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 24)

                    // Kind toggle
                    HStack(spacing: 0) {
                        ForEach(ItemKind.allCases, id: \.self) { k in
                            Button { kind = k } label: {
                                Text(k.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(kind == k ? Color(hex: "#E8C547") : Color.white.opacity(0.3))
                                    .kerning(3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(kind == k ? Color(hex: "#E8C547").opacity(0.1) : .clear)
                                    .animation(.easeInOut(duration: 0.15), value: kind)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Item picker
                    if kind == .arena {
                        itemPickerSection(label: "ARENA") {
                            ForEach(arenas) { arena in
                                let isSelected = selectedArenaId == arena.id ||
                                    (selectedArenaId.isEmpty && arena.id == arenas.first?.id)
                                let c = Color(hex: arena.color)
                                Button { selectedArenaId = arena.id } label: {
                                    itemRow(glyph: arena.icon, label: arena.label,
                                            detail: nil, color: c, isSelected: isSelected)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        labeledSection("DURATION") {
                            Stepper("\(durationMins) min", value: $durationMins, in: 5...180, step: 5)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                    } else {
                        itemPickerSection(label: "PROTOCOL") {
                            if protocols.isEmpty {
                                Text("No protocols yet — create one from Protocols.")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.3))
                            } else {
                                ForEach(protocols) { p in
                                    let isSelected = selectedProtocolId == p.id ||
                                        (selectedProtocolId.isEmpty && p.id == protocols.first?.id)
                                    let c = Color(hex: p.color)
                                    let total = p.blocks.reduce(0) { $0 + $1.duration }
                                    Button { selectedProtocolId = p.id } label: {
                                        itemRow(glyph: p.glyph, label: p.name,
                                                detail: "\(total)m total", color: c, isSelected: isSelected)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Date / time
                    labeledSection("WHEN") {
                        DatePicker("", selection: $scheduledAt, in: Date()...)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                    }

                    // Note
                    labeledSection("NOTE (OPTIONAL)") {
                        TextField("", text: $note)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Confirm
                    Button {
                        let block = buildBlock()
                        onAdd(block)
                        dismiss()
                    } label: {
                        Text("SCHEDULE →")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#E8C547"))
                            .kerning(4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(hex: "#E8C547").opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(hex: "#E8C547").opacity(0.5), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAdd)
                    .opacity(canAdd ? 1 : 0.4)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 40)
            }
        }
    }

    private func buildBlock() -> ScheduledBlock {
        switch kind {
        case .arena:
            let a = effectiveArena!
            return ScheduledBlock(kind: .arena, itemId: a.id, itemLabel: a.label,
                                  itemGlyph: a.icon, itemColor: a.color,
                                  scheduledAt: scheduledAt, durationMins: durationMins, note: note)
        case .arenaProtocol:
            let p = effectiveProtocol!
            return ScheduledBlock(kind: .arenaProtocol, itemId: p.id, itemLabel: p.name,
                                  itemGlyph: p.glyph, itemColor: p.color,
                                  scheduledAt: scheduledAt, durationMins: protocolDuration, note: note)
        }
    }

    // MARK: - Reusable sub-views

    @ViewBuilder
    private func itemPickerSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(label)
            content()
        }
    }

    @ViewBuilder
    private func labeledSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(label)
            content()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.25))
            .kerning(5)
    }

    private func itemRow(glyph: String, label: String, detail: String?,
                         color: Color, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Text(glyph).font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(isSelected ? color : Color.white.opacity(0.5))
                    .kerning(2)
                if let d = detail {
                    Text(d)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            Spacer()
            if isSelected {
                Text("✓").font(.system(size: 11, design: .monospaced)).foregroundStyle(color)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(isSelected ? color.opacity(0.1) : Color.white.opacity(0.03))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .strokeBorder(isSelected ? color.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Add Deadline Sheet

struct AddDeadlineSheet: View {
    let arenas: [Arena]
    let onAdd: (ArenaDeadline) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedArenaId: String = ""
    @State private var targetDate:     Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var targetSessions: Int  = 10
    @State private var note: String = ""

    private var effectiveArena: Arena? {
        arenas.first { $0.id == selectedArenaId } ?? arenas.first
    }

    var body: some View {
        ZStack {
            Color(hex: "#080810").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    HStack {
                        Text("SET DEADLINE")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .kerning(7)
                        Spacer()
                        Button { dismiss() } label: {
                            Text("×")
                                .font(.system(size: 20, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.35))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 24)

                    // Arena picker
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("ARENA")
                        ForEach(arenas) { arena in
                            let isSelected = selectedArenaId == arena.id ||
                                (selectedArenaId.isEmpty && arena.id == arenas.first?.id)
                            let c = Color(hex: arena.color)
                            Button { selectedArenaId = arena.id } label: {
                                HStack(spacing: 10) {
                                    Text(arena.icon).font(.system(size: 14))
                                    Text(arena.label)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(isSelected ? c : Color.white.opacity(0.5))
                                        .kerning(2)
                                    Spacer()
                                    if isSelected {
                                        Text("✓").font(.system(size: 11, design: .monospaced)).foregroundStyle(c)
                                    }
                                }
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(isSelected ? c.opacity(0.1) : Color.white.opacity(0.03))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(isSelected ? c.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Target sessions
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("TARGET SESSIONS")
                        Stepper("\(targetSessions) sessions", value: $targetSessions, in: 1...999, step: 1)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.white)
                    }

                    // Due date
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("DUE DATE")
                        DatePicker("", selection: $targetDate, in: Date()..., displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("NOTE (OPTIONAL)")
                        TextField("", text: $note)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Confirm
                    Button {
                        guard let a = effectiveArena else { return }
                        let deadline = ArenaDeadline(
                            arenaId: a.id, arenaLabel: a.label, arenaColor: a.color,
                            targetDate: targetDate, targetSessions: targetSessions, note: note
                        )
                        onAdd(deadline)
                        dismiss()
                    } label: {
                        Text("SET DEADLINE →")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .kerning(4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.white.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(arenas.isEmpty)
                    .opacity(arenas.isEmpty ? 0.4 : 1)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 40)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.25))
            .kerning(5)
    }
}
