// ActiveSessionView.swift — Arena Protocol
// Live focus timer with pause/resume, circular progress, completion

import ActivityKit
import WidgetKit
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
    @State private var liveActivity: Activity<ArenaLiveActivityAttributes>? = nil
    @State private var jointEntries: [JointArenaEntry] = []
    @State private var showJointPicker = false
    @State private var totalTime: Int

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var arenaColor: Color { Color(hex: arena.color) }
    private var ringColors: [Color] {
        ([arena] + jointEntries.map { $0.arena }).map { Color(hex: $0.color) }
    }

    init(arena: Arena, duration: Int, note: String, navigate: @escaping (Screen) -> Void) {
        self.arena = arena
        self.duration = duration
        self.note = note
        self.navigate = navigate
        _timeLeft = State(initialValue: duration * 60)
        _totalTime = State(initialValue: duration * 60)
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
                VStack(spacing: 4) {
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

                // Arena breakdown (shown when joints exist, or always with + button)
                VStack(spacing: 0) {
                    // Primary row
                    arenaRow(icon: arena.icon, label: arena.label, color: arenaColor,
                             minutes: duration, removable: false, onRemove: {})

                    // Joint rows
                    ForEach(jointEntries) { entry in
                        arenaRow(icon: entry.arena.icon, label: entry.arena.label,
                                 color: Color(hex: entry.arena.color),
                                 minutes: entry.minutes, removable: true) {
                            removeJoint(entry)
                        }
                    }

                    // Total row (shown when joints exist)
                    if !jointEntries.isEmpty {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                            .padding(.horizontal, 12)
                        HStack {
                            Text("TOTAL")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.35))
                                .kerning(4)
                            Spacer()
                            Text("\(totalTime / 60)m")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    // Add joint button row
                    Button { showJointPicker = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 12))
                            Text("ADD ARENA")
                                .font(.system(size: 10, design: .monospaced))
                                .kerning(3)
                        }
                        .foregroundStyle(Color.white.opacity(0.22))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.07), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                // Timer ring
                CircularTimerView(timeLeft: timeLeft, totalTime: totalTime, colors: ringColors, size: 220)

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

                // Swipe hint
                Text("↓  swipe to stack")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.12))
                    .kerning(3)
                    .padding(.bottom, 8)

                Spacer()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { navigate(.home) } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .padding(20)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showJointPicker) {
            JointArenaPicker(
                current: [arena] + jointEntries.map { $0.arena },
                allArenas: store.letteredArenas
            ) { pickedArena, pickedMinutes in
                addJoint(arena: pickedArena, minutes: pickedMinutes)
            }
            .presentationDetents([.fraction(0.6)])
            .presentationBackground(Color(hex: "#080810"))
        }
        .onAppear { setup() }
        .onReceive(timer) { _ in tick() }
        .onDisappear { timer.upstream.connect().cancel() }
        .gesture(
            DragGesture()
                .onEnded { val in
                    if val.translation.height > 80 && abs(val.translation.width) < 50 {
                        stashSession()
                    }
                }
        )
    }

    @ViewBuilder
    private func arenaRow(icon: String, label: String, color: Color, minutes: Int,
                          removable: Bool, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            // Colored bar
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3, height: 32)

            Text(icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .kerning(2)
                // proportional bar
                GeometryReader { geo in
                    let fraction = totalTime > 0 ? CGFloat(minutes * 60) / CGFloat(totalTime) : 0
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.06))
                        RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.5))
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 3)
            }

            Spacer()

            Text("+\(minutes)m")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(color.opacity(0.7))

            if removable {
                Button { onRemove() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.2))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func removeJoint(_ entry: JointArenaEntry) {
        jointEntries.removeAll { $0.id == entry.id }
        endTime = endTime.addingTimeInterval(-TimeInterval(entry.minutes * 60))
        totalTime -= entry.minutes * 60
    }

    private func addJoint(arena: Arena, minutes: Int) {
        jointEntries.append(JointArenaEntry(arena: arena, minutes: minutes))
        endTime = endTime.addingTimeInterval(TimeInterval(minutes * 60))
        totalTime += minutes * 60
        showJointPicker = false
    }

    private func setup() {
        if let active = store.activeSession, active.arena.id == arena.id {
            // Returning from minimize — resume from stored state
            if active.isPaused {
                isPaused = true
                timeLeft = Int(active.pausedRemaining)
                endTime = Date().addingTimeInterval(active.pausedRemaining)
            } else {
                endTime = active.endTime
                timeLeft = max(0, Int(active.endTime.timeIntervalSinceNow))
            }
            // Reattach to existing Live Activity — do NOT start a new one
            #if canImport(ActivityKit)
            liveActivity = Activity<ArenaLiveActivityAttributes>.activities.first
            #endif
        } else {
            // Fresh start
            store.startSession(arena: arena, durationMins: duration, note: note)
            endTime = Date().addingTimeInterval(TimeInterval(timeLeft))
            UserDefaults.standard.set(endTime.timeIntervalSince1970, forKey: "timerEndTime")
            SharedStore.writeActiveSession(arenaName: arena.label, arenaColor: arena.color, endsAt: endTime)
            WidgetCenter.shared.reloadAllTimelines()

            #if canImport(ActivityKit)
            if ActivityAuthorizationInfo().areActivitiesEnabled {
                let normalizedColor: String = {
                    let c = arena.color.trimmingCharacters(in: .whitespacesAndNewlines)
                    return c.hasPrefix("#") ? c : "#\(c)"
                }()
                let attrs = ArenaLiveActivityAttributes(
                    arenaId: arena.id,
                    arenaLabel: arena.label,
                    arenaColor: normalizedColor,
                    arenaIcon: arena.icon.isEmpty ? "◉" : arena.icon,
                    questNote: note,
                    startTime: endTime.addingTimeInterval(-TimeInterval(timeLeft))
                )
                let contentState = ArenaLiveActivityAttributes.ContentState(
                    endTime: endTime,
                    isPaused: false,
                    pausedRemaining: 0
                )
                // End any stale activities before requesting — handles schema changes between builds
                Task {
                    for stale in Activity<ArenaLiveActivityAttributes>.activities {
                        await stale.end(nil, dismissalPolicy: .immediate)
                    }
                    do {
                        let activity = try Activity<ArenaLiveActivityAttributes>.request(
                            attributes: attrs,
                            content: .init(state: contentState, staleDate: endTime),
                            pushType: nil
                        )
                        await MainActor.run { liveActivity = activity }
                        print("[LiveActivity] started: \(activity.id)")
                    } catch {
                        print("[LiveActivity] REQUEST FAILED: \(error)")
                    }
                }
            }
            #endif
        }
        if let example = arena.examples.randomElement() { focusHint = example }
    }

    private func tick() {
        guard !isPaused else { return }
        let remaining = Int(endTime.timeIntervalSinceNow)
        if remaining <= 0 {
            timeLeft = 0
            endLiveActivity()
            for entry in jointEntries {
                store.addSession(Session(arenaId: entry.arena.id, duration: entry.minutes,
                                         date: todayString(), note: note,
                                         ts: Date().timeIntervalSince1970 * 1000))
            }
            store.endSession()
            navigate(.complete(arena, duration, note))
        } else {
            timeLeft = remaining
        }
    }

    private func togglePause() {
        isPaused.toggle()
        if isPaused {
            store.activeSession?.isPaused = true
            store.activeSession?.pausedRemaining = TimeInterval(timeLeft)
        } else {
            endTime = Date().addingTimeInterval(TimeInterval(timeLeft))
            store.activeSession?.isPaused = false
            store.activeSession?.pausedRemaining = 0
            store.activeSession?.endTime = endTime
            UserDefaults.standard.set(endTime.timeIntervalSince1970, forKey: "timerEndTime")
        }
        #if canImport(ActivityKit)
        let activity = liveActivity
        let currentEndTime = store.activeSession?.endTime ?? endTime
        let currentPaused = isPaused
        let currentRemaining = store.activeSession?.pausedRemaining ?? 0
        Task {
            let newState = ArenaLiveActivityAttributes.ContentState(
                endTime: currentEndTime,
                isPaused: currentPaused,
                pausedRemaining: currentRemaining
            )
            await activity?.update(.init(state: newState, staleDate: nil))
        }
        #endif
    }

    private func endLiveActivity() {
        #if canImport(ActivityKit)
        let activity = liveActivity
        let currentEndTime = endTime
        Task {
            let finalState = ArenaLiveActivityAttributes.ContentState(
                endTime: currentEndTime,
                isPaused: false,
                pausedRemaining: 0
            )
            await activity?.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
        }
        #endif
        SharedStore.clearActiveSession()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func finishEarly() {
        cancelNotification(id: "session_1")
        endLiveActivity()
        for entry in jointEntries {
            store.addSession(Session(arenaId: entry.arena.id, duration: entry.minutes,
                                     date: todayString(), note: note,
                                     ts: Date().timeIntervalSince1970 * 1000))
        }
        store.endSession()
        navigate(.complete(arena, duration, note))
    }

    private func abandonSession() {
        cancelNotification(id: "session_1")
        endLiveActivity()
        store.endSession()
        navigate(.home)
    }

    private func stashSession() {
        store.stashSession()
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

// MARK: - Joint Arena Picker

private struct JointArenaPicker: View {
    let current: [Arena]
    let allArenas: [Arena]
    let onAdd: (Arena, Int) -> Void

    @State private var selected: Arena? = nil
    @State private var minutes = 25
    @State private var isCustom = false
    @State private var customText = ""

    private let presets = [5, 10, 15, 25, 30, 45, 60]

    var available: [Arena] {
        allArenas.filter { a in !current.contains(where: { $0.id == a.id }) }
    }

    var effectiveMinutes: Int {
        isCustom ? (Int(customText) ?? 0) : minutes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ADD ARENA TO SESSION")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.25))
                .kerning(7)
                .padding(.top, 28)
                .padding(.horizontal, 22)
                .padding(.bottom, 20)

            // Arena selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(available) { arena in
                        let isSelected = selected?.id == arena.id
                        let c = Color(hex: arena.color)
                        Button { selected = arena } label: {
                            VStack(spacing: 4) {
                                Text(arena.icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(c)
                                Text(arena.label)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isSelected ? c : Color.white.opacity(0.4))
                                    .kerning(2)
                            }
                            .frame(width: 64, height: 64)
                            .background(isSelected ? c.opacity(0.15) : Color.white.opacity(0.03))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(isSelected ? c : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                    }
                }
                .padding(.horizontal, 22)
            }
            .padding(.bottom, 20)

            // Duration selection
            VStack(alignment: .leading, spacing: 10) {
                Text("DURATION")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.horizontal, 22)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { p in
                            let active = !isCustom && minutes == p
                            Button { minutes = p; isCustom = false } label: {
                                Text("\(p)m")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(active ? Color(hex: "#E8C547") : Color.white.opacity(0.4))
                                    .kerning(2)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(active ? Color(hex: "#E8C547").opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(active ? Color(hex: "#E8C547") : Color.white.opacity(0.1), lineWidth: active ? 1.5 : 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                        // Custom
                        Button { isCustom = true } label: {
                            Text(isCustom ? "—" : "other")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(isCustom ? Color(hex: "#E8C547") : Color.white.opacity(0.4))
                                .kerning(2)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(isCustom ? Color(hex: "#E8C547").opacity(0.12) : Color.white.opacity(0.04))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(isCustom ? Color(hex: "#E8C547") : Color.white.opacity(0.1), lineWidth: isCustom ? 1.5 : 1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                }

                if isCustom {
                    HStack(spacing: 8) {
                        TextField("min", text: $customText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundStyle(Color(hex: "#E8C547"))
                            .multilineTextAlignment(.center)
                            .padding(10)
                            .background(Color(hex: "#E8C547").opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#E8C547"), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(maxWidth: 100)
                        Text("MINUTES")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .kerning(2)
                    }
                    .padding(.horizontal, 22)
                }
            }
            .padding(.bottom, 24)

            // Confirm button
            Button {
                guard let arena = selected, effectiveMinutes > 0 else { return }
                onAdd(arena, effectiveMinutes)
            } label: {
                HStack(spacing: 8) {
                    if let sel = selected {
                        Text(sel.icon).font(.system(size: 14))
                        Text("+ \(sel.label)  \(effectiveMinutes)m")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .kerning(3)
                    } else {
                        Text("SELECT AN ARENA ABOVE")
                            .font(.system(size: 12, design: .monospaced))
                            .kerning(3)
                    }
                }
                .foregroundStyle(selected != nil && effectiveMinutes > 0 ? Color(hex: "#080810") : Color.white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selected != nil && effectiveMinutes > 0 ? Color(hex: "#E8C547") : Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(selected == nil || effectiveMinutes <= 0)
            .padding(.horizontal, 22)
            .padding(.bottom, 32)
        }
    }
}
