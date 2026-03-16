// DataStore.swift — Arena Protocol
// All models, defaults, and persistence layer
// iOS 26 / Swift 6 compatible using @Observable + UserDefaults

import Foundation
import Observation
@preconcurrency import UserNotifications

// MARK: - Models

struct Arena: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var label: String
    var letter: String
    var color: String          // hex string
    var subtitle: String
    var description: String
    var icon: String
    var examples: [String]
    var subArenas: [String: [String]]

    static func reletter(_ arenas: [Arena]) -> [Arena] {
        arenas.enumerated().map { i, a in
            var updated = a
            updated.letter = String(UnicodeScalar(65 + i)!)
            return updated
        }
    }
}

struct Session: Identifiable, Codable {
    var id: String = UUID().uuidString
    var arenaId: String
    var duration: Int          // minutes
    var date: String           // yyyy-MM-dd
    var note: String
    var ts: Double             // epoch ms
}

struct ArenaProtocolModel: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var glyph: String
    var color: String
    var description: String
    var blocks: [ProtocolBlock]
}

struct ProtocolBlock: Codable, Hashable {
    var arenaId: String
    var label: String
    var duration: Int
    var color: String
}

struct Habit: Identifiable, Codable {
    var id: String
    var name: String
    var goal: String
    var color: String
    var createdAt: String
}

struct HabitLog: Codable {
    var habitId: String
    var date: String
    var value: Bool
    var ts: Double
}

struct JournalEntry: Codable {
    var date: String
    var text: String
    var ts: Double
}

struct IdeaNote: Identifiable, Codable {
    var id: Double
    var text: String
    var ts: String
}

struct AppSettings: Codable {
    var windDownTime: String = "21:30"
}

struct MorningCheckin: Codable {
    var date: String
    var completed: [String]
}

// MARK: - Static Defaults

let DEFAULT_ARENAS: [Arena] = [
    Arena(
        id: "body", label: "BODY", letter: "A", color: "#C0392B",
        subtitle: "move · fuel · rest",
        description: "The instrument. Without it, nothing else functions. Move it, fuel it, rest it.",
        icon: "◉",
        examples: ["10 min walk", "20 pushups", "Cold shower", "Cook a real meal",
                   "Sleep before midnight", "5 min breathwork", "Stretch for 10 min", "Drink 2L of water"],
        subArenas: [
            "MOVE": ["10 min walk", "20 pushups", "Cold shower", "Stretch for 10 min"],
            "FUEL": ["Cook a real meal", "Drink 2L of water", "Prep meals for tomorrow", "No sugar today"],
            "REST": ["Sleep before midnight", "5 min breathwork", "20 min nap", "Legs up the wall 10 min"]
        ]
    ),
    Arena(
        id: "spirit", label: "SPIRIT", letter: "B", color: "#D4A017",
        subtitle: "reflect · read · meditate",
        description: "The inner fire. Who you are beneath the noise. Purpose, identity, the story you tell yourself.",
        icon: "★",
        examples: ["Write 3 things you're grateful for", "Journal one page", "Read 10 pages",
                   "Meditate 10 min", "Define today's one intention", "Review your goals",
                   "Visualize your future self", "Name one lie depression told you today"],
        subArenas: [
            "REFLECT": ["Write 3 things you're grateful for", "Journal one page",
                        "Define today's one intention", "Name one lie depression told you today"],
            "READ": ["Read 10 pages", "Review your goals",
                     "Read one article that challenges you", "Reread a passage that matters"],
            "MEDITATE": ["Meditate 10 min", "Visualize your future self",
                         "4-7-8 breathing for 5 min", "Sit in silence for 5 min"]
        ]
    ),
    Arena(
        id: "tribe", label: "TRIBE", letter: "C", color: "#B87333",
        subtitle: "reach out · show up · plan",
        description: "The hearth. You exist because of others. Show up for them — and let them show up for you.",
        icon: "◇",
        examples: ["Send one meaningful text", "Call someone you've been avoiding",
                   "Plan something with a friend", "Reply to a message you've been ignoring",
                   "Tell someone you appreciate them", "Check in on family", "Accept an invitation"],
        subArenas: [
            "REACH OUT": ["Send one meaningful text", "Call someone you've been avoiding",
                          "Tell someone you appreciate them", "Reply to a message you've been ignoring"],
            "SHOW UP": ["Check in on family", "Accept an invitation",
                        "Be present — no phone for one hour", "Do something kind without being asked"],
            "PLAN": ["Plan something with a friend", "Schedule a catch-up call",
                     "Suggest a date or activity", "Book something you'll look forward to"]
        ]
    ),
    Arena(
        id: "craft", label: "CRAFT", letter: "D", color: "#708090",
        subtitle: "deep work · admin · build",
        description: "The work. What you are building in the world — your output, your mastery, your mark.",
        icon: "△",
        examples: ["Send one important email", "Complete one work task",
                   "Work on a side project for 25 min", "Research one lead",
                   "Write 200 words", "Outline one idea", "Do one thing you've been avoiding"],
        subArenas: [
            "DEEP WORK": ["Work on a side project for 25 min", "Write 200 words",
                          "Outline one idea", "Build one thing, start to finish"],
            "ADMIN": ["Send one important email", "Update one key metric",
                      "Clear your inbox", "Do one thing you've been avoiding"],
            "BUILD": ["Research one lead", "Sketch a system or process",
                      "Define the next milestone", "Learn one thing relevant to your craft"]
        ]
    )
]

