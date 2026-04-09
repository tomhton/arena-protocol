// SessionDisplayView.swift — Arena Protocol
// Inline active session display for the hub page.
// Renders the active timer, pause/resume, done, joint arenas, timeline, stacked sessions.
// Does NOT own a timer — HomeView's 1-second tick drives sessionNow.

import SwiftUI
import ActivityKit
import WidgetKit

struct SessionDisplayView: View {
    @Environment(DataStore.self) private var store
    let sessionNow: Date
    var onDone: (Arena, Int, String, Bool) -> Void
    var navigate: (Screen) -> Void

    @State private var showJointPicker = false
    @State private var showConcurrentConfirm = false
    @State private var showAbandonConfirm = false
    @State private var showChecklist = false
    @State private var editingEntry: JointArenaEntry? = nil

    private var active: ActiveSessionState? { store.activeSession }
    private var stacked: [ActiveSessionState] { store.stackedSessions }
    private var src: ActiveSessionState? { active ?? stacked.first }
    private var curSlot: (arena: Arena, start: Date, end: Date)? { src?.currentSlot(now: sessionNow) }

    private var liveArena: Arena { curSlot?.arena ?? active?.arena ?? stacked.first?.arena ?? DEFAULT_ARENAS[0] }
    private var liveColor: Color { Color(hex: liveArena.color) }
    private var liveEnd: Date { curSlot?.end ?? active?.endTime ?? stacked.first?.endTime ?? Date() }
    private var jointEntries: [JointArenaEntry] { active?.jointEntries ?? [] }
    private var totalCount: Int { (active != nil ? 1 : 0) + jointEntries.count + stacked.count }

    private var futureSlots: [(arena: Arena, start: Date, end: Date)] {
        src?.timeline.filter { $0.start > sessionNow } ?? []
    }
    private var subStacked: [ActiveSessionState] {
        active != nil ? stacked : Array(stacked.dropFirst())
    }

