// HistoryView.swift — Arena Protocol
// Stats, habit grids, session log, journal entries, data export

import SwiftUI

enum HistoryTab: String, CaseIterable {
    case chart   = "CHART"
    case habits  = "HABITS"
    case log     = "LOG"
    case journal = "JOURNAL"
}

struct HistoryView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var tab: HistoryTab = .chart
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    private var sessions: [Session]     { store.sessions }
    private var arenas: [Arena]         { store.letteredArenas }
    private var habits: [Habit]         { store.habits }
    private var habitLogs: [HabitLog]   { store.habitLogs }
    private var journals: [JournalEntry]{ store.journals }

    private var totalSessions: Int  { sessions.count }
    private var totalMinutes:  Int  { sessions.reduce(0) { $0 + $1.duration } }
    private var activeDays:    Int  { Set(sessions.map { $0.date }).count }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                statCards
                exportButtons
                tabBar
                tabContent
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
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
            .padding(.top, 52)
            .padding(.bottom, 24)

            Text("YOUR RECORD")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.25))
                .kerning(7)
                .padding(.bottom, 4)
            HStack(spacing: 6) {
                Text("ARENA")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .kerning(2)
                Text("HISTORY")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#B794F4"))
                    .kerning(2)
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: 10) {
            ForEach([("SESSIONS", totalSessions), ("MINUTES", totalMinutes), ("DAYS", activeDays)], id: \.0) { item in
                VStack(spacing: 4) {
                    Text("\(item.1)")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#E8E8E8"))
                    Text(item.0)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.07), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.bottom, 14)
    }

    // MARK: - Export Buttons

    private var exportButtons: some View {
        HStack(spacing: 8) {
            Button { exportCSV() } label: {
                Text("↓ CSV")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color(hex: "#4ECDC4"))
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#4ECDC4").opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#4ECDC4").opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Button { exportJSON() } label: {
                Text("↓ JSON")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color(hex: "#B794F4"))
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#B794F4").opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#B794F4").opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            VStack {
                Text("NOTION · OBSIDIAN · SHEETS")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .kerning(1)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.02))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.bottom, 20)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryTab.allCases, id: \.self) { t in
                    Button { withAnimation { tab = t } } label: {
                        Text(t.rawValue)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(tab == t ? Color(hex: "#B794F4") : Color.white.opacity(0.35))
                            .kerning(3)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(tab == t ? Color(hex: "#B794F4").opacity(0.12) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(tab == t ? Color(hex: "#B794F4") : Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .chart:   chartTab
        case .habits:  habitsTab
        case .log:     logTab
        case .journal: journalTab
        }
    }

    // MARK: - Chart Tab

    private var chartTab: some View {
        let weekData = getWeeklyData(sessions: sessions)
        let maxCount = weekData.map { $0.sessions.count }.max() ?? 1

        return VStack(alignment: .leading, spacing: 20) {
            // 7-day bar chart
            VStack(alignment: .leading, spacing: 16) {
                Text("7-DAY ACTIVITY")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(5)

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(weekData, id: \.date) { day in
                        let isToday = day.date == todayString()
                        let topArena = arenas.first { $0.id == day.arenas.first }
                        let barHeight = day.sessions.isEmpty ? 4.0 : max(CGFloat(day.sessions.count) / CGFloat(maxCount) * 64, 8)

                        VStack(spacing: 6) {
                            ZStack {
                                if day.sessions.isEmpty {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.06))
                                        .frame(width: 34, height: 4)
                                } else {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: topArena?.color ?? "#E8C547").opacity(isToday ? 1 : 0.6))
                                        .frame(width: 34, height: barHeight)
                                        .overlay(
                                            day.sessions.count > 1 ?
                                            Text("\(day.sessions.count)")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundStyle(Color(hex: "#080810")) : nil
                                        )
                                }
                            }
                            .frame(height: 64, alignment: .bottom)
                            Text(day.label)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(isToday ? Color(hex: "#E8C547") : Color.white.opacity(0.25))
                                .kerning(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.02))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Arena breakdown
            Text("ARENA BREAKDOWN")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.22))
                .kerning(5)

            VStack(spacing: 10) {
                ForEach(arenaStats) { stat in
                    let pct = totalSessions > 0 ? Double(stat.total) / Double(totalSessions) : 0
                    let neglected = pct < 0.1 && totalSessions > 5

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(stat.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: stat.color))
                            Text(stat.label)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color(hex: "#E8E8E8"))
                                .kerning(2)
                            if stat.streak > 1 {
                                Text("🔥\(stat.streak)d")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color(hex: stat.color))
                            }
                            if neglected {
                                Text("NEGLECTED")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(Color.red.opacity(0.7))
                                    .kerning(1)
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .overlay(Capsule().strokeBorder(Color.red.opacity(0.3), lineWidth: 1))
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(stat.total)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: stat.color))
                                Text("\(stat.minutes)m")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.2))
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.06)).frame(height: 3)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: stat.color))
                                    .frame(width: geo.size.width * pct, height: 3)
                                    .animation(.easeInOut(duration: 0.5), value: pct)
                            }
                        }
                        .frame(height: 3)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(neglected ? Color.red.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private struct ArenaStat: Identifiable {
        var id: String
        var icon: String
        var label: String
        var color: String
        var total: Int
        var streak: Int
        var minutes: Int
    }

    private var arenaStats: [ArenaStat] {
        arenas.map { a in
            ArenaStat(id: a.id, icon: a.icon, label: a.label, color: a.color,
                      total: sessions.filter { $0.arenaId == a.id }.count,
                      streak: getStreakForArena(arenaId: a.id, sessions: sessions),
                      minutes: sessions.filter { $0.arenaId == a.id }.reduce(0) { $0 + $1.duration })
        }.sorted { $0.total > $1.total }
    }

    // MARK: - Habits Tab

    private var habitsTab: some View {
        VStack(spacing: 20) {
            if habits.isEmpty {
                VStack(spacing: 8) {
                    Text("NO HABITS TRACKED YET")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .kerning(3)
                    Text("ADD HABITS IN SETTINGS")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.12))
                        .kerning(2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 40)
            }
            ForEach(habits) { habit in
                habitCard(habit)
            }
        }
    }

    private func habitCard(_ habit: Habit) -> some View {
        let grid   = getHabitGrid(habitId: habit.id, logs: habitLogs)
        let streak = getHabitStreak(habitId: habit.id, logs: habitLogs)
        let total  = habitLogs.filter { $0.habitId == habit.id && $0.value }.count
        let logged = habitLogs.filter { $0.habitId == habit.id }.count
        let rate   = logged > 0 ? Int(Double(total) / Double(logged) * 100) : 0
        let weeks  = stride(from: 0, to: 70, by: 7).map { Array(grid[$0..<min($0+7, grid.count)]) }
        let hColor = Color(hex: habit.color)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(hColor)
                        .kerning(2)
                    if !habit.goal.isEmpty {
                        Text(habit.goal)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                }
                Spacer()
                HStack(spacing: 12) {
                    statPill("\(streak)", "STREAK", hColor)
                    statPill("\(rate)%", "RATE", Color.white.opacity(0.8))
                }
            }
            // 70-day grid
            HStack(alignment: .top, spacing: 3) {
                ForEach(weeks.indices, id: \.self) { wi in
                    VStack(spacing: 3) {
                        ForEach(weeks[wi].indices, id: \.self) { di in
                            let cell = weeks[wi][di]
                            RoundedRectangle(cornerRadius: 2)
                                .fill(cell.value == true ? hColor : cell.value == false ? Color.red.opacity(0.3) : Color.white.opacity(0.06))
                                .opacity(cell.value == true ? 1 : cell.value == false ? 0.8 : 0.4)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
            HStack(spacing: 12) {
                legendDot(hColor, "YES")
                legendDot(Color.red.opacity(0.6), "NO")
                legendDot(Color.white.opacity(0.2), "UNLOGGED")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.02))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(hColor.opacity(0.25), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statPill(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(color)
            Text(label).font(.system(size: 8, design: .monospaced)).foregroundStyle(Color.white.opacity(0.25)).kerning(2)
        }
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 8, design: .monospaced)).foregroundStyle(Color.white.opacity(0.25)).kerning(2)
        }
    }

    // MARK: - Log Tab

    private var logTab: some View {
        VStack(spacing: 8) {
            if sessions.isEmpty {
                Text("NO SESSIONS YET")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.18))
                    .kerning(3)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
            }
            ForEach(sessions.reversed()) { session in
                let arena = arenas.first { $0.id == session.arenaId }
                let aColor = Color(hex: arena?.color ?? "#708090")
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(aColor.opacity(0.15))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(aColor.opacity(0.4), lineWidth: 1))
                        .frame(width: 36, height: 36)
                        .overlay(Text(arena?.icon ?? "△").font(.system(size: 16)).foregroundStyle(aColor))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(arena?.label ?? session.arenaId)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(aColor)
                            .kerning(2)
                        if !session.note.isEmpty {
                            Text(session.note)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.white.opacity(0.35))
                                .italic()
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(session.duration)m")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.8))
                        Text(session.date == todayString() ? "today" : String(session.date.suffix(5)))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.02))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Journal Tab

    private var journalTab: some View {
        VStack(spacing: 10) {
            if journals.isEmpty {
                Text("NO JOURNAL ENTRIES YET")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.18))
                    .kerning(3)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
            }
            ForEach(journals.reversed(), id: \.ts) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.date)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(hex: "#B794F4"))
                        .kerning(3)
                    Text(entry.text)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineSpacing(4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.02))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#B794F4").opacity(0.15), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Export

    private func exportCSV() {
        let csv = store.exportCSV()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("arena_sessions_\(todayString()).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        shareItems = [url]
        showShareSheet = true
    }

    private func exportJSON() {
        let data: [String: Any] = [
            "exported": ISO8601DateFormatter().string(from: Date()),
            "platform": "Arena Protocol",
            "sessions": sessions.map { s -> [String: Any] in
                ["arenaId": s.arenaId, "duration": s.duration, "date": s.date, "note": s.note,
                 "arenaLabel": arenas.first { $0.id == s.arenaId }?.label ?? s.arenaId]
            },
            "summary": [
                "totalSessions": sessions.count,
                "totalMinutes": sessions.reduce(0) { $0 + $1.duration },
                "uniqueDays": Set(sessions.map { $0.date }).count
            ]
        ]
        if let json = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("arena_data_\(todayString()).json")
            try? json.write(to: url)
            shareItems = [url]
            showShareSheet = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
