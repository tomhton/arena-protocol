// ActiveSessionView.swift — Arena Protocol
// Live focus timer with pause/resume, circular progress, completion

import SwiftUI

struct ActiveSessionView: View {
    @Environment(DataStore.self) private var store
    let arena: Arena
    let duration: Int   // minutes
    let note: String
    var navigate: (Screen) -> Void

    @State private var timeLeft: Int
    @State private var isPaused = false
    @State private var focusHint = ""
    @State private var endTime: Date = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var arenaColor: Color { Color(hex: arena.color) }
    private var totalTime: Int { duration * 60 }

    init(arena: Arena, duration: Int, note: String, navigate: @escaping (Screen) -> Void) {
        self.arena = arena
        self.duration = duration
        self.note = note
        self.navigate = navigate
        _timeLeft = State(initialValue: duration * 60)
    }

    var body: some View {
        ZStack {
            // Background glow
            RadialGradient(
                colors: [arenaColor.opacity(0.12), Color.clear],
                center: .top, startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 6) {
                    Text(isPaused ? "PAUSED" : "NOW IN")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(7)
                    Text(arena.label)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(arenaColor)
                        .kerning(5)
                    if !note.isEmpty {
                        Text(note)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .italic()
                    }
                }

                // Timer ring
                CircularTimerView(timeLeft: timeLeft, totalTime: totalTime, color: arenaColor, size: 220)

                // Focus hint
                if !focusHint.isEmpty {
                    VStack(spacing: 8) {
                        Text("FOCUS ON")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.22))
                            .kerning(5)
                        Text(focusHint)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                }

                // Controls
                HStack(spacing: 10) {
                    Button { togglePause() } label: {
                        Text(isPaused ? "RESUME" : "PAUSE")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .kerning(4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button { finishEarly() } label: {
                        Text("DONE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(arenaColor)
                            .kerning(4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(arenaColor.opacity(0.18))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(arenaColor, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                Button { abandonSession() } label: {
                    Text("ABANDON SESSION")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .kerning(3)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .onAppear { setup() }
        .onReceive(timer) { _ in tick() }
        .onDisappear { timer.upstream.connect().cancel() }
    }

    private func setup() {
        endTime = Date().addingTimeInterval(TimeInterval(timeLeft))
        if let example = arena.examples.randomElement() { focusHint = example }
        UserDefaults.standard.set(endTime.timeIntervalSince1970, forKey: "timerEndTime")
        SharedStore.writeActiveSession(arenaName: arena.label, arenaColor: arena.color, endsAt: endTime)
    }

    private func tick() {
        guard !isPaused else { return }
        let remaining = Int(endTime.timeIntervalSinceNow)
        if remaining <= 0 {
            timeLeft = 0
            SharedStore.clearActiveSession()
            navigate(.complete(arena, duration, note))
        } else {
            timeLeft = remaining
        }
    }

    private func togglePause() {
        isPaused.toggle()
        if !isPaused {
            endTime = Date().addingTimeInterval(TimeInterval(timeLeft))
            UserDefaults.standard.set(endTime.timeIntervalSince1970, forKey: "timerEndTime")
            SharedStore.writeActiveSession(arenaName: arena.label, arenaColor: arena.color, endsAt: endTime)
        }
    }

    private func finishEarly() {
        cancelNotification(id: "session_1")
        SharedStore.clearActiveSession()
        navigate(.complete(arena, duration, note))
    }

    private func abandonSession() {
        cancelNotification(id: "session_1")
        SharedStore.clearActiveSession()
        navigate(.home)
    }
}

// MARK: - Complete View

struct CompleteView: View {
    let arena: Arena
    let duration: Int
    let note: String
    var onDone: () -> Void

    private var arenaColor: Color { Color(hex: arena.color) }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [arenaColor.opacity(0.15), Color.clear],
                center: .top, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text(arena.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(arenaColor)
                    .shadow(color: arenaColor, radius: 20)
                    .transition(.scale)

                VStack(spacing: 8) {
                    Text("SESSION COMPLETE")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(7)
                    Text(arena.label)
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .foregroundStyle(arenaColor)
                        .kerning(3)
                    Text("\(duration) MINUTES")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .kerning(3)
                    if !note.isEmpty {
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .italic()
                    }
                }

                Button(action: onDone) {
                    Text("DONE")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(5)
                        .frame(maxWidth: 320)
                        .padding(.vertical, 18)
                        .background(arenaColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: arenaColor.opacity(0.4), radius: 20)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear { cancelNotification(id: "session_1") }
    }
}