    private var nextScheduledBlock: ScheduledBlock? {
        store.scheduledBlocks
            .filter { $0.scheduledAt > Date() && $0.scheduledAt < Date().addingTimeInterval(4 * 3600) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Current arena block
            currentArenaSection

            // Progress bar for current slot
            slotProgressBar

            // Pause / Done controls
            if let a = active {
                controlsRow(session: a)
            }

            // Timeline
            if !futureSlots.isEmpty {
                timelineSection
            }

            // Upcoming deadlines/scheduled
            if let block = nextScheduledBlock {
                upcomingSection(block: block)
            }

            // Stacked sessions
            if !subStacked.isEmpty {
                stackedSection
            }

            // Add arena + done row
            actionRow
        }
        .background(liveColor.opacity(0.08))
        .animation(.easeInOut(duration: 0.5), value: liveColor.description)
        .sheet(isPresented: $showJointPicker) {
            JointArenaPicker(allArenas: store.letteredArenas) { pickedArena, pickedMinutes, pickedNote in
                addJoint(arena: pickedArena, minutes: pickedMinutes, note: pickedNote)
            }
            .presentationDetents([.fraction(0.6)])
            .presentationBackground(Color(hex: "#080810"))
        }
        .sheet(isPresented: $showChecklist) {
            ChecklistPanelView(sessionId: active?.arena.id)
                .presentationDetents([.fraction(0.4), .fraction(0.75)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(hex: "#080810"))
        }
        .sheet(item: $editingEntry) { entry in
            JointEntryEditSheet(
                entry: entry,
                allArenas: store.letteredArenas,
                jointEntries: jointEntries,
                onEdit: { newArena, newDuration in
                    store.editJoint(entryId: entry.id, newArena: newArena, newDuration: newDuration)
                    #if canImport(ActivityKit)
                    store.syncLiveActivity(force: true)
                    #endif
                },
                onRemove: {
                    store.removeJoint(entryId: entry.id)
                    #if canImport(ActivityKit)
                    store.syncLiveActivity(force: true)
                    #endif
                },
                onInsertBefore: { arena, minutes in
                    if let idx = jointEntries.firstIndex(where: { $0.id == entry.id }) {
                        store.insertJoint(arena: arena, minutes: minutes, atIndex: idx)
                        #if canImport(ActivityKit)
                        store.syncLiveActivity(force: true)
                        #endif
                    }
                }
            )
            .presentationDetents([.fraction(0.55)])
            .presentationBackground(Color(hex: "#080810"))
        }
    }

    // MARK: - Current Arena

    private var currentArenaSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(liveArena.icon).font(.system(size: 18))
                Text(liveArena.label)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .kerning(2)
                Spacer()
                timerDisplay
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            HStack(spacing: 8) {
                Text("ENDS  \(formattedTime(liveEnd))")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(liveColor.opacity(0.55))
                    .kerning(2)
                if let note = active?.note, !note.isEmpty {
                    Text("·").foregroundStyle(Color.white.opacity(0.15))
                    Text(note)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var timerDisplay: some View {
        if let a = active, a.isPaused {
            let s = Int(a.pausedRemaining)
            Text(String(format: "%d:%02d", s / 60, s % 60))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(liveColor.opacity(0.55))
                .monospacedDigit()
        } else if liveEnd > sessionNow {
            Text(liveEnd, style: .timer)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(liveColor)
                .monospacedDigit()
        } else {
            Text("0:00")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(liveColor.opacity(0.5))
                .monospacedDigit()
        }
    }

    // MARK: - Controls

    private func controlsRow(session: ActiveSessionState) -> some View {
        HStack(spacing: 10) {
            Button { store.togglePause() } label: {
                Text(session.isPaused ? "▶  RESUME" : "⏸  PAUSE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(liveColor)
                    .kerning(2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(liveColor.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(liveColor.opacity(0.5), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                finishEarly()
            } label: {
                Text("DONE ✓")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#080810"))
                    .kerning(2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(liveColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Progress Bar

    private var slotProgressBar: some View {
        Group {
            if let slot = curSlot {
                let elapsed = sessionNow.timeIntervalSince(slot.start)
                let total = slot.end.timeIntervalSince(slot.start)
                let fraction = total > 0 ? max(0, min(1, 1.0 - elapsed / total)) : 0

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(liveColor.opacity(0.12))
                            .frame(height: 3)
                        Capsule()
                            .fill(liveColor)
                            .frame(width: geo.size.width * fraction, height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 20)
            Text("TIMELINE")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(4)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 6)

            // Interactive bubbles for joint entries
            let entrySlotPairs = matchedEntrySlots()
            ForEach(entrySlotPairs, id: \.entry.id) { pair in
                let sc = Color(hex: pair.entry.arena.color)
                let slotMins = pair.entry.minutes
                Button {
                    editingEntry = pair.entry
                } label: {
                    HStack(spacing: 8) {
                        Text(pair.entry.arena.icon)
                            .font(.system(size: 13))
                        Text(pair.entry.arena.label)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(sc.opacity(0.85))
                            .kerning(2)
                        Text("\(slotMins)m")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(sc.opacity(0.4))
                        Spacer()
                        Text("\(formattedTime(pair.entry.scheduledStart)) → \(formattedTime(pair.entry.scheduledEnd))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(sc.opacity(0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(sc.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(sc.opacity(0.15), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 3)
            }

            // Show any future slots that don't match joint entries (e.g. primary arena overflow)
            let unmatchedSlots = futureSlots.filter { slot in
                !entrySlotPairs.contains { $0.entry.scheduledStart == slot.start }
            }
            ForEach(Array(unmatchedSlots.enumerated()), id: \.offset) { _, slot in
                let sc = Color(hex: slot.arena.color)
                let slotMins = max(1, Int(slot.end.timeIntervalSince(slot.start) / 60))
                HStack(spacing: 10) {
                    Text(slot.arena.icon).font(.system(size: 13)).foregroundStyle(sc.opacity(0.65))
                    Text(slot.arena.label)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(sc.opacity(0.75)).kerning(2)
                    Text("·  \(slotMins)m")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(sc.opacity(0.35))
                    Spacer()
                    Text("\(formattedTime(slot.start)) → \(formattedTime(slot.end))")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(sc.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
        }
    }

    /// Match future joint entries to display as interactive bubbles
    private func matchedEntrySlots() -> [(entry: JointArenaEntry, slot: (arena: Arena, start: Date, end: Date)?)] {
        jointEntries
            .filter { $0.scheduledStart > sessionNow }
            .map { entry in
                let matchingSlot = futureSlots.first { $0.start == entry.scheduledStart }
                return (entry: entry, slot: matchingSlot)
            }
    }

    // MARK: - Upcoming

    private func upcomingSection(block: ScheduledBlock) -> some View {
        let color = Color(hex: block.itemColor)
        let when = block.scheduledAt.relativeShort()

        return VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 4)
            Text("UPCOMING")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(4)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
            HStack(spacing: 10) {
                Text(block.itemGlyph).font(.system(size: 13))
                Text(block.itemLabel)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(color).kerning(2)
                Text("·  \(when)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.3))
                Text("·  \(block.durationMins)m")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.3))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Stacked

    private var stackedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 4)
            Text("STACKED")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(4)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 2)
            ForEach(subStacked, id: \.arena.id) { s in
                let sSlot  = s.currentSlot(now: sessionNow)
                let sArena = sSlot?.arena ?? s.arena
                let sColor = Color(hex: sArena.color)
                let sEnd   = sSlot?.end ?? s.endTime
                Button {
                    store.unstashSession(arenaId: s.arena.id)
                } label: {
                    HStack(spacing: 10) {
                        Text(sArena.icon).font(.system(size: 13)).foregroundStyle(sColor)
                        Text(sArena.label)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(sColor.opacity(0.8)).kerning(2)
                        Spacer()
                        if sEnd > sessionNow {
                            Text(sEnd, style: .timer)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(sColor.opacity(0.7))
                                .monospacedDigit()
                        } else {
                            Text("0:00")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(sColor.opacity(0.45))
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button { showJointPicker = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 11))
                    Text("ADD ARENA")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .kerning(3)
                }
                .foregroundStyle(liveColor.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(liveColor.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(liveColor.opacity(0.2), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Button { showChecklist = true } label: {
                HStack(spacing: 6) {
                    Text("☐")
                        .font(.system(size: 10))
                    Text("TASKS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .kerning(3)
                }
                .foregroundStyle(Color(hex: "#E8C547").opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#E8C547").opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: "#E8C547").opacity(0.2), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                abandonSession()
            } label: {
                Text("ABANDON")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.18))
                    .kerning(2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func formattedTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        fmt.timeZone = TimeZone(identifier: store.settings.clockTimezone) ?? .current
        return fmt.string(from: date)
    }

    // MARK: - Session Actions

    private func finishEarly() {
        guard let session = active else { return }
        cancelNotification(id: "session_1")
        let now = Date()

        // Update primary calendar event
        if let id = session.calEventId {
            CalendarManager.shared.updateEventEnd(id: id, newEnd: now)
        }
        // Update or delete joint calendar events
        for entry in session.jointEntries {
            if let id = entry.calEventId {
                if entry.scheduledStart <= now {
                    CalendarManager.shared.updateEventEnd(id: id, newEnd: min(entry.scheduledEnd, now))
                } else {
                    CalendarManager.shared.deleteEvent(id: id)
                }
            }
        }

        // End Live Activity
        endLiveActivity()

        // Log joint arenas
        for entry in session.jointEntries {
            store.addSession(Session(arenaId: entry.arena.id, duration: entry.minutes,
                                     date: todayString(), note: session.note,
                                     ts: Date().timeIntervalSince1970 * 1000,
                                     social: session.social))
        }

        let arena = session.arena
        let duration = session.durationMins
        let note = session.note
        let social = session.social

        store.endSession()
        // Defer completion overlay to next render pass so SwiftUI doesn't
        // simultaneously remove SessionDisplayView and insert CompletionOverlay
        // with competing transition animations (causes crash).
        Task { @MainActor in
            onDone(arena, duration, note, social)
        }
    }

    private func abandonSession() {
        guard let session = active else { return }
        cancelNotification(id: "session_1")
        let now = Date()
        let elapsed = now.timeIntervalSince(session.startTime)
        if let id = session.calEventId {
            if elapsed < 60 {
                CalendarManager.shared.deleteEvent(id: id)
            } else {
                CalendarManager.shared.updateEventEnd(id: id, newEnd: now)
            }
        }
        for entry in session.jointEntries {
            if let id = entry.calEventId {
                CalendarManager.shared.deleteEvent(id: id)
            }
        }
        endLiveActivity()
        store.endSession()
    }

    private func addJoint(arena: Arena, minutes: Int, note: String = "") {
        guard var session = store.activeSession else { return }
        let jointStart = session.endTime
        let jointEnd = jointStart.addingTimeInterval(TimeInterval(minutes * 60))
        var entry = JointArenaEntry(arena: arena, minutes: minutes, note: note)
        entry.scheduledStart = jointStart
        entry.scheduledEnd = jointEnd
        session.jointEntries.append(entry)
        session.endTime = jointEnd
        store.activeSession = session
        showJointPicker = false

        // Update Live Activity with new timeline and schedule background transitions
        #if canImport(ActivityKit)
        store.syncLiveActivity(force: true)
        store.scheduleLiveActivityTransitions()
        #endif

        let entryId = entry.id
        let arenaLabel = arena.label
        let desc = arena.description
        Task { @MainActor in
            if !CalendarManager.shared.isReadAuthorized {
                _ = await CalendarManager.shared.requestFullAccess()
            }
            let calId = CalendarManager.shared.addEvent(title: "[\(arenaLabel)]", start: jointStart, end: jointEnd, notes: desc)
            if var s = store.activeSession,
               let idx = s.jointEntries.firstIndex(where: { $0.id == entryId }) {
                s.jointEntries[idx].calEventId = calId
                store.activeSession = s
            }
        }
    }

    private func endLiveActivity() {
        #if canImport(ActivityKit)
        let currentEndTime = store.activeSession?.endTime ?? Date()
        Task {
            let finalState = ArenaLiveActivityAttributes.ContentState(
                endTime: currentEndTime,
                isPaused: false,
                pausedRemaining: 0
            )
            for activity in Activity<ArenaLiveActivityAttributes>.activities {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .default
                )
            }
        }
        #endif
        SharedStore.clearActiveSession()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Joint Entry Edit Sheet

struct JointEntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: JointArenaEntry
    let allArenas: [Arena]
    let jointEntries: [JointArenaEntry]
    var onEdit: (Arena?, Int?) -> Void
    var onRemove: () -> Void
    var onInsertBefore: (Arena, Int) -> Void

    @State private var selectedArena: Arena
    @State private var selectedDuration: Int
    @State private var showInsertPicker = false
    @State private var insertArena: Arena?
    @State private var insertDuration: Int = 15

    private let durationPresets = [5, 10, 15, 25, 30, 45, 60]

    init(entry: JointArenaEntry, allArenas: [Arena], jointEntries: [JointArenaEntry],
         onEdit: @escaping (Arena?, Int?) -> Void,
         onRemove: @escaping () -> Void,
         onInsertBefore: @escaping (Arena, Int) -> Void) {
        self.entry = entry
        self.allArenas = allArenas
        self.jointEntries = jointEntries
        self.onEdit = onEdit
        self.onRemove = onRemove
        self.onInsertBefore = onInsertBefore
        _selectedArena = State(initialValue: entry.arena)
        _selectedDuration = State(initialValue: entry.minutes)
        _insertArena = State(initialValue: allArenas.first)
    }

    var body: some View {
        let entryColor = Color(hex: selectedArena.color)
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("EDIT ARENA")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(entryColor)
                    .kerning(3)
                Spacer()
                Button { dismiss() } label: {
                    Text("✕")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Arena picker
            Text("ARENA")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(4)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allArenas) { arena in
                        let ac = Color(hex: arena.color)
                        let isSelected = arena.id == selectedArena.id
                        Button {
                            selectedArena = arena
                        } label: {
                            HStack(spacing: 4) {
                                Text(arena.icon).font(.system(size: 11))
                                Text(arena.label)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isSelected ? ac : ac.opacity(0.5))
                                    .kerning(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? ac.opacity(0.15) : ac.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(isSelected ? ac.opacity(0.6) : ac.opacity(0.12), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            // Duration picker
            Text("DURATION")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(4)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(durationPresets, id: \.self) { mins in
                        let isSelected = mins == selectedDuration
                        Button {
                            selectedDuration = mins
                        } label: {
                            Text("\(mins)m")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? entryColor : entryColor.opacity(0.4))
                                .kerning(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSelected ? entryColor.opacity(0.15) : entryColor.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(isSelected ? entryColor.opacity(0.6) : entryColor.opacity(0.12), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)

            // Action buttons
            HStack(spacing: 10) {
                // Save changes
                Button {
                    let newArena: Arena? = selectedArena.id != entry.arena.id ? selectedArena : nil
                    let newDuration: Int? = selectedDuration != entry.minutes ? selectedDuration : nil
                    if newArena != nil || newDuration != nil {
                        onEdit(newArena, newDuration)
                    }
                    dismiss()
                } label: {
                    Text("SAVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(2)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(entryColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                // Insert before
                Button {
                    showInsertPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 9))
                        Text("INSERT BEFORE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .kerning(2)
                    }
                    .foregroundStyle(entryColor.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(entryColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(entryColor.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Spacer()

                // Remove
                Button {
                    onRemove()
                    dismiss()
                } label: {
                    Text("REMOVE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#FF4444").opacity(0.7))
                        .kerning(2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#FF4444").opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(hex: "#FF4444").opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(hex: "#080810").ignoresSafeArea())
        .sheet(isPresented: $showInsertPicker) {
            JointArenaPicker(allArenas: allArenas) { pickedArena, pickedMinutes, _ in
                onInsertBefore(pickedArena, pickedMinutes)
                showInsertPicker = false
                dismiss()
            }
            .presentationDetents([.fraction(0.6)])
            .presentationBackground(Color(hex: "#080810"))
        }
    }
}
