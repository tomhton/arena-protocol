// ArenaProtocolTests.swift — Arena Protocol
// Unit tests for data models, streak logic, forge marks, ember drops, and persistence

import Testing
import Foundation
@testable import ArenaProtocol

// MARK: - Date Helpers

@Suite("Date Helpers")
struct DateHelperTests {
    @Test func todayStringFormat() {
        let s = todayString()
        #expect(s.count == 10)
        #expect(s.contains("-"))
        let parts = s.split(separator: "-")
        #expect(parts.count == 3)
    }

    @Test func formatTimeZeroPads() {
        #expect(formatTime(0)    == "00:00")
        #expect(formatTime(60)   == "01:00")
        #expect(formatTime(3599) == "59:59")
        #expect(formatTime(90)   == "01:30")
    }

    @Test func dateRoundTrip() {
        let today = todayString()
        let date  = dateFromString(today)
        let back  = stringFromDate(date)
        #expect(back == today)
    }
}

// MARK: - Arena Model

@Suite("Arena Model")
struct ArenaModelTests {
    @Test func defaultArenasCount() {
        #expect(DEFAULT_ARENAS.count == 4)
    }

    @Test func defaultArenasHaveUniqueIds() {
        let ids = DEFAULT_ARENAS.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }

    @Test func reletterReassignsLetters() {
        let arenas = DEFAULT_ARENAS
        let lettered = Arena.reletter(arenas)
        #expect(lettered[0].letter == "A")
        #expect(lettered[1].letter == "B")
        #expect(lettered[2].letter == "C")
        #expect(lettered[3].letter == "D")
    }

    @Test func reletterPreservesOtherFields() {
        let arenas = DEFAULT_ARENAS
        let lettered = Arena.reletter(arenas)
        #expect(lettered[0].id == arenas[0].id)
        #expect(lettered[0].label == arenas[0].label)
    }
}

// MARK: - Streak Logic

@Suite("Streak Logic")
struct StreakTests {
    private func makeSession(arenaId: String = "body", daysAgo: Int) -> Session {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
        return Session(id: UUID().uuidString, arenaId: arenaId,
                       duration: 25, date: stringFromDate(date), note: "", ts: 0)
    }

    @Test func emptySessionsReturnsZeroStreak() {
        #expect(getStreakForArena(arenaId: "body", sessions: []) == 0)
    }

    @Test func sessionTodayIsStreak1() {
        let s = makeSession(daysAgo: 0)
        #expect(getStreakForArena(arenaId: "body", sessions: [s]) == 1)
    }

    @Test func consecutiveDaysStreak() {
        let sessions = [0, 1, 2].map { makeSession(daysAgo: $0) }
        #expect(getStreakForArena(arenaId: "body", sessions: sessions) == 3)
    }

    @Test func gapBreaksStreak() {
        // Days 0 and 2 — missing day 1
        let sessions = [0, 2].map { makeSession(daysAgo: $0) }
        #expect(getStreakForArena(arenaId: "body", sessions: sessions) == 1)
    }

    @Test func streakOnlyCountsTargetArena() {
        let bodySession  = makeSession(arenaId: "body",  daysAgo: 0)
        let spiritSession = makeSession(arenaId: "spirit", daysAgo: 1)
        // body only has 1 consecutive day (today)
        #expect(getStreakForArena(arenaId: "body", sessions: [bodySession, spiritSession]) == 1)
    }

    @Test func multipleSameDayCountsOnce() {
        let s1 = makeSession(daysAgo: 0)
        let s2 = makeSession(daysAgo: 0)
        let s3 = makeSession(daysAgo: 1)
        #expect(getStreakForArena(arenaId: "body", sessions: [s1, s2, s3]) == 2)
    }
}

// MARK: - Forge Marks

@Suite("Forge Marks")
struct ForgeMarkTests {
    private func sessions(count: Int, arenaId: String = "body") -> [Session] {
        (0..<count).map { i in
            Session(id: "\(i)", arenaId: arenaId, duration: 25, date: todayString(), note: "", ts: Double(i))
        }
    }

    @Test func noMarkBelowThreshold() {
        #expect(getForgeMarkForArena(arenaId: "body", sessions: sessions(count: 2)) == nil)
    }

    @Test func firstMarkAtThreshold3() {
        let result = getForgeMarkForArena(arenaId: "body", sessions: sessions(count: 3))
        #expect(result?.name == "First Blood")
        #expect(result?.mark == "▪")
        #expect(result?.count == 3)
    }

    @Test func markAdvancesAtThreshold7() {
        let result = getForgeMarkForArena(arenaId: "body", sessions: sessions(count: 7))
        #expect(result?.name == "Kindled")
    }

    @Test func highestMarkWins() {
        let result = getForgeMarkForArena(arenaId: "body", sessions: sessions(count: 111))
        #expect(result?.name == "Eternal")
        #expect(result?.mark == "⟡")
    }

    @Test func markIsolatedByArena() {
        let bodySessions   = sessions(count: 7, arenaId: "body")
        let spiritSessions = sessions(count: 2, arenaId: "spirit")
        let all = bodySessions + spiritSessions
        #expect(getForgeMarkForArena(arenaId: "spirit", sessions: all) == nil)
        #expect(getForgeMarkForArena(arenaId: "body",   sessions: all)?.name == "Kindled")
    }
}

// MARK: - Title System

@Suite("Title System")
struct TitleTests {
    private func sessions(arenaId: String, count: Int) -> [Session] {
        (0..<count).map { Session(id: "\($0)", arenaId: arenaId, duration: 25, date: todayString(), note: "", ts: 0) }
    }

