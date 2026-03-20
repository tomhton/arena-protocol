// IntervalTimerView.swift — Arena Protocol
// Mindless / no-arena interval timer

import SwiftUI

struct IntervalTimerView: View {
    @Environment(DataStore.self) private var store
    let label: String
    let minutes: Int
    var navigate: (Screen) -> Void

    @State private var timeLeft: Int
    @State private var isPaused = false
    @State private var endTime = Date()
    @State private var calEventId: String?
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(label: String, minutes: Int, navigate: @escaping (Screen) -> Void) {
        self.label = label
        self.minutes = minutes
        self.navigate = navigate
        _timeLeft = State(initialValue: minutes * 60)
    }

    private var progress: Double {
        let total = minutes * 60
        guard total > 0 else { return 0 }
        return 1.0 - Double(timeLeft) / Double(total)
    }
    private let accentColor = Color(hex: "#4ECDC4")

    var body: some View {
        ZStack {
            Color(hex: "#080810").ignoresSafeArea()
            RadialGradient(colors: [accentColor.opacity(0.08), Color.clear],
                           center: .center, startRadius: 0, endRadius: 350)
                .ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                VStack(spacing: 6) {
                    Text("INTERVAL")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(7)
                    Text(label)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .kerning(4)
                }

                // Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .shadow(color: accentColor.opacity(0.5), radius: 8)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    VStack(spacing: 4) {
                        Text(formatTime(timeLeft))
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundStyle(accentColor)
                            .monospacedDigit()
                        Text("REMAINING")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.22))
                            .kerning(3)
                        Text("ends \(endTime.formatted(timezone: store.settings.clockTimezone))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(accentColor.opacity(0.45))
                            .kerning(2)
                    }
                }
                .frame(width: 200, height: 200)

                HStack(spacing: 10) {
                    Button { isPaused.toggle() } label: {
                        Text(isPaused ? "RESUME" : "PAUSE")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .kerning(4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button { finishInterval() } label: {
                        Text("DONE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(accentColor)
                            .kerning(4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accentColor.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accentColor, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            endTime = Date().addingTimeInterval(TimeInterval(timeLeft))
            let start = Date()
            let end = endTime
            let title = "[INTERVAL] \(label)"
            Task { @MainActor in
                if !CalendarManager.shared.isReadAuthorized {
                    _ = await CalendarManager.shared.requestFullAccess()
                }
                calEventId = CalendarManager.shared.addEvent(title: title, start: start, end: end)
            }
        }
        .onReceive(ticker) { _ in
            guard !isPaused else { return }
            let r = Int(endTime.timeIntervalSinceNow)
            if r <= 0 { finishInterval() } else { timeLeft = r }
        }
        .onDisappear { ticker.upstream.connect().cancel() }
    }

    private func finishInterval() {
        if let id = calEventId {
            CalendarManager.shared.updateEventEnd(id: id, newEnd: Date())
        }
        navigate(.home)
    }
}