let DEFAULT_PROTOCOLS: [ArenaProtocolModel] = [
    ArenaProtocolModel(
        id: "warrior", name: "THE WARRIOR", glyph: "⚔", color: "#C0392B",
        description: "Body first. Then the work. No excuses.",
        blocks: [
            ProtocolBlock(arenaId: "body",  label: "BODY",  duration: 20, color: "#C0392B"),
            ProtocolBlock(arenaId: "craft", label: "CRAFT", duration: 25, color: "#708090")
        ]
    ),
    ArenaProtocolModel(
        id: "monk", name: "THE MONK", glyph: "☽", color: "#D4A017",
        description: "Silence and study. Turn inward, then outward.",
        blocks: [
            ProtocolBlock(arenaId: "spirit", label: "SPIRIT", duration: 15, color: "#D4A017"),
            ProtocolBlock(arenaId: "tribe",  label: "TRIBE",  duration: 10, color: "#B87333")
        ]
    ),
    ArenaProtocolModel(
        id: "builder", name: "THE BUILDER", glyph: "◈", color: "#708090",
        description: "Pure output. Build something that lasts.",
        blocks: [
            ProtocolBlock(arenaId: "craft", label: "CRAFT", duration: 25, color: "#708090"),
            ProtocolBlock(arenaId: "craft", label: "CRAFT", duration: 25, color: "#708090")
        ]
    ),
    ArenaProtocolModel(
        id: "ember", name: "THE EMBER", glyph: "◉", color: "#B87333",
        description: "A gentle day. Move, connect, rest.",
        blocks: [
            ProtocolBlock(arenaId: "body",   label: "BODY",   duration: 10, color: "#C0392B"),
            ProtocolBlock(arenaId: "tribe",  label: "TRIBE",  duration: 10, color: "#B87333"),
            ProtocolBlock(arenaId: "spirit", label: "SPIRIT", duration: 10, color: "#D4A017")
        ]
    )
]

let MORNING_HABITS_STATIC: [(id: String, label: String, duration: String, description: String, color: String)] = [
    ("reading",  "READING",       "5 MIN", "Something positive. Feed your mind before the world does.",                        "#E8C547"),
    ("goals",    "GOAL PLANNING", "5 MIN", "Set your intentions. What are the three arenas you're entering today?",            "#4ECDC4"),
    ("movement", "MOVEMENT",      "5 MIN", "Get moving. Signal to your body that today has already begun.",                    "#A8E6A3")
]

let STUCK_PROMPTS = [
    "You've been circling. Pick one arena. Enter it.",
    "Momentum is a choice. What's the smallest move?",
    "Stuck means your brain needs a container. Give it one.",
    "The resistance you feel? That's the arena calling.",
    "Don't optimize. Don't plan. Just start.",
    "One minute of action beats an hour of intention.",
    "Your future self already made the decision. Catch up.",
    "The timer ends. You move. No negotiation."
]

