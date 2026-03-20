// SelectView.swift — Arena Protocol
// Session configuration: quest note, sub-arena, duration, launch

import SwiftUI
import EventKit

struct SelectView: View {
    @Environment(DataStore.self) private var store
    let arena: Arena
    var navigate: (Screen) -> Void

    @State private var note = ""
    @State private var selectedDuration = 25
    @State private var isCustomActive = false
    @State private var customMinutes = ""
    @State private var activeSubArena: String? = nil
    @State private var calEvents: [EKEvent] = []
    @State private var ongoingMatch: EKEvent? = nil
    @State private var isSocial = false
    @FocusState private var customFocused: Bool

    private var arenaColor: Color { Color(hex: arena.color) }
    private var effectiveDuration: Int {
        if isCustomActive, let v = Int(customMinutes), v > 0 {
            return v
        }
        return selectedDuration
    }
    private var durationValid: Bool {
        !isCustomActive || (Int(customMinutes) ?? 0) > 0
    }
    private var subArenaKeys: [String] { Array(arena.subArenas.keys).sorted() }
    private var filteredExamples: [String]? {
        guard let k = activeSubArena else { return nil }
        return arena.subArenas[k]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            // swipe-up on the scroll view dismisses keyboard
            VStack(alignment: .leading, spacing: 0) {
                backButton
                arenaHeader
                questField
                if !subArenaKeys.isEmpty { subArenaSection }
                if let event = ongoingMatch { resumeFromCalBanner(event: event) }
                if !calEvents.isEmpty { calFeedSection }
                durationSection
                socialToggle
                launchSection
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            calEvents = CalendarManager.shared.upcomingEvents(hours: 8)
            ongoingMatch = CalendarManager.shared.activeEvents().first(where: { event in
                let matched = CalendarManager.shared.matchArena(for: event, arenas: store.arenas)
                return matched?.id == arena.id
                    || (event.title ?? "").hasPrefix("[\(arena.label)]")
            })
        }
    }

    // MARK: - Back