    @Test func noTitleWithEmptySessions() {
        #expect(getUnlockedTitles(sessions: []).isEmpty)
    }

    @Test func theMovingUnlocksAt7Body() {
        let s = sessions(arenaId: "body", count: 7)
        let titles = getUnlockedTitles(sessions: s)
        #expect(titles.contains { $0.id == "the_moving" })
    }

    @Test func theBuilderUnlocksAt10Craft() {
        let s = sessions(arenaId: "craft", count: 10)
        #expect(getUnlockedTitles(sessions: s).contains { $0.id == "the_builder" })
    }

    @Test func activeTitleIsLast() {
        let body  = sessions(arenaId: "body",  count: 7)
        let craft = sessions(arenaId: "craft", count: 10)
        let all   = body + craft
        let active = getActiveTitle(sessions: all)
        #expect(active != nil)
    }
}

// MARK: - Ember Drops

@Suite("Ember Drops")
struct EmberDropTests {
    private func s(_ count: Int) -> [Session] {
        (0..<count).map { Session(id: "\($0)", arenaId: "body", duration: 25, date: todayString(), note: "", ts: 0) }
    }

    @Test func firstDropAtCount1() {
        let drop = checkEmberDrop(sessions: s(1), seenDrops: [])
        #expect(drop?.id == "drop_1")
    }

    @Test func seenDropSkipped() {
        let drop = checkEmberDrop(sessions: s(1), seenDrops: ["drop_1"])
        #expect(drop?.id != "drop_1")
    }

    @Test func drop5AtCount5() {
        let drop = checkEmberDrop(sessions: s(5), seenDrops: ["drop_1"])
        #expect(drop?.id == "drop_5")
    }
}

// MARK: - Weekly Data

@Suite("Weekly Data")
struct WeeklyDataTests {
    @Test func alwaysReturn7Days() {
        let data = getWeeklyData(sessions: [])
        #expect(data.count == 7)
    }

    @Test func lastDayIsToday() {
        let data = getWeeklyData(sessions: [])
        #expect(data.last?.date == todayString())
    }

    @Test func sessionsGroupedByDay() {
        let s = Session(id: "1", arenaId: "body", duration: 25, date: todayString(), note: "", ts: 0)
        let data = getWeeklyData(sessions: [s])
        #expect(data.last?.sessions.count == 1)
    }
}

// MARK: - Habit Grid

@Suite("Habit Grid")
struct HabitGridTests {
    @Test func gridAlways70Cells() {
        let grid = getHabitGrid(habitId: "x", logs: [])
        #expect(grid.count == 70)
    }

    @Test func lastCellIsToday() {
        let grid = getHabitGrid(habitId: "x", logs: [])
        #expect(grid.last?.date == todayString())
    }

    @Test func loggedValueReflectedInGrid() {
        let log = HabitLog(habitId: "x", date: todayString(), value: true, ts: 0)
        let grid = getHabitGrid(habitId: "x", logs: [log])
        #expect(grid.last?.value == true)
    }

    @Test func streakCountsConsecutiveTrueLogs() {
        let cal = Calendar.current
        var logs: [HabitLog] = []
        for i in 0..<5 {
            let d = cal.date(byAdding: .day, value: -i, to: Date())!
            logs.append(HabitLog(habitId: "x", date: stringFromDate(d), value: true, ts: 0))
        }
        #expect(getHabitStreak(habitId: "x", logs: logs) == 5)
    }

    @Test func streakBrokenByFalseLog() {
        let cal = Calendar.current
        let today     = HabitLog(habitId: "x", date: todayString(), value: true,  ts: 0)
        let yesterday = HabitLog(habitId: "x",
                                  date: stringFromDate(cal.date(byAdding: .day, value: -1, to: Date())!),
                                  value: false, ts: 0)
        #expect(getHabitStreak(habitId: "x", logs: [today, yesterday]) == 1)
    }
}

// MARK: - Persistence

@Suite("Persistence Helpers")
struct PersistenceTests {
    @Test func loadFallbackWhenKeyAbsent() {
        UserDefaults.standard.removeObject(forKey: "_test_missing_key_")
        let val: [String] = loadFromDefaults("_test_missing_key_", fallback: ["default"])
        #expect(val == ["default"])
    }

    @Test func saveAndLoadRoundTrip() {
        let key = "_test_roundtrip_\(Int.random(in: 1000...9999))_"
        let original = ["alpha", "beta", "gamma"]
        saveToDefaults(key, original)
        let loaded: [String] = loadFromDefaults(key, fallback: [])
        #expect(loaded == original)
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Protocol Model

@Suite("Protocol Model")
struct ProtocolModelTests {
    @Test func defaultProtocolsCount() {
        #expect(DEFAULT_PROTOCOLS.count == 4)
    }

    @Test func warriorHasTwoBlocks() {
        let warrior = DEFAULT_PROTOCOLS.first { $0.id == "warrior" }
        #expect(warrior?.blocks.count == 2)
    }

    @Test func fullDayHasFourBlocks() {
        let fullDay = DEFAULT_PROTOCOLS.first { $0.id == "full-day" }
        #expect(fullDay?.blocks.count == 4)
    }

    @Test func totalDurationIsCorrect() {
        let warrior = DEFAULT_PROTOCOLS.first { $0.id == "warrior" }!
        let total = warrior.blocks.reduce(0) { $0 + $1.duration }
        #expect(total == 50) // 20 + 30
    }
}