let ARENA_ICONS = ["◈", "◎", "⬡", "◇", "△", "○", "◉", "◆", "▲", "★", "⬟", "⬠", "⊕", "⊗", "⊘", "❋", "✦", "⟡"]
let ARENA_COLORS = ["#E8C547", "#4ECDC4", "#A8E6A3", "#FF8FA3", "#B794F4", "#F4A261",
                    "#60A5FA", "#F87171", "#34D399", "#A78BFA", "#FB923C", "#38BDF8",
                    "#E879F9", "#4ADE80"]
let DURATIONS = [5, 10, 30, 60, 90]

// MARK: - Forge / Reward

let FORGE_MILESTONES = [3, 7, 13, 21, 33, 50, 77, 111]
let FORGE_MARKS = ["▪", "▸", "◆", "★", "⬟", "✦", "❋", "⟡"]
let FORGE_MARK_NAMES = ["First Blood", "Kindled", "Forged", "Tempered", "Hardened", "Undying", "Mythic", "Eternal"]

struct ForgeMark {
    let mark: String
    let name: String
    let count: Int
}

func getForgeMarkForArena(arenaId: String, sessions: [Session]) -> ForgeMark? {
    let count = sessions.filter { $0.arenaId == arenaId }.count
    for i in stride(from: FORGE_MILESTONES.count - 1, through: 0, by: -1) {
        if count >= FORGE_MILESTONES[i] {
            return ForgeMark(mark: FORGE_MARKS[i], name: FORGE_MARK_NAMES[i], count: count)
        }
    }
    return nil
}

struct Title: Sendable {
    let id: String
    let label: String
    let arenaId: String?
    let condition: @Sendable ([Session]) -> Bool
}

let TITLES: [Title] = [
    Title(id: "the_moving",   label: "THE MOVING",   arenaId: "body",   condition: { $0.filter { $0.arenaId == "body"   }.count >= 7  }),
    Title(id: "the_burning",  label: "THE BURNING",  arenaId: "body",   condition: { $0.filter { $0.arenaId == "body"   }.count >= 20 }),
    Title(id: "the_witness",  label: "THE WITNESS",  arenaId: "tribe",  condition: { $0.filter { $0.arenaId == "tribe"  }.count >= 5  }),
    Title(id: "the_builder",  label: "THE BUILDER",  arenaId: "craft",  condition: { $0.filter { $0.arenaId == "craft"  }.count >= 10 }),
    Title(id: "the_seeker",   label: "THE SEEKER",   arenaId: "spirit", condition: { $0.filter { $0.arenaId == "spirit" }.count >= 7  }),
    Title(id: "the_returned", label: "THE RETURNED", arenaId: nil,      condition: { Set($0.map { $0.date }).count >= 3 }),
    Title(id: "the_forge",    label: "THE FORGE",    arenaId: nil,      condition: { Set($0.map { $0.arenaId }).count >= 4 }),
    Title(id: "the_unbroken", label: "THE UNBROKEN", arenaId: nil,      condition: { sessions in
        let dates = Set(sessions.map { $0.date })
        var streak = 0
        var check = todayString()
        let cal = Calendar.current
        for _ in 0..<365 {
            if dates.contains(check) {
                streak += 1
                let d = cal.date(byAdding: .day, value: -1, to: dateFromString(check))!
                check = stringFromDate(d)
            } else { break }
        }
        return streak >= 7
    })
]

struct EmberDrop: Identifiable, Sendable {
    let id: String
    let message: String
    let glyph: String
    let trigger: @Sendable ([Session]) -> Bool
}

