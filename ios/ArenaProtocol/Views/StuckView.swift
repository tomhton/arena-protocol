// StuckView.swift — Arena Protocol
// Emergency protocol: grace period timer → mandatory arena selection

import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

struct StuckView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var phase: StuckPhase = .config
    @State private var selectedDuration = 10
    @State private var isCustomActive   = false
    @State private var customMinutes    = ""
    @State private var intention        = ""
    @State private var timeLeft         = 0
    @State private var endTime          = Date()
    @State private var prompt           = STUCK_PROMPTS.randomElement()!

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var arenas: [Arena] { store.letteredArenas }
    private var effectiveDuration: Int {
        isCustomActive ? (Int(customMinutes) ?? 0) : selectedDuration
    }
    private var circumference: Double { 2 * .pi * 90 }
    private var totalSecs: Int { effectiveDuration * 60 }
    private var progress: Double { totalSecs > 0 ? 1.0 - Double(timeLeft) / Double(totalSecs) : 0 }

    enum StuckPhase { case config, countdown, pickArena }

    var body: some View {
        switch phase {
        case .config:   configView
        case .countdown: countdownView
        case .pickArena: pickArenaView
        }
    }

    // MARK: - Config

    private var configView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button { navigate(.home) } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 52)
                .padding(.bottom, 36)

                Text("EMERGENCY PROTOCOL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 4)
                HStack(spacing: 6) {
                    Text("I AM")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .kerning(2)
                    Text("STUCK")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#FF8FA3"))
                        .kerning(2)
                }
                .padding(.bottom, 6)
                Text("Set a countdown. When it hits zero, you *must* enter an arena.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .lineSpacing(5)
                    .padding(.bottom, 24)

                // Prompt
                Text("\"\(prompt)\"")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#FF8FA3").opacity(0.8))
                    .italic()
                    .lineSpacing(5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#FF8FA3").opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#FF8FA3").opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 28)

                // Optional intention
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("IF YOU COULD DO ANYTHING RIGHT NOW")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.22))
                            .kerning(5)
                        Text("— OPTIONAL")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.12))
                    }

                    ZStack(alignment: .topLeading) {
                        if intention.isEmpty {
                            Text("What's one thing you'd actually do if you weren't stuck...")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.2))
                                .padding(14)
                        }
                        TextEditor(text: $intention)
                            .font(.system(size: intention.isEmpty ? 12 : 13))
                            .foregroundStyle(intention.isEmpty ? Color.white.opacity(0.3) : Color(hex: "#FF8FA3"))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .scrollDisabled(true)
                            .frame(minHeight: 70)
                            .padding(10)
                    }
                    .background(intention.isEmpty ? Color.white.opacity(0.02) : Color(hex: "#FF8FA3").opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(intention.isEmpty ? Color.white.opacity(0.08) : Color(hex: "#FF8FA3").opacity(0.45), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: intention.isEmpty ? .clear : Color(hex: "#FF8FA3").opacity(0.1), radius: 12)

                    if !intention.isEmpty {
                        Text("▸ HOLD THIS THOUGHT")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color(hex: "#FF8FA3").opacity(0.5))
                            .kerning(2)
                    }
                }
                .padding(.bottom, 28)

                // Grace period selector
                Text("GRACE PERIOD")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(5)
                    .padding(.bottom, 12)

                FlowLayout(spacing: 8) {
                    ForEach(DURATIONS, id: \.self) { d in
                        Button {
                            selectedDuration = d; isCustomActive = false
                        } label: {
                            Text("\(d)m")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(!isCustomActive && selectedDuration == d ? Color(hex: "#FF8FA3") : Color.white.opacity(0.4))
                                .kerning(2)
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(!isCustomActive && selectedDuration == d ? Color(hex: "#FF8FA3").opacity(0.12) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(!isCustomActive && selectedDuration == d ? Color(hex: "#FF8FA3") : Color.white.opacity(0.1),
                                                      lineWidth: !isCustomActive && selectedDuration == d ? 1.5 : 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    Button { isCustomActive = true } label: {
                        Text("other")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(isCustomActive ? Color(hex: "#FF8FA3") : Color.white.opacity(0.4))
                            .kerning(2)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(isCustomActive ? Color(hex: "#FF8FA3").opacity(0.12) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(isCustomActive ? Color(hex: "#FF8FA3") : Color.white.opacity(0.1),
                                                  lineWidth: isCustomActive ? 1.5 : 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 16)

                if isCustomActive {
                    HStack(spacing: 10) {
                        TextField("min", text: $customMinutes)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundStyle(Color(hex: "#FF8FA3"))
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .background(Color(hex: "#FF8FA3").opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#FF8FA3"), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(maxWidth: 120)
                        Text("MINUTES")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .kerning(2)
                    }
                    .padding(.bottom, 16)
                }

                Button { startCountdown() } label: {
                    Text("START GRACE PERIOD")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#FF8FA3"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 6) {
                Text("GRACE PERIOD")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                Text("CHOOSE YOUR ARENA")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#FF8FA3"))
                    .kerning(4)
            }

            // Circular timer
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(hex: "#FF8FA3"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .shadow(color: Color(hex: "#FF8FA3").opacity(0.6), radius: 10)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                VStack(spacing: 6) {
                    Text(formatTime(timeLeft))
                        .font(.system(size: 46, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#FF8FA3"))
                        .monospacedDigit()
                    Text("UNTIL MANDATORY")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(3)
                }
            }
            .frame(width: 220, height: 220)

            // Intention or prompt
            if !intention.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR INTENTION")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color(hex: "#FF8FA3").opacity(0.5))
                        .kerning(4)
                    Text("\"\(intention)\"")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#FF8FA3"))
                        .italic()
                        .lineSpacing(4)
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
                .frame(maxWidth: 300, alignment: .leading)
                .background(Color(hex: "#FF8FA3").opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#FF8FA3").opacity(0.2), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                Text("\"\(prompt)\"")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#FF8FA3").opacity(0.7))
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .frame(maxWidth: 280)
                    .background(Color(hex: "#FF8FA3").opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#FF8FA3").opacity(0.15), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
            #if canImport(ActivityKit)
            transitionToMandatory()
            #endif
            withAnimation { phase = .pickArena }
        } label: {
                Text("I'M READY NOW →")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .kerning(4)
                    .padding(.horizontal, 32).padding(.vertical, 14)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .onReceive(ticker) { _ in
            guard phase == .countdown else { return }
            let remaining = Int(endTime.timeIntervalSinceNow)
            if remaining <= 0 {
                #if canImport(ActivityKit)
                transitionToMandatory()
                #endif
                withAnimation { phase = .pickArena }
            } else { timeLeft = remaining }
        }
    }

    // MARK: - Pick Arena

    private var pickArenaView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("⚡")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "#FF8FA3"))
                        .shadow(color: Color(hex: "#FF8FA3"), radius: 12)
                    Text("TIME IS UP")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(7)
                    Text("PICK AN ARENA")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .kerning(3)
                    if !intention.isEmpty {
                        Text("\"\(intention)\"")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#FF8FA3").opacity(0.6))
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 52)
                .padding(.bottom, 28)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(arenas.indices, id: \.self) { i in
                        ArenaCardView(
                            arena: arenas[i], sessCount: 0, streak: 0, editMode: false,
                            onTap: { navigate(.select(arenas[i], false)) },
                            sessions: store.sessions
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Actions

    private func startCountdown() {
        guard effectiveDuration > 0 else { return }
        timeLeft = effectiveDuration * 60
        endTime  = Date().addingTimeInterval(TimeInterval(timeLeft))
        withAnimation { phase = .countdown }
        #if canImport(ActivityKit)
        startStuckActivity()
        #endif
    }

    #if canImport(ActivityKit)
    private func startStuckActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let stuckEnd = endTime
        let note = intention.trimmingCharacters(in: .whitespaces)
        Task {
            for a in Activity<ArenaLiveActivityAttributes>.activities {
                await a.end(nil, dismissalPolicy: .immediate)
            }
            let attrs = ArenaLiveActivityAttributes(
                arenaId: "stuck",
                questNote: note.isEmpty ? "Grace period" : note,
                startTime: Date())
            let state = ArenaLiveActivityAttributes.ContentState(
                endTime: stuckEnd, isPaused: false, pausedRemaining: 0, isIdle: false,
                arenaLabel: "STUCK", arenaColor: "#FF8FA3", arenaIcon: "⚡")
            _ = try? Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: stuckEnd),
                pushType: nil)
        }
    }

    private func transitionToMandatory() {
        Task {
            let mandatoryState = ArenaLiveActivityAttributes.ContentState(
                endTime: Date(), isPaused: false, pausedRemaining: 0,
                isIdle: false, isMandatory: true,
                arenaLabel: "MANDATORY", arenaColor: "#FF8FA3", arenaIcon: "⚡")
            for a in Activity<ArenaLiveActivityAttributes>.activities where a.attributes.arenaId == "stuck" {
                await a.update(.init(state: mandatoryState, staleDate: nil))
            }
        }
    }

    private func endStuckActivity() {
        Task {
            for a in Activity<ArenaLiveActivityAttributes>.activities where a.attributes.arenaId == "stuck" {
                await a.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
    #endif
}