    private var backButton: some View {
        Button { navigate(.home) } label: {
            Text("← BACK")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.35))
                .kerning(4)
        }
        .buttonStyle(.plain)
        .padding(.top, 48)
        .padding(.bottom, 36)
    }

    // MARK: - Arena Header

    private var arenaHeader: some View {
        ZStack(alignment: .topTrailing) {
            ArenaIllustration(arenaId: arena.id, color: arenaColor)
                .frame(width: 160, height: 180)
                .opacity(0.07)
                .blendMode(.screen)
                .offset(x: 24)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                Text("ARENA \(arena.letter)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 6)

                Text(arena.label)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(arenaColor)
                    .shadow(color: arenaColor.opacity(0.4), radius: 20)
                    .kerning(3)
                    .padding(.bottom, 10)

                Text(arena.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .lineSpacing(6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Quest

    private var questField: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY'S QUEST")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(arenaColor.opacity(0.8))
                .kerning(5)
                .padding(.bottom, 12)

            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("Name your quest for this arena...")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .padding(14)
                }
                TextEditor(text: $note)
                    .font(.system(size: note.isEmpty ? 13 : 15, weight: note.isEmpty ? .regular : .bold, design: .monospaced))
                    .foregroundStyle(note.isEmpty ? Color.white.opacity(0.35) : arenaColor)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 64)
                    .padding(10)
            }
            .background(note.isEmpty ? Color.white.opacity(0.03) : arenaColor.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(note.isEmpty ? Color.white.opacity(0.1) : arenaColor.opacity(0.6), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: note.isEmpty ? .clear : arenaColor.opacity(0.12), radius: 12)

            if !note.isEmpty {
                Text("▸ YOUR QUEST IS SET")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(arenaColor.opacity(0.6))
                    .kerning(3)
                    .padding(.top, 6)
            }
        }
        .padding(.bottom, 28)
    }

    // MARK: - Sub-Arena

    private var subArenaSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FOCUS AREA")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(5)
                .padding(.bottom, 10)

            FlowLayout(spacing: 8) {
                ForEach(subArenaKeys, id: \.self) { key in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeSubArena = activeSubArena == key ? nil : key
                        }
                    } label: {
                        Text(key)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(activeSubArena == key ? arenaColor : Color.white.opacity(0.45))
                            .kerning(3)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(activeSubArena == key ? arenaColor.opacity(0.2) : Color.white.opacity(0.03))
                            .overlay(
                                Capsule()
                                    .strokeBorder(activeSubArena == key ? arenaColor : Color.white.opacity(0.12), lineWidth: activeSubArena == key ? 1.5 : 1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 14)

            if let examples = filteredExamples {
                VStack(spacing: 6) {
                    ForEach(examples, id: \.self) { ex in
                        Button { note = ex } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(arenaColor.opacity(note == ex ? 1 : 0.4))
                                    .frame(width: 5, height: 5)
                                Text(ex)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(note == ex ? arenaColor : Color.white.opacity(0.55))
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(note == ex ? arenaColor.opacity(0.15) : Color.white.opacity(0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(note == ex ? arenaColor.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .offset(y: -8)))
                .animation(.easeInOut(duration: 0.2), value: activeSubArena)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Calendar Feed

    private var calFeedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("📅")
                    .font(.system(size: 10))
                Text("FROM YOUR CALENDAR")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(5)
            }
            .padding(.bottom, 10)

            VStack(spacing: 6) {
                ForEach(calEvents.prefix(4), id: \.eventIdentifier) { event in
                    let dur  = event.startDate.minutesUntil(event.endDate)
                    let when = event.startDate.relativeShort()
                    let matched = CalendarManager.shared.matchArena(for: event, arenas: store.arenas)
                    let isThisArena = matched?.id == arena.id
                    let accent: Color = matched.map { Color(hex: $0.color) } ?? arenaColor.opacity(0.5)

                    Button {
                        // Pre-fill note with event title; set duration to match event length
                        note = event.title ?? ""
                        let snapped = [5, 10, 15, 25, 30, 45, 60, 90].min(by: { abs($0 - dur) < abs($1 - dur) }) ?? dur
                        if DURATIONS.contains(snapped) {
                            selectedDuration = snapped
                            isCustomActive = false
                        } else {
                            isCustomActive = true
                            customMinutes = "\(dur)"
                        }
                    } label: {
                        HStack(spacing: 10) {
                            // Color strip
                            RoundedRectangle(cornerRadius: 2)
                                .fill(accent)
                                .frame(width: 3, height: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title ?? "Untitled")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(isThisArena ? accent : Color.white.opacity(0.7))
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    Text(when)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.3))
                                    Text("·")
                                        .foregroundStyle(Color.white.opacity(0.2))
                                    Text("\(dur)m")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.3))
                                    if let m = matched {
                                        Text("·")
                                            .foregroundStyle(Color.white.opacity(0.2))
                                        Text(m.label)
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundStyle(accent.opacity(0.7))
                                            .kerning(1)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 10))
                                .foregroundStyle(accent.opacity(0.5))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isThisArena ? accent.opacity(0.07) : Color.white.opacity(0.02))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isThisArena ? accent.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: note)
                }
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Duration

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BLOCK DURATION")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(5)
                .padding(.bottom, 10)

            FlowLayout(spacing: 8) {
                ForEach(DURATIONS, id: \.self) { d in
                    Button {
                        selectedDuration = d
                        isCustomActive = false
                    } label: {
                        Text("\(d)m")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(!isCustomActive && selectedDuration == d ? arenaColor : Color.white.opacity(0.4))
                            .kerning(2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(!isCustomActive && selectedDuration == d ? arenaColor.opacity(0.18) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(!isCustomActive && selectedDuration == d ? arenaColor : Color.white.opacity(0.1),
                                                  lineWidth: !isCustomActive && selectedDuration == d ? 1.5 : 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                Button { isCustomActive = true; customFocused = true } label: {
                    Text("other")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(isCustomActive ? arenaColor : Color.white.opacity(0.4))
                        .kerning(2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(isCustomActive ? arenaColor.opacity(0.18) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(isCustomActive ? arenaColor : Color.white.opacity(0.1),
                                              lineWidth: isCustomActive ? 1.5 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            if isCustomActive {
                HStack(spacing: 10) {
                    TextField("min", text: $customMinutes)
                        .keyboardType(.numberPad)
                        .focused($customFocused)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(arenaColor)
                        .padding(12)
                        .background(arenaColor.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(arenaColor, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(maxWidth: 120)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("DONE") { customFocused = false }
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(arenaColor)
                            }
                        }
                    Text("MINUTES")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(2)
                }
                .padding(.top, 10)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Launch

    private var launchSection: some View {
        VStack(spacing: 8) {
            Button { if durationValid { startSession() } } label: {
                HStack(spacing: 10) {
                    Text(arena.icon).font(.system(size: 16))
                    Text("ENTER THE ARENA")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .kerning(4)
                }
                .foregroundStyle(durationValid ? Color(hex: "#080810") : Color.white.opacity(0.2))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(durationValid ? arenaColor : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(!durationValid)

            if !durationValid {
                Text("ENTER A DURATION FIRST")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(2)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if CalendarManager.shared.isWriteAuthorized {
                Text("📅 session will be logged to Arena Protocol calendar")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.18))
                    .kerning(1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Social Toggle

    private var socialToggle: some View {
        let socialColor = Color(hex: "#B794F4")
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SOCIAL")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isSocial ? socialColor : Color.white.opacity(0.4))
                    .kerning(5)
                Text("with others")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
            }
            Spacer()
            Toggle("", isOn: $isSocial)
                .tint(socialColor)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isSocial ? socialColor.opacity(0.08) : Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSocial ? socialColor.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 20)
    }

    // MARK: - Calendar Resume Banner

    private func resumeFromCalBanner(event: EKEvent) -> some View {
        let remaining = max(1, Int(event.endDate.timeIntervalSinceNow / 60))
        let rawTitle = event.title ?? ""
        let prefix = "[\(arena.label)] "
        let eventNote = rawTitle.hasPrefix(prefix)
            ? String(rawTitle.dropFirst(prefix.count))
            : rawTitle
        let accent = arenaColor

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("▶")
                    .font(.system(size: 9))
                    .foregroundStyle(accent)
                Text("IN PROGRESS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(accent.opacity(0.8))
                    .kerning(5)
            }
            .padding(.bottom, 8)

            Button { resumeSession(event: event, minutes: remaining, note: eventNote) } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(rawTitle)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(accent)
                            .lineLimit(1)
                        Text("\(remaining)m remaining · ends \(event.endDate.relativeShort())")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(accent.opacity(0.55))
                    }
                    Spacer()
                    Text("RESUME")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(accent.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(accent.opacity(0.5), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Actions

    private func resumeSession(event: EKEvent, minutes: Int, note: String) {
        scheduleNotification(id: "session_1", title: "\(arena.label) session complete",
                             body: "Your focus block has ended.",
                             secondsFromNow: TimeInterval(minutes * 60))
        navigate(.active(arena, minutes, note, isSocial))
    }

    private func startSession() {
        let dur = effectiveDuration
        guard dur > 0 else { return }
        scheduleNotification(id: "session_1", title: "\(arena.label) session complete",
                             body: "Your focus block has ended.",
                             secondsFromNow: TimeInterval(dur * 60))
        navigate(.active(arena, dur, note, isSocial))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if rowWidth + s.width > width && rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0; rowHeight = 0
            }
            rowWidth += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: width, height: height + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing; x = bounds.minX; rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}

// Swift 5.9+ custom operator for optional binding
extension Optional where Wrapped == Int {
    var orZero: Int { self ?? 0 }
}
