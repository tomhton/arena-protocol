// SessionIntelligence.swift — Arena Protocol
// Zero-API local session pattern analysis.
// Produces a SessionProfile from raw Session + Arena arrays.
// Called on-demand — never stored as persistent state.

import Foundation

// MARK: - UserArchetype

/// Classifies the user's current engagement style based on session history.
enum UserArchetype: String, Equatable, Sendable {
    case newcomer       // < 5 total sessions
    case returning      // back after 7–14 day gap
    case recovering     // back after 15–60 day gap
    case sprinter       // avg duration ≤ 20 min
    case deepWorker     // avg duration ≥ 45 min
    case streakChaser   // global streak ≥ 7 days
    case specialist     // one arena > 70% of sessions (min 20 total)
    case balancer       // all arenas ≥ 15%, min 20 total sessions
    case veteran        // ≥ 100 total sessions
    case surging        // last-7 sessions ≥ 2× prior-7 AND last-7 ≥ 4
}

// MARK: - ArenaTransition

struct ArenaTransition: Equatable, Sendable {
    let from: String   // arenaId
    let to: String     // arenaId
}

// MARK: - SessionProfile

/// A computed snapshot of everything knowable about this user's session patterns.
/// Rebuilt fresh on each call — never cache to disk.
struct SessionProfile: Equatable, Sendable {

    // MARK: Volume
    let totalSessions: Int
    let totalMinutes: Int
    let activeDaysLast30: Int
    let consistencyScore: Double            // 0.0–1.0 (active days / 30)

    // MARK: Recency & Momentum
    let sessionsLast7: Int
    let sessionsPrior7: Int                 // sessions 8–14 days ago
    let weeklyTrend: Double                 // last7 / prior7  (2.0 if prior7==0 and last7>0)
    let isGrowing: Bool                     // trend ≥ 1.5 AND last7 ≥ 3
    let isDeclining: Bool                   // trend ≤ 0.5 AND prior7 ≥ 3
    let daysSinceLastSession: Int           // 0 = today
    let previousSessionGapDays: Int         // gap between last two sessions (for comeback detection)

    // MARK: Duration Patterns
    let averageDuration: Int                // minutes
    let typicalDurationByArena: [String: Int]   // arenaId → median minutes

    // MARK: Time of Day  (hour 0–23 from ts)
    let peakHour: Int
    let morningRatio: Double                // 05–11
    let afternoonRatio: Double              // 12–17
    let eveningRatio: Double                // 18–23 + 00–04

    // MARK: Arena Affinity
    let primaryArenaId: String?
    let arenaSessionCounts: [String: Int]       // arenaId → total session count
    let arenaDistribution: [String: Double]     // arenaId → fraction 0.0–1.0
    let neglectedArenaIds: [String]             // used but <10% + no session in 14 days
    let neverUsedArenaIds: [String]             // 0 sessions ever

    // MARK: Streaks
    let currentGlobalStreak: Int
    let longestGlobalStreak: Int
    let currentArenaStreaks: [String: Int]      // arenaId → streak

    // MARK: Sequences
    let stackingFrequency: Double               // fraction of active days with 2+ arenas
    let commonTransitions: [ArenaTransition]    // top 3 arena-to-arena pairs

    // MARK: Social
    let socialRatio: Double                     // fraction of sessions flagged social

    // MARK: Archetype
    let archetype: UserArchetype
}

// MARK: - Build