let EMBER_DROPS: [EmberDrop] = [
    EmberDrop(id: "drop_1",     message: "The first step is always the hardest. You took it.",            glyph: "▸", trigger: { $0.count >= 1  }),
    EmberDrop(id: "drop_5",     message: "Five sessions. The forge is warming.",                          glyph: "◆", trigger: { $0.count >= 5  }),
    EmberDrop(id: "drop_13",    message: "Thirteen. An odd number. That's the point. Keep going.",        glyph: "★", trigger: { $0.count >= 13 }),
    EmberDrop(id: "drop_3arena",message: "Three arenas in one day. You showed up everywhere.",             glyph: "✦", trigger: { sessions in
        let today = todayString()
        return Set(sessions.filter { $0.date == today }.map { $0.arenaId }).count >= 3
    }),
    EmberDrop(id: "drop_week",  message: "Seven consecutive days. Depression told you this was impossible.", glyph: "⬟", trigger: { sessions in
        let dates = Set(sessions.map { $0.date })
        let cal = Calendar.current
        for i in 0..<7 {
            let d = cal.date(byAdding: .day, value: -i, to: Date())!
            if !dates.contains(stringFromDate(d)) { return false }
        }
        return true
    })
]

func getUnlockedTitles(sessions: [Session]) -> [Title] {
    TITLES.filter { $0.condition(sessions) }
}

func getActiveTitle(sessions: [Session]) -> Title? {
    getUnlockedTitles(sessions: sessions).last
}

func checkEmberDrop(sessions: [Session], seenDrops: [String]) -> EmberDrop? {
    EMBER_DROPS.first { !seenDrops.contains($0.id) && $0.trigger(sessions) }
}

// MARK: - Date Helpers

func todayString() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: Date())
}

func dateFromString(_ s: String) -> Date {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.date(from: s) ?? Date()
}

func stringFromDate(_ d: Date) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: d)
}

func formatTime(_ seconds: Int) -> String {
    String(format: "%02d:%02d", seconds / 60, seconds % 60)
}

func uid() -> String { UUID().uuidString.lowercased().prefix(7).map { String($0) }.joined() }

// MARK: - Streak / Stats

func getStreakForArena(arenaId: String, sessions: [Session]) -> Int {
    let dates = Array(Set(sessions.filter { $0.arenaId == arenaId }.map { $0.date })).sorted(by: >)
    guard !dates.isEmpty else { return 0 }
    var streak = 0
    var check = todayString()
    let cal = Calendar.current
    for d in dates {
        if d == check {
            streak += 1
            let next = cal.date(byAdding: .day, value: -1, to: dateFromString(check))!
            check = stringFromDate(next)
        } else { break }
    }
    return streak
}

struct WeekDay {
    let date: String
    let label: String
    let sessions: [Session]
    let arenas: [String]
}

func getWeeklyData(sessions: [Session]) -> [WeekDay] {
    let cal = Calendar.current
    let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
    let labelFmt = DateFormatter(); labelFmt.dateFormat = "EEE"
    return (0..<7).reversed().map { i in
        let d = cal.date(byAdding: .day, value: -i, to: Date())!
        let ds = fmt.string(from: d)
        let daySessions = sessions.filter { $0.date == ds }
        return WeekDay(date: ds, label: labelFmt.string(from: d),
                       sessions: daySessions,
                       arenas: Array(Set(daySessions.map { $0.arenaId })))
    }
}

struct HabitCell {
    let date: String
    let value: Bool?
}

func getHabitGrid(habitId: String, logs: [HabitLog]) -> [HabitCell] {
    let cal = Calendar.current
    let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
    return (0..<70).reversed().map { i in
        let d = cal.date(byAdding: .day, value: -i, to: Date())!
        let ds = fmt.string(from: d)
        let log = logs.first { $0.habitId == habitId && $0.date == ds }
        return HabitCell(date: ds, value: log?.value)
    }
}

func getHabitStreak(habitId: String, logs: [HabitLog]) -> Int {
    var streak = 0
    var check = todayString()
    let cal = Calendar.current
    for _ in 0..<365 {
        if let log = logs.first(where: { $0.habitId == habitId && $0.date == check }), log.value {
            streak += 1
            let d = cal.date(byAdding: .day, value: -1, to: dateFromString(check))!
            check = stringFromDate(d)
        } else { break }
    }
    return streak
}

// MARK: - Persistence

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()

func loadFromDefaults<T: Decodable>(_ key: String, fallback: T) -> T {
    guard let data = UserDefaults.standard.data(forKey: key),
          let val = try? decoder.decode(T.self, from: data) else { return fallback }
    return val
}

