// ProtocolsView.swift — Arena Protocol
// Protocol list + full builder (create/edit/delete) + active protocol runner

import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Protocols List

struct ProtocolsView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var editingProtocol: ArenaProtocolModel? = nil
    @State private var isCreating = false
    @State private var savedForgeIds: Set<String> = []

    private var protocols: [ArenaProtocolModel] { store.protocols }

    private var recommendations: [ArenaProtocolModel] {
        ForgeEngine.recommendProtocols(profile: store.sessionProfile, arenas: store.arenas)
    }

    var body: some View {
        if isCreating {
            ProtocolEditorView(
                existing: nil,
                arenas: store.arenas,
                onSave: { p in
                    store.protocols.append(p)
                    store.saveProtocols()
                    isCreating = false
                },
                onCancel: { isCreating = false },
                onDelete: nil
            )
        } else if let p = editingProtocol {
            ProtocolEditorView(
                existing: p,
                arenas: store.arenas,
                onSave: { updated in
                    if let idx = store.protocols.firstIndex(where: { $0.id == p.id }) {
                        store.protocols[idx] = updated
                        store.saveProtocols()
                    }
                    editingProtocol = nil
                },
                onCancel: { editingProtocol = nil },
                onDelete: {
                    store.protocols.removeAll { $0.id == p.id }
                    store.saveProtocols()
                    editingProtocol = nil
                }
            )
        } else {
            listView
        }
    }

    // MARK: - List

    private var listView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button { navigate(.home) } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 48)
                .padding(.bottom, 28)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CHAIN YOUR ARENAS")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .kerning(7)
                        Text("PROTOCOLS")
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .kerning(2)
                        Text("Back-to-back arenas. One progress bar.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .lineSpacing(4)
                            .padding(.top, 4)
                    }
                    Spacer()
                    Button { isCreating = true } label: {
                        HStack(spacing: 5) {
                            Text("+")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                            Text("NEW")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .kerning(3)
                        }
                        .foregroundStyle(Color(hex: "#E8C547"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#E8C547").opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(hex: "#E8C547").opacity(0.4), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 28)

                // AI recommendations
                if !recommendations.isEmpty {
                    forYouSection
                        .padding(.bottom, 28)
                }

                // User's protocols
                if !protocols.isEmpty {
                    Text("YOUR PROTOCOLS")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.22))
                        .kerning(6)
                        .padding(.bottom, 14)
                }

                VStack(spacing: 14) {
                    ForEach(protocols) { p in
                        protocolCard(p)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 32)
        }
    }

    // MARK: - FOR YOU section

    private var forYouSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("◈")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#E8C547").opacity(0.8))
                Text("FOR YOU")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(6)
                Spacer()
                Text("based on your patterns")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.15))
                    .kerning(1)
            }

            ForEach(recommendations) { p in
                forYouCard(p)
            }
        }
    }

    private func forYouCard(_ p: ArenaProtocolModel) -> some View {
        let total  = p.blocks.reduce(0) { $0 + $1.duration }
        let pColor = Color(hex: p.color)
        let isSaved = savedForgeIds.contains(p.id)

        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(p.glyph)
                            .font(.system(size: 18))
                            .foregroundStyle(pColor)
                            .shadow(color: pColor.opacity(0.6), radius: 6)
                        Text(p.name)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(pColor)
                            .kerning(3)
                    }
                    Text(p.description)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .lineSpacing(4)
                }
                Spacer()
                Text("◈ AI")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#E8C547").opacity(0.6))
                    .kerning(2)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#E8C547").opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(hex: "#E8C547").opacity(0.25), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Block strip
            GeometryReader { geo in
                HStack(spacing: 4) {
                    ForEach(p.blocks.indices, id: \.self) { i in
                        let b = p.blocks[i]
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: b.color).opacity(0.7))
                            .frame(width: max(8, geo.size.width * CGFloat(b.duration) / CGFloat(max(1, total)) - 4), height: 6)
                    }
                }
            }
            .frame(height: 6)

            // Block labels
            HStack {
                ForEach(p.blocks.indices, id: \.self) { i in
                    let b = p.blocks[i]
                    Text("\(b.label) \(b.duration)m")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(hex: b.color).opacity(0.8))
                        .kerning(1)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(total)m total")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .kerning(2)
            }

            // Actions
            HStack(spacing: 10) {
                // Save to library
                Button {
                    guard !isSaved else { return }
                    // Strip the _forge_ prefix so it becomes a regular user protocol
                    var saved = p
                    saved = ArenaProtocolModel(
                        id: UUID().uuidString,
                        name: p.name,
                        glyph: p.glyph,
                        color: p.color,
                        description: p.description,
                        blocks: p.blocks
                    )
                    store.protocols.append(saved)
                    store.saveProtocols()
                    savedForgeIds.insert(p.id)
                } label: {
                    Text(isSaved ? "✓ SAVED" : "SAVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(isSaved ? Color.white.opacity(0.3) : pColor)
                        .kerning(3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSaved ? Color.white.opacity(0.04) : pColor.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(isSaved ? Color.white.opacity(0.1) : pColor.opacity(0.4), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: isSaved)

                // Begin immediately
                Button { navigate(.activeProtocol(p)) } label: {
                    Text("BEGIN →")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(pColor)
                        .kerning(4)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(pColor.opacity(0.18))
                        .overlay(RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(pColor.opacity(0.6), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(pColor.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(hex: "#E8C547").opacity(0.3), pColor.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func protocolCard(_ p: ArenaProtocolModel) -> some View {
        let total = p.blocks.reduce(0) { $0 + $1.duration }
        let pColor = Color(hex: p.color)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(p.glyph)
                            .font(.system(size: 18))
                            .foregroundStyle(pColor)
                            .shadow(color: pColor.opacity(0.6), radius: 6)
                        Text(p.name)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(pColor)
                            .kerning(3)
                    }
                    Text(p.description)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .lineSpacing(4)
                }
                Spacer()
                Button { editingProtocol = p } label: {
                    Text("✎")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            // Block strip
            GeometryReader { geo in
                HStack(spacing: 4) {
                    ForEach(p.blocks.indices, id: \.self) { i in
                        let b = p.blocks[i]
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: b.color).opacity(0.7))
                            .frame(width: max(8, geo.size.width * CGFloat(b.duration) / CGFloat(max(1, total)) - 4), height: 6)
                    }
                }
            }
            .frame(height: 6)

            // Block labels
            HStack {
                ForEach(p.blocks.indices, id: \.self) { i in
                    let b = p.blocks[i]
                    Text("\(b.label) \(b.duration)m")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(hex: b.color).opacity(0.8))
                        .kerning(1)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(total)m total")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .kerning(2)
            }

            Button { navigate(.activeProtocol(p)) } label: {
                Text("BEGIN PROTOCOL →")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(pColor)
                    .kerning(4)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(pColor.opacity(0.18))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(pColor.opacity(0.5), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(pColor.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(pColor.opacity(0.25), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Protocol Editor (Create + Edit)

struct ProtocolEditorView: View {
    @Environment(DataStore.self) private var store

    let existing: ArenaProtocolModel?
    let arenas: [Arena]
    let onSave: (ArenaProtocolModel) -> Void
    let onCancel: () -> Void
    let onDelete: (() -> Void)?

    struct EditableBlock: Identifiable {
        let id = UUID()
        var arenaId: String
        var duration: Int
    }

    @State private var name: String
    @State private var glyph: String
    @State private var color: String
    @State private var desc: String
    @State private var blocks: [EditableBlock]

    private let colorPresets = [
        "#60A5FA", "#E8C547", "#34D399", "#A78BFA",
        "#F87171", "#FB923C", "#4ECDC4", "#F9A8D4"
    ]

    init(existing: ArenaProtocolModel?, arenas: [Arena],
         onSave: @escaping (ArenaProtocolModel) -> Void,
         onCancel: @escaping () -> Void,
         onDelete: (() -> Void)?) {
        self.existing  = existing
        self.arenas    = arenas
        self.onSave    = onSave
        self.onCancel  = onCancel
        self.onDelete  = onDelete
        _name  = State(initialValue: existing?.name ?? "")
        _glyph = State(initialValue: existing?.glyph ?? "◈")
        _color = State(initialValue: existing?.color ?? "#E8C547")
        _desc  = State(initialValue: existing?.description ?? "")
        _blocks = State(initialValue:
            existing?.blocks.map { EditableBlock(arenaId: $0.arenaId, duration: $0.duration) }
            ?? [EditableBlock(arenaId: arenas.first?.id ?? "", duration: 25)]
        )
    }

    private var isNew: Bool { existing == nil }
    private var accentColor: Color { Color(hex: color) }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !blocks.isEmpty && blocks.allSatisfy { $0.duration > 0 } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Button { onCancel() } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 48)
                .padding(.bottom, 28)

                Text(isNew ? "CREATE PROTOCOL" : "EDIT PROTOCOL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 4)
                Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? "UNTITLED" : name.uppercased())
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(accentColor)
                    .kerning(2)
                    .padding(.bottom, 28)

                // Name
                fieldLabel("NAME")
                TextField("Protocol name", text: $name)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(accentColor)
                    .padding(12)
                    .background(accentColor.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accentColor.opacity(0.35), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 20)

                // Description
                fieldLabel("DESCRIPTION")
                TextField("Short description", text: $desc)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 20)

                // Glyph + Color
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 0) {
                        fieldLabel("GLYPH")
                        TextField("◈", text: $glyph)
                            .font(.system(size: 22))
                            .multilineTextAlignment(.center)
                            .padding(10)
                            .frame(width: 56, height: 46)
                            .background(accentColor.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accentColor.opacity(0.35), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onChange(of: glyph) { _, new in
                                if new.count > 2 { glyph = String(new.prefix(2)) }
                            }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        fieldLabel("COLOR")
                        HStack(spacing: 10) {
                            ForEach(colorPresets, id: \.self) { c in
                                Circle()
                                    .fill(Color(hex: c))
                                    .frame(width: 26, height: 26)
                                    .overlay(Circle().strokeBorder(color == c ? .white : .clear, lineWidth: 2))
                                    .shadow(color: color == c ? Color(hex: c).opacity(0.7) : .clear, radius: 5)
                                    .onTapGesture { color = c }
                            }
                        }
                    }
                }
                .padding(.bottom, 28)

                // Blocks
                fieldLabel("BLOCKS")
                VStack(spacing: 10) {
                    ForEach($blocks) { $block in
                        blockRow(block: $block)
                    }

                    Button {
                        blocks.append(EditableBlock(arenaId: arenas.first?.id ?? "", duration: 25))
                    } label: {
                        HStack(spacing: 8) {
                            Text("+")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                            Text("ADD BLOCK")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .kerning(3)
                        }
                        .foregroundStyle(accentColor.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accentColor.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accentColor.opacity(0.2), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 32)

                // Save
                Button { if isValid { commitSave() } } label: {
                    Text(isNew ? "CREATE PROTOCOL" : "SAVE CHANGES")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(isValid ? Color(hex: "#080810") : Color.white.opacity(0.3))
                        .kerning(5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? accentColor : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
                .padding(.bottom, 12)

                // Delete (edit only)
                if let onDelete {
                    Button { onDelete() } label: {
                        Text("DELETE PROTOCOL")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(hex: "#F87171").opacity(0.6))
                            .kerning(3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private func blockRow(block: Binding<EditableBlock>) -> some View {
        let b = block.wrappedValue
        let arena = arenas.first(where: { $0.id == b.arenaId }) ?? arenas.first
        let bColor = Color(hex: arena?.color ?? "#E8C547")

        HStack(spacing: 12) {
            // Arena picker
            Menu {
                ForEach(arenas) { a in
                    Button(a.label) { block.wrappedValue.arenaId = a.id }
                }
            } label: {
                HStack(spacing: 7) {
                    Circle().fill(bColor).frame(width: 7, height: 7)
                    Text(arena?.label ?? "PICK ARENA")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(bColor)
                        .kerning(1)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 7))
                        .foregroundStyle(bColor.opacity(0.5))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(bColor.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(bColor.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()

            // Duration
            TextField("25", value: block.duration, format: .number)
                .keyboardType(.numberPad)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(bColor)
                .multilineTextAlignment(.center)
                .frame(width: 46)
                .padding(8)
                .background(bColor.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(bColor.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("MIN")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.3))

            // Remove
            if blocks.count > 1 {
                Button { blocks.removeAll { $0.id == b.id } } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.18))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(bColor.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(bColor.opacity(0.12), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func fieldLabel(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.22))
            .kerning(5)
            .padding(.bottom, 10)
    }

    private func commitSave() {
        let protocolBlocks: [ProtocolBlock] = blocks.compactMap { b in
            guard let arena = arenas.first(where: { $0.id == b.arenaId }), b.duration > 0 else { return nil }
            return ProtocolBlock(arenaId: arena.id, label: arena.label, duration: b.duration, color: arena.color)
        }
        guard !protocolBlocks.isEmpty else { return }
        let p = ArenaProtocolModel(
            id: existing?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            glyph: glyph.isEmpty ? "◈" : glyph,
            color: color,
            description: desc,
            blocks: protocolBlocks
        )
        onSave(p)
    }
}

// MARK: - Active Protocol View

struct ActiveProtocolView: View {
    @Environment(DataStore.self) private var store
    let `protocol`: ArenaProtocolModel
    var onComplete: ([ProtocolBlock]) -> Void
    var onAbandon:  () -> Void

    @State private var blockIdx = 0
    @State private var timeLeft: Int = 0
    @State private var isPaused = false
    @State private var completedBlocks: [ProtocolBlock] = []
    @State private var endTime = Date()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentBlock: ProtocolBlock { `protocol`.blocks[blockIdx] }
    private var totalDuration: Int { `protocol`.blocks.reduce(0) { $0 + $1.duration } * 60 }
    private var completedTime: Int { completedBlocks.reduce(0) { $0 + $1.duration * 60 } }
    private var overallProgress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(completedTime + (currentBlock.duration * 60 - timeLeft)) / Double(totalDuration)
    }
    private var blockProgress: Double {
        guard currentBlock.duration > 0 else { return 0 }
        return 1.0 - Double(timeLeft) / Double(currentBlock.duration * 60)
    }
    private var blockColor: Color { Color(hex: currentBlock.color) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 4) {
                Text("PROTOCOL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(6)
                Text(`protocol`.name)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: `protocol`.color))
                    .kerning(4)
            }
            .padding(.bottom, 20)

            overallProgressBar
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

            VStack(spacing: 2) {
                Text(isPaused ? "PAUSED" : "NOW IN")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(5)
                Text(currentBlock.label)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(blockColor)
                    .kerning(4)
                Text("BLOCK \(blockIdx + 1) OF \(`protocol`.blocks.count)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(2)
            }
            .padding(.bottom, 8)

            CircularTimerView(timeLeft: timeLeft, totalTime: currentBlock.duration * 60, colors: [blockColor], size: 200)
                .padding(.bottom, 24)

            HStack(spacing: 10) {
                Button { togglePause() } label: {
                    Text(isPaused ? "RESUME" : "PAUSE")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .kerning(4)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button { finishEarly() } label: {
                    Text("DONE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(blockColor)
                        .kerning(4)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(blockColor.opacity(0.18))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(blockColor, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            Button {
                #if canImport(ActivityKit)
                endActivity()
                #endif
                onAbandon()
            } label: {
                Text("ABANDON PROTOCOL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.18))
                    .kerning(3)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .onAppear { startBlock() }
        .onReceive(ticker) { _ in tick() }
        .onDisappear { ticker.upstream.connect().cancel() }
    }

    private var overallProgressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 8)
                    HStack(spacing: 0) {
                        ForEach(`protocol`.blocks.indices, id: \.self) { i in
                            let b = `protocol`.blocks[i]
                            let segFill: Double = i < blockIdx ? 1 : i == blockIdx ? blockProgress : 0
                            Color(hex: b.color).opacity(0.85)
                                .frame(width: geo.size.width * CGFloat(b.duration) / CGFloat(totalDuration / 60) * segFill, height: 8)
                                .animation(.linear(duration: 1), value: blockProgress)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(height: 8)

            HStack {
                ForEach(`protocol`.blocks.indices, id: \.self) { i in
                    let b = `protocol`.blocks[i]
                    Text(i < blockIdx ? "✓" : b.label)
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(i == blockIdx ? Color(hex: b.color) : i < blockIdx ? Color(hex: b.color).opacity(0.6) : Color.white.opacity(0.2))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut, value: blockIdx)
                }
            }
        }
    }

    private func startBlock() {
        timeLeft = currentBlock.duration * 60
        endTime  = Date().addingTimeInterval(TimeInterval(timeLeft))
        #if canImport(ActivityKit)
        startActivityForBlock()
        #endif
    }

    private func tick() {
        guard !isPaused else { return }
        let remaining = Int(endTime.timeIntervalSinceNow)
        if remaining <= 0 { advanceBlock() } else { timeLeft = remaining }
    }

    private func advanceBlock() {
        let next = blockIdx + 1
        if next < `protocol`.blocks.count {
            completedBlocks.append(currentBlock)
            blockIdx = next
            startBlock()
        } else {
            #if canImport(ActivityKit)
            endActivity()
            #endif
            onComplete(completedBlocks + [currentBlock])
        }
    }

    private func togglePause() {
        isPaused.toggle()
        if !isPaused { endTime = Date().addingTimeInterval(TimeInterval(timeLeft)) }
        #if canImport(ActivityKit)
        let newEnd = isPaused ? Date() : endTime
        let paused = isPaused
        let left = timeLeft
        let block = currentBlock
        Task {
            let state = ArenaLiveActivityAttributes.ContentState(
                endTime: newEnd, isPaused: paused,
                pausedRemaining: paused ? TimeInterval(left) : 0, isIdle: false,
                arenaLabel: block.label, arenaColor: block.color, arenaIcon: "◈")
            for a in Activity<ArenaLiveActivityAttributes>.activities where a.attributes.arenaId != "idle" {
                await a.update(.init(state: state, staleDate: nil))
            }
        }
        #endif
    }

    private func finishEarly() {
        let elapsed = max(1, currentBlock.duration - timeLeft / 60)
        var partial = currentBlock; partial.duration = elapsed
        #if canImport(ActivityKit)
        endActivity()
        #endif
        onComplete(completedBlocks + [partial])
    }

    #if canImport(ActivityKit)
    private func startActivityForBlock() {
        let block = currentBlock
        let blockEndTime = endTime
        let state = ArenaLiveActivityAttributes.ContentState(
            endTime: blockEndTime, isPaused: false, pausedRemaining: 0, isIdle: false,
            arenaLabel: block.label, arenaColor: block.color, arenaIcon: "◈")
        let attrs = ArenaLiveActivityAttributes(
            arenaId: block.arenaId,
            questNote: `protocol`.name, startTime: Date())
        Task {
            for a in Activity<ArenaLiveActivityAttributes>.activities {
                await a.end(nil, dismissalPolicy: .immediate)
            }
            _ = try? Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: blockEndTime),
                pushType: nil)
        }
    }

    private func endActivity() {
        Task {
            for a in Activity<ArenaLiveActivityAttributes>.activities where a.attributes.arenaId != "idle" {
                await a.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
    #endif
}
