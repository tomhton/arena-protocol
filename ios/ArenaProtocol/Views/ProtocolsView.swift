// ProtocolsView.swift — Arena Protocol
// Protocol list + editor + active protocol runner

import SwiftUI

struct ProtocolsView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var editingId: String? = nil
    @State private var editName = ""
    @State private var editDesc = ""
    @State private var editBlocks: [ProtocolBlock] = []

    private var protocols: [ArenaProtocolModel] { store.protocols }

    var body: some View {
        if let id = editingId, let p = protocols.first(where: { $0.id == id }) {
            editView(p)
        } else {
            listView
        }
    }

    // MARK: - List

    private var listView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Button { navigate(.home) } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 48)
                .padding(.bottom, 28)

                Text("CHAIN YOUR ARENAS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 4)
                Text("PROTOCOLS")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .kerning(2)
                    .padding(.bottom, 6)
                Text("Back-to-back arenas. One progress bar. One unbroken chain.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .lineSpacing(4)
                    .padding(.bottom, 28)

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
                Button {
                    editName   = p.name
                    editDesc   = p.description
                    editBlocks = p.blocks
                    editingId  = p.id
                } label: {
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
                            .frame(width: geo.size.width * CGFloat(b.duration) / CGFloat(total) - 4, height: 6)
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

    // MARK: - Edit View

    @ViewBuilder
    private func editView(_ p: ArenaProtocolModel) -> some View {
        let pColor = Color(hex: p.color)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button { editingId = nil } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 48)
                .padding(.bottom, 28)

                Text("EDIT PROTOCOL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 4)
                Text(editName)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(pColor)
                    .kerning(2)
                    .padding(.bottom, 24)

                fieldLabel("NAME")
                styledTextField($editName, color: pColor)
                    .padding(.bottom, 20)

                fieldLabel("DESCRIPTION")
                styledTextField($editDesc)
                    .padding(.bottom, 20)

                fieldLabel("BLOCKS — ADJUST DURATIONS")
                VStack(spacing: 0) {
                    ForEach(editBlocks.indices, id: \.self) { idx in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: editBlocks[idx].color))
                                .frame(width: 8, height: 8)
                            Text(editBlocks[idx].label)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .kerning(2)
                            Spacer()
                            TextField("5", value: $editBlocks[idx].duration, format: .number)
                                .keyboardType(.numberPad)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(Color(hex: editBlocks[idx].color))
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .padding(8)
                                .background(Color(hex: editBlocks[idx].color).opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color(hex: editBlocks[idx].color).opacity(0.4), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text("MIN")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.3))
                        }
                        .padding(.vertical, 12)
                        Divider().background(Color.white.opacity(0.05))
                    }
                }
                .padding(.bottom, 24)

                Button { saveEdit(p) } label: {
                    Text("SAVE PROTOCOL")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(pColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 32)
        }
    }

    private func fieldLabel(_ s: String) -> some View {
        Text(s).font(.system(size: 9, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.22)).kerning(5).padding(.bottom, 10)
    }

    private func styledTextField(_ binding: Binding<String>, color: Color = .white) -> some View {
        TextField("", text: binding)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(color)
            .padding(12)
            .background(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func saveEdit(_ p: ArenaProtocolModel) {
        guard let idx = store.protocols.firstIndex(where: { $0.id == p.id }) else { return }
        store.protocols[idx].name        = editName
        store.protocols[idx].description = editDesc
        store.protocols[idx].blocks      = editBlocks
        store.saveProtocols()
        editingId = nil
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

            // Protocol name
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

            // Overall progress bar
            overallProgressBar
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

            // Current block info
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

            // Timer ring
            CircularTimerView(timeLeft: timeLeft, totalTime: currentBlock.duration * 60, color: blockColor, size: 200)
                .padding(.bottom, 24)

            // Controls
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

            Button { onAbandon() } label: {
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
            // Segmented bar
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

            // Labels
            HStack {
                ForEach(`protocol`.blocks.indices, id: \.self) { i in
                    let b = `protocol`.blocks[i]
                    Text(i < blockIdx ? "✓" : b.label)
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(i == blockIdx ? Color(hex: b.color) : i < blockIdx ? Color(hex: b.color).opacity(0.6) : Color.white.opacity(0.2))
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut, value: blockIdx)
                }
            }
        }
    }

    private func startBlock() {
        timeLeft = currentBlock.duration * 60
        endTime  = Date().addingTimeInterval(TimeInterval(timeLeft))
    }

    private func tick() {
        guard !isPaused else { return }
        let remaining = Int(endTime.timeIntervalSinceNow)
        if remaining <= 0 {
            advanceBlock()
        } else {
            timeLeft = remaining
        }
    }

    private func advanceBlock() {
        let next = blockIdx + 1
        if next < `protocol`.blocks.count {
            completedBlocks.append(currentBlock)
            blockIdx = next
            startBlock()
        } else {
            onComplete(completedBlocks + [currentBlock])
        }
    }

    private func togglePause() {
        isPaused.toggle()
        if !isPaused { endTime = Date().addingTimeInterval(TimeInterval(timeLeft)) }
    }

    private func finishEarly() {
        let elapsed = max(1, currentBlock.duration - timeLeft / 60)
        var partial = currentBlock; partial.duration = elapsed
        onComplete(completedBlocks + [partial])
    }
}