func saveToDefaults<T: Encodable>(_ key: String, _ value: T) {
    if let data = try? encoder.encode(value) {
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - DataStore (@Observable)

@Observable
final class DataStore {

    // State
    var arenas:     [Arena]              = loadFromDefaults("arena_custom_arenas",   fallback: DEFAULT_ARENAS)
    var sessions:   [Session]            = loadFromDefaults("arena_sessions",        fallback: [])
    var habits:     [Habit]              = loadFromDefaults("arena_habits",          fallback: [])
    var habitLogs:  [HabitLog]           = loadFromDefaults("arena_habit_logs",      fallback: [])
    var journals:   [JournalEntry]       = loadFromDefaults("arena_journals",        fallback: [])
    var ideas:      [IdeaNote]           = loadFromDefaults("arena_ideas",           fallback: [])
    var settings:   AppSettings          = loadFromDefaults("arena_settings",        fallback: AppSettings())
    var protocols:  [ArenaProtocolModel] = loadFromDefaults("arena_protocols",       fallback: DEFAULT_PROTOCOLS)
    var seenDrops:  [String]             = loadFromDefaults("arena_seen_drops",      fallback: [])
    var checkin:    MorningCheckin       = {
        let saved: MorningCheckin = loadFromDefaults("arena_checkin", fallback: MorningCheckin(date: "", completed: []))
        return saved.date == todayString() ? saved : MorningCheckin(date: todayString(), completed: [])
    }()

    var letteredArenas: [Arena] { Arena.reletter(arenas) }
    var todaySessions:  Int    { sessions.filter { $0.date == todayString() }.count }

    // Save helpers
    func saveArenas()    { saveToDefaults("arena_custom_arenas",  arenas) }
    func saveSessions()  { saveToDefaults("arena_sessions",       sessions) }
    func saveHabits()    { saveToDefaults("arena_habits",         habits) }
    func saveHabitLogs() { saveToDefaults("arena_habit_logs",     habitLogs) }
    func saveJournals()  { saveToDefaults("arena_journals",       journals) }
    func saveIdeas()     { saveToDefaults("arena_ideas",          ideas) }
    func saveSettings()  { saveToDefaults("arena_settings",       settings) }
    func saveProtocols() { saveToDefaults("arena_protocols",      protocols) }
    func saveSeenDrops() { saveToDefaults("arena_seen_drops",     seenDrops) }
    func saveCheckin()   { saveToDefaults("arena_checkin",        checkin) }

    // Session management
    func addSession(_ s: Session) {
        sessions.append(s)
        saveSessions()
    }

    // Streak & forge
    func streak(for arenaId: String) -> Int { getStreakForArena(arenaId: arenaId, sessions: sessions) }
    func forgeMark(for arenaId: String) -> ForgeMark? { getForgeMarkForArena(arenaId: arenaId, sessions: sessions) }

    // Ember drop
    func checkAndClaimEmberDrop() -> EmberDrop? {
        guard let drop = checkEmberDrop(sessions: sessions, seenDrops: seenDrops) else { return nil }
        seenDrops.append(drop.id)
        saveSeenDrops()
        return drop
    }

    // Export CSV
    func exportCSV() -> String {
        var rows = [["Date", "Arena", "Duration (min)", "Quest", "Timestamp"]]
        for s in sessions {
            let arena = letteredArenas.first { $0.id == s.arenaId }
            rows.append([s.date, arena?.label ?? s.arenaId, String(s.duration), s.note,
                         ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: s.ts / 1000))])
        }
        return rows.map { $0.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ",") }.joined(separator: "\n")
    }
}

// MARK: - Notifications

func scheduleNotification(id: String, title: String, body: String, secondsFromNow: TimeInterval) {
    guard secondsFromNow > 0 else { return }
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
        guard granted else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsFromNow, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.removeDeliveredNotifications(withIdentifiers: [id])
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.add(request)
    }
}

func cancelNotification(id: String) {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [id])
    center.removeDeliveredNotifications(withIdentifiers: [id])
}