func buildSessionProfile(from sessions: [Session], arenas: [Arena]) -> SessionProfile {
    let cal = Calendar.current
    let now = Date()
    let today = todayString()

    // --- Volume ---
    let totalSessions = sessions.count
    let totalMinutes  = sessions.reduce(0) { $0 + $1.duration }

    // --- Active days last 30 ---
    let past30 = stringFromDate(cal.date(byAdding: .day, value: -30, to: now)!)
    let activeDaysLast30  = Set(sessions.filter { $0.date >= past30 }.map { $0.date }).count
    let consistencyScore  = min(1.0, Double(activeDaysLast30) / 30.0)

    // --- Recency / Momentum ---
    let past7  = stringFromDate(cal.date(byAdding: .day, value: -7,  to: now)!)
    let past14 = stringFromDate(cal.date(byAdding: .day, value: -14, to: now)!)

    let sessionsLast7  = sessions.filter { $0.date >= past7 }.count
    let sessionsPrior7 = sessions.filter { $0.date >= past14 && $0.date < past7 }.count

    let weeklyTrend: Double = {
        if sessionsPrior7 > 0 { return Double(sessionsLast7) / Double(sessionsPrior7) }
        return sessionsLast7 > 0 ? 2.0 : 1.0
    }()
    let isGrowing   = weeklyTrend >= 1.5 && sessionsLast7 >= 3
    let isDeclining = weeklyTrend <= 0.5 && sessionsPrior7 >= 3

    let lastDateStr = sessions.map { $0.date }.max()
    let daysSinceLastSession: Int = {
        guard let last = lastDateStr else { return 0 }
        let d = cal.dateComponents([.day], from: dateFromString(last), to: dateFromString(today)).day ?? 0
        return max(0, d)
    }()

    // Gap between two most-recent sessions (comeback detection)
    let sortedByTs = sessions.sorted { $0.ts < $1.ts }
    let previousSessionGapDays: Int = {
        guard sortedByTs.count >= 2 else { return 0 }
        let last = sortedByTs[sortedByTs.count - 1]
        let prev = sortedByTs[sortedByTs.count - 2]
        let d = cal.dateComponents([.day],
                                   from: dateFromString(prev.date),
                                   to: dateFromString(last.date)).day ?? 0
        return max(0, d)
    }()

    // --- Duration patterns ---
    let averageDuration = totalSessions > 0 ? totalMinutes / totalSessions : 0
    var typicalDurationByArena: [String: Int] = [:]
    for arena in arenas {
        let durs = sessions.filter { $0.arenaId == arena.id }.map { $0.duration }.sorted()
        if !durs.isEmpty { typicalDurationByArena[arena.id] = durs[durs.count / 2] }
    }

    // --- Time of day ---
    var hourCounts: [Int: Int] = [:]
    for s in sessions {
        let h = cal.component(.hour, from: Date(timeIntervalSince1970: s.ts / 1000))
        hourCounts[h, default: 0] += 1
    }
    let peakHour = hourCounts.max(by: { $0.value < $1.value })?.key ?? 9
    var morningC = 0, afternoonC = 0, eveningC = 0
    for (h, c) in hourCounts {
        if      h >= 5  && h < 12 { morningC   += c }
        else if h >= 12 && h < 18 { afternoonC += c }
        else                       { eveningC   += c }
    }
    let morningRatio   = totalSessions > 0 ? Double(morningC)   / Double(totalSessions) : 0
    let afternoonRatio = totalSessions > 0 ? Double(afternoonC) / Double(totalSessions) : 0
    let eveningRatio   = totalSessions > 0 ? Double(eveningC)   / Double(totalSessions) : 0

    // --- Arena affinity ---
    var arenaSessionCounts: [String: Int] = [:]
    for s in sessions { arenaSessionCounts[s.arenaId, default: 0] += 1 }

    let primaryArenaId = arenaSessionCounts.max(by: { $0.value < $1.value })?.key

    var arenaDistribution: [String: Double] = [:]
    for (id, count) in arenaSessionCounts {
        arenaDistribution[id] = Double(count) / max(1.0, Double(totalSessions))
    }

    let usedIds = Set(sessions.map { $0.arenaId })
    let neverUsedArenaIds = arenas.filter { !usedIds.contains($0.id) }.map { $0.id }

    let neglectedArenaIds = arenas.compactMap { arena -> String? in
        guard usedIds.contains(arena.id) else { return nil }
        let fraction  = arenaDistribution[arena.id] ?? 0
        let hasRecent = sessions.contains { $0.arenaId == arena.id && $0.date >= past14 }
        return (fraction < 0.10 && !hasRecent) ? arena.id : nil
    }

    // --- Streaks ---
    let currentGlobalStreak = _globalStreak(sessions: sessions, today: today, cal: cal)
    let longestGlobalStreak  = _longestGlobalStreak(sessions: sessions, cal: cal)
    var currentArenaStreaks: [String: Int] = [:]
    for arena in arenas {
        currentArenaStreaks[arena.id] = getStreakForArena(arenaId: arena.id, sessions: sessions)
    }

    // --- Stacking / transitions ---
    let byDate = Dictionary(grouping: sessions) { $0.date }
    var multiArenaDays = 0
    var transCount: [String: Int] = [:]
    for (_, daySessions) in byDate {
        let ids = daySessions.sorted { $0.ts < $1.ts }.map { $0.arenaId }
        if Set(ids).count >= 2 { multiArenaDays += 1 }
        for i in 0..<(ids.count - 1) where ids[i] != ids[i + 1] {
            transCount["\(ids[i])|\(ids[i + 1])", default: 0] += 1
        }
    }
    let stackingFrequency = byDate.isEmpty ? 0.0 : Double(multiArenaDays) / Double(byDate.count)
    let commonTransitions: [ArenaTransition] = transCount
        .sorted { $0.value > $1.value }
        .prefix(3)
        .compactMap { kv in
            let parts = kv.key.components(separatedBy: "|")
            guard parts.count == 2 else { return nil }
            return ArenaTransition(from: parts[0], to: parts[1])
        }

    // --- Social ---
    let socialRatio = totalSessions > 0
        ? Double(sessions.filter { $0.social }.count) / Double(totalSessions) : 0

    // --- Archetype ---
    let archetype = _archetype(
        total: totalSessions,
        avg: averageDuration,
        streak: currentGlobalStreak,
        growing: isGrowing,
        daysSinceLast: daysSinceLastSession,
        previousGap: previousSessionGapDays,
        primaryFraction: primaryArenaId.map { arenaDistribution[$0] ?? 0 } ?? 0,
        dist: arenaDistribution,
        arenas: arenas
    )

    return SessionProfile(
        totalSessions:          totalSessions,
        totalMinutes:           totalMinutes,
        activeDaysLast30:       activeDaysLast30,
        consistencyScore:       consistencyScore,
        sessionsLast7:          sessionsLast7,
        sessionsPrior7:         sessionsPrior7,
        weeklyTrend:            weeklyTrend,
        isGrowing:              isGrowing,
        isDeclining:            isDeclining,
        daysSinceLastSession:   daysSinceLastSession,
        previousSessionGapDays: previousSessionGapDays,
        averageDuration:        averageDuration,
        typicalDurationByArena: typicalDurationByArena,
        peakHour:               peakHour,
        morningRatio:           morningRatio,
        afternoonRatio:         afternoonRatio,
        eveningRatio:           eveningRatio,
        primaryArenaId:         primaryArenaId,
        arenaSessionCounts:     arenaSessionCounts,
        arenaDistribution:      arenaDistribution,
        neglectedArenaIds:      neglectedArenaIds,
        neverUsedArenaIds:      neverUsedArenaIds,
        currentGlobalStreak:    currentGlobalStreak,
        longestGlobalStreak:    longestGlobalStreak,
        currentArenaStreaks:    currentArenaStreaks,
        stackingFrequency:      stackingFrequency,
        commonTransitions:      commonTransitions,
        socialRatio:            socialRatio,
        archetype:              archetype
    )
}

// MARK: - Private helpers

private func _globalStreak(sessions: [Session], today: String, cal: Calendar) -> Int {
    let dates = Set(sessions.map { $0.date })
    guard !dates.isEmpty else { return 0 }
    var cursor = dateFromString(today)
    // If no session today, start counting from yesterday
    if !dates.contains(today) {
        cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        guard dates.contains(stringFromDate(cursor)) else { return 0 }
    }
    var streak = 0
    while dates.contains(stringFromDate(cursor)) {
        streak += 1
        cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
    }
    return streak
}

private func _longestGlobalStreak(sessions: [Session], cal: Calendar) -> Int {
    let dates = Array(Set(sessions.map { $0.date })).sorted()
    guard !dates.isEmpty else { return 0 }
    var longest = 1
    var current = 1
    for i in 1..<dates.count {
        let prev = dateFromString(dates[i - 1])
        let curr = dateFromString(dates[i])
        let diff = cal.dateComponents([.day], from: prev, to: curr).day ?? 0
        if diff == 1 {
            current += 1
            longest = max(longest, current)
        } else {
            current = 1
        }
    }
    return longest
}

private func _archetype(
    total: Int, avg: Int, streak: Int,
    growing: Bool, daysSinceLast: Int, previousGap: Int,
    primaryFraction: Double, dist: [String: Double], arenas: [Arena]
) -> UserArchetype {
    if total < 5                               { return .newcomer }
    if total >= 100                            { return .veteran }
    if previousGap >= 15 && previousGap <= 60 { return .recovering }
    if previousGap >= 7                        { return .returning }
    if growing                                 { return .surging }
    if streak >= 7                             { return .streakChaser }
    if total >= 20 && primaryFraction >= 0.70  { return .specialist }
    if total >= 20 {
        let allBalanced = arenas.allSatisfy { (dist[$0.id] ?? 0) >= 0.15 }
        if allBalanced { return .balancer }
    }
    return avg >= 45 ? .deepWorker : .sprinter
}
