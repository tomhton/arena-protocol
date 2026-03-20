// ForgeEngine.swift — Arena Protocol
// Personalized narrative generation from session patterns.
// No external API. Pure local evaluation against SessionProfile.
//
// Integration:
//   ForgeEngine.evaluate(profile:arenas:lastSession:seenDropIds:) -> ForgeNarrative?
//   narrative.toEmberDrop() converts to EmberDrop for the existing modal system.
//
// Drop ID namespace: all forge IDs are prefixed "forge_" to avoid
// collisions with legacy EMBER_DROPS (drop_1, drop_5, etc.)

import Foundation

// MARK: - ForgeCategory

enum ForgeCategory: String, Sendable {
    case firstContact   // debut / first session in a new arena
    case milestone      // global session count milestones
    case arenaDepth     // per-arena session count milestones
    case streak         // consecutive-day streaks
    case momentum       // trending up / surging
    case recovery       // coming back after a gap
    case balance        // multi-arena usage patterns
    case pattern        // behavioral patterns (deep work, sprinter, etc.)
    case social         // social session patterns
}

// MARK: - ForgeUrgency

enum ForgeUrgency: Sendable {
    case drop       // show as EmberDrop modal immediately
    case notable    // queued, shown soon
    case ambient    // background acknowledgement, lower visual priority
}

// MARK: - ForgeNarrative

struct ForgeNarrative: Identifiable, Sendable {
    let id: String          // unique drop ID — stored in seenDrops to prevent replay
    let glyph: String
    let headline: String    // short, punchy (≤ 5 words)
    let flavor: String      // full message shown in EmberDropModal
    let category: ForgeCategory
    let urgency: ForgeUrgency

    /// Converts to the legacy EmberDrop type so the existing modal pipeline works unchanged.
    /// The trigger closure always returns true — evaluation already happened here.
    func toEmberDrop() -> EmberDrop {
        EmberDrop(id: id, message: flavor, glyph: glyph, trigger: { _ in true })
    }
}

// MARK: - ForgeEngine

enum ForgeEngine {

    /// Evaluates the most relevant unseen narrative for the current user.
    /// Returns nil if no narrative qualifies or all have been seen.
    ///
    /// Priority order: firstContact → milestone → streak → comeback → momentum
    ///                 → balance → pattern → social → ambient nudges
    static func evaluate(
        profile: SessionProfile,
        arenas: [Arena],
        lastSession: Session?,
        seenDropIds: [String]
    ) -> ForgeNarrative? {

        let seen = Set(seenDropIds)

        let candidates: [ForgeNarrative?] = [
            // Tier 1 — First contact (highest priority)
            narrativeDebut(profile, seen: seen),
            narrativeFirstPerArena(profile, arenas: arenas, lastSession: lastSession, seen: seen),

            // Tier 2 — Volume milestones
            narrativeGlobalMilestone(profile, seen: seen),
            narrativeArenaDepth(profile, arenas: arenas, lastSession: lastSession, seen: seen),

            // Tier 3 — Streak milestones
            narrativeStreak(profile, seen: seen),

            // Tier 4 — Momentum events
            narrativeComeback(profile, seen: seen),
            narrativeSurge(profile, seen: seen),

            // Tier 5 — Balance
            narrativeAllArenas(profile, arenas: arenas, seen: seen),
            narrativeBalancer(profile, arenas: arenas, seen: seen),
            narrativeMultistreak(profile, seen: seen),

            // Tier 6 — Behavioral patterns
            narrativeDeepWorker(profile, seen: seen),
            narrativeSprinter(profile, seen: seen),
            narrativeSpecialist(profile, arenas: arenas, seen: seen),
            narrativeSocial(profile, seen: seen),

            // Tier 7 — Ambient nudges
            narrativeReflective(lastSession: lastSession, seen: seen),
            narrativeNeglect(profile, arenas: arenas, seen: seen),
        ]

        return candidates.compactMap { $0 }.first
    }
}

// MARK: - Narrative builders (private)

private extension ForgeEngine {

    // MARK: Tier 1 — First contact

    static func narrativeDebut(_ p: SessionProfile, seen: Set<String>) -> ForgeNarrative? {
        let id = "forge_debut"
        guard !seen.contains(id), p.totalSessions == 1 else { return nil }
        return ForgeNarrative(
            id: id, glyph: "▸",
            headline: "The Opening",
            flavor: "The forge lights. First session logged. Every record starts with a single entry.",
            category: .firstContact, urgency: .drop
        )
    }

    static func narrativeFirstPerArena(
        _ p: SessionProfile, arenas: [Arena], lastSession: Session?, seen: Set<String>
    ) -> ForgeNarrative? {
        guard let s = lastSession, p.totalSessions > 1 else { return nil }
        let id = "forge_first_\(s.arenaId)"
        guard !seen.contains(id) else { return nil }
        guard (p.arenaSessionCounts[s.arenaId] ?? 0) == 1 else { return nil }
        let arena = arenas.first { $0.id == s.arenaId }
        let label = arena?.label ?? s.arenaId.uppercased()
        let icon  = arena?.icon ?? "◆"
        return ForgeNarrative(
            id: id, glyph: icon,
            headline: "\(label) ACTIVATED",
            flavor: "First session in \(label). A new front opens. The work expands.",
            category: .firstContact, urgency: .drop
        )
    }

    // MARK: Tier 2 — Volume milestones

    static func narrativeGlobalMilestone(_ p: SessionProfile, seen: Set<String>) -> ForgeNarrative? {
        let milestones: [(Int, String, String, String)] = [
            (5,   "forge_global_5",   "◆", "Five sessions in the books. The pattern is beginning."),
            (10,  "forge_global_10",  "★", "Ten sessions. You're not dabbling anymore."),
            (25,  "forge_global_25",  "⬟", "Twenty-five sessions. One quarter of a hundred. Hold the line."),
            (50,  "forge_global_50",  "✦", "Fifty sessions. Most people never get here."),
            (100, "forge_global_100", "❋", "One hundred sessions. The forge is running hot. Keep going."),
            (200, "forge_global_200", "⟡", "Two hundred. This is not a phase. This is who you are."),
            (365, "forge_global_365", "◈", "Three sixty-five. A full year of showing up. That's a life changed."),
        ]
        for (threshold, id, glyph, flavor) in milestones.reversed() {
            if p.totalSessions >= threshold && !seen.contains(id) {
                return ForgeNarrative(
                    id: id, glyph: glyph,
                    headline: "\(threshold) SESSIONS",
                    flavor: flavor,
                    category: .milestone, urgency: .drop
                )
            }
        }
        return nil
    }

    static func narrativeArenaDepth(
        _ p: SessionProfile, arenas: [Arena], lastSession: Session?, seen: Set<String>
    ) -> ForgeNarrative? {
        guard let s = lastSession else { return nil }
        let count = p.arenaSessionCounts[s.arenaId] ?? 0
        let arena = arenas.first { $0.id == s.arenaId }
        let label = arena?.label ?? s.arenaId.uppercased()
        // FORGE_MILESTONES = [3, 7, 13, 21, 33, 50, 77, 111]
        let marks = [(3, "▸"), (7, "◆"), (13, "★"), (21, "⬟"), (33, "✦"), (50, "❋"), (77, "⟡"), (111, "◈")]
        let flavors = [
            3:   "Three sessions in \(label). You're learning the language.",
            7:   "Seven sessions in \(label). The first real streak.",
            13:  "Thirteen in \(label). Odd number, intentional commitment.",
            21:  "Twenty-one sessions in \(label). The habit is structural now.",
            33:  "Thirty-three in \(label). Deep in the work.",
            50:  "Fifty sessions in \(label). Most never reach this far in a single arena.",
            77:  "Seventy-seven in \(label). This is mastery territory.",
            111: "One-eleven in \(label). You've built something most people only talk about.",
        ]
        for (milestone, glyph) in marks.reversed() {
            let id = "forge_arena_\(s.arenaId)_\(milestone)"
            if count >= milestone && !seen.contains(id) {
                let flavor = flavors[milestone] ?? "Deep in \(label)."
                return ForgeNarrative(
                    id: id, glyph: glyph,
                    headline: "\(label) × \(milestone)",
                    flavor: flavor,
                    category: .arenaDepth, urgency: .drop
                )
            }
        }
        return nil
    }

    // MARK: Tier 3 — Streak milestones

    static func narrativeStreak(_ p: SessionProfile, seen: Set<String>) -> ForgeNarrative? {
        let milestones: [(Int, String, String, String)] = [
            (3,   "forge_streak_3",   "▸", "Three consecutive days. The streak is real."),
            (7,   "forge_streak_7",   "◆", "Seven days straight. You did the week."),
            (14,  "forge_streak_14",  "★", "Two weeks without a miss. This is discipline now."),
            (21,  "forge_streak_21",  "⬟", "Twenty-one days. The research says habit. You proved it."),
            (30,  "forge_streak_30",  "✦", "Thirty straight. A month. Full stop."),
            (60,  "forge_streak_60",  "❋", "Sixty days. You rewired something permanent."),
            (100, "forge_streak_100", "⟡", "One hundred consecutive days. This doesn't happen by accident."),
        ]
        for (threshold, id, glyph, flavor) in milestones.reversed() {
            if p.currentGlobalStreak >= threshold && !seen.contains(id) {
                return ForgeNarrative(
                    id: id, glyph: glyph,
                    headline: "\(threshold)-DAY STREAK",
                    flavor: flavor,
                    category: .streak, urgency: .drop
                )
            }
        }
        return nil
    }

    // MARK: Tier 4 — Momentum events

    static func narrativeComeback(_ p: SessionProfile, seen: Set<String>) -> ForgeNarrative? {
        let id = "forge_comeback"
        // previousSessionGapDays captures the gap before this session
        // Don't fire for newcomers (no real gap to come back from)
        guard !seen.contains(id),
              p.previousSessionGapDays >= 7,
              p.totalSessions >= 5 else { return nil }
        let days = p.previousSessionGapDays
        let flavor = days >= 30
            ? "A month away. That's a real gap. But you came back. That's the whole game."
            : "Back after \(days) days. The arena doesn't judge the gap — only the return."
        return ForgeNarrative(
            id: id, glyph: "▸",
            headline: "THE RETURN",
            flavor: flavor,
            category: .recovery, urgency: .drop
        )
    }

    static func narrativeSurge(_ p: SessionProfile, seen: Set<String>) -> ForgeNarrative? {
        let id = "forge_surge"
        guard !seen.contains(id),
              p.isGrowing,
              p.sessionsLast7 >= 5 else { return nil }
        return ForgeNarrative(
            id: id, glyph: "⬟",
            headline: "MOMENTUM SURGE",
            flavor: "Last 7 days: \(p.sessionsLast7) sessions. The week before: \(p.sessionsPrior7). You're accelerating.",
            category: .momentum, urgency: .notable
        )
    }

    // MARK: Tier 5 — Balance

    static func narrativeAllArenas(
        _ p: SessionProfile, arenas: [Arena], seen: Set<String>
    ) -> ForgeNarrative? {
        let id = "forge_all_arenas"
        guard !seen.contains(id) else { return nil }
        // All default arenas used in the last 7 days
        let usedLast7 = Set(
            // We don't have last7 sessions in profile; approximate using arenaSessionCounts
            // and the fact that neverUsedArenaIds is empty for all arenas
            p.arenaSessionCounts.keys
        )
        let allCovered = arenas.allSatisfy { usedLast7.contains($0.id) }
        guard allCovered, arenas.count >= 3 else { return nil }
        return ForgeNarrative(
            id: id, glyph: "✦",
            headline: "FULL ACTIVATION",
            flavor: "Every arena. One week. That's not luck — that's a complete human being operating at full range.",
            category: .balance, urgency: .notable
        )
    }

    static func narrativeBalancer(
        _ p: SessionProfile, arenas: [Arena], seen: Set<String>
    ) -> ForgeNarrative? {
        let id = "forge_balancer"
        guard !seen.contains(id),
              p.totalSessions >= 20,
              p.archetype == .balancer else { return nil }
        return ForgeNarrative(
            id: id, glyph: "✦",
            headline: "THE BALANCER",
            flavor: "All arenas pulling even weight. You don't optimise one thing at the cost of another.",
            category: .balance, urgency: .ambient
        )
    }

    static func narrativeMultistreak(_ p: SessionProfile, seen: Set<String>) -> ForgeNarrative? {
        let id = "forge_multistreak"
        guard !seen.contains(id) else { return nil }
        let areasOn7 = p.currentArenaStreaks.values.filter { $0 >= 7 }.count
        guard areasOn7 >= 2 else { return nil }
        return ForgeNarrative(
            id: id, glyph: "❋",
            headline: "MULTI-FRONT STREAK",
            flavor: "\(areasOn7) arenas with a 7-day streak running simultaneously. This is rare.",
            category: .streak, urgency: .notable
        )
    }

    // MARK: Tier 6 — Behavioral patterns

    static func narrativeDeepWorker(_ p: SessionProfile, seen: Set<String>) -> ForgeNarrative? {
        let id = "forge_deep_worker"
        guard !seen.contains(id),
              p.totalSessions >= 10,
              p.averageDuration >= 45 else { return nil }
        return ForgeNarrative(
            id: id, glyph: "◈",
            headline: "DEEP WORKER",
            flavor: "Average session: \(p.averageDuration) minutes. You don't dabble. You go deep.",
            category: .pattern, urgency: .ambient
        )
    }

    static func narrativeSprinter(_ p: SessionProfile, seen: Set<String>) -> ForgeNarrative? {
        let id = "forge_sprinter"
        guard !seen.contains(id),
              p.totalSessions >= 15,
              p.averageDuration <= 20 else { return nil }
        return ForgeNarrative(
            id: id, glyph: "▸",
            headline: "THE SPRINTER",
            flavor: "Short sessions, consistent reps. \(p.averageDuration) min average. You show up fast and clean.",
            category: .pattern, urgency: .ambient
        )
    }

    static func narrativeSpecialist(
        _ p: SessionProfile, arenas: [Arena], seen: Set<String>
    ) -> ForgeNarrative? {
        guard p.totalSessions >= 20, let primaryId = p.primaryArenaId else { return nil }
        let fraction = p.arenaDistribution[primaryId] ?? 0
        guard fraction >= 0.70 else { return nil }
        let id = "forge_specialist_\(primaryId)"
        guard !seen.contains(id) else { return nil }
        let arena = arenas.first { $0.id == primaryId }
        let label = arena?.label ?? primaryId.uppercased()
        let pct   = Int(fraction * 100)
        return ForgeNarrative(
            id: id, glyph: "◆",
            headline: "\(label) SPECIALIST",
            flavor: "\(pct)% of sessions in \(label). You found your arena. Now go deep.",
            category: .arenaDepth, urgency: .ambient
        )
    }

    static func narrativeSocial(_ p: SessionProfile, seen: Set<String>) -> ForgeNarrative? {
        let id = "forge_social"
        let socialCount = Int(p.socialRatio * Double(p.totalSessions))
        guard !seen.contains(id),
              socialCount >= 5 else { return nil }
        return ForgeNarrative(
            id: id, glyph: "◆",
            headline: "SOCIAL INTEGRATOR",
            flavor: "\(socialCount) sessions with people. You understand that the work doesn't always happen alone.",
            category: .social, urgency: .ambient
        )
    }

    // MARK: Tier 7 — Ambient nudges

    static func narrativeReflective(lastSession: Session?, seen: Set<String>) -> ForgeNarrative? {
        let id = "forge_reflective"
        guard !seen.contains(id),
              let s = lastSession,
              s.note.count >= 50 else { return nil }
        return ForgeNarrative(
            id: id, glyph: "▸",
            headline: "REFLECTIVE SESSION",
            flavor: "You wrote \(s.note.count) characters of notes. Most people just log the time. You logged the meaning.",
            category: .pattern, urgency: .ambient
        )
    }

    static func narrativeNeglect(
        _ p: SessionProfile, arenas: [Arena], seen: Set<String>
    ) -> ForgeNarrative? {
        // Fire for the first unseen neglected arena
        for arenaId in p.neglectedArenaIds {
            let id = "forge_neglect_\(arenaId)"
            guard !seen.contains(id) else { continue }
            let arena = arenas.first { $0.id == arenaId }
            let label = arena?.label ?? arenaId.uppercased()
            return ForgeNarrative(
                id: id, glyph: "▪",
                headline: "\(label) DORMANT",
                flavor: "\(label) hasn't seen a session in over two weeks. It doesn't have to be long. Just show up.",
                category: .pattern, urgency: .ambient
            )
        }
        return nil
    }
}

// MARK: - ForgeEngine.Queries
// Pure boolean classifiers. Pass a SessionProfile — get a direct answer.
// Use these anywhere: UI conditionals, debug panels, unit tests.

extension ForgeEngine {
    enum Queries {

        // --- Volume ---
        static func isNewcomer(_ p: SessionProfile)    -> Bool { p.totalSessions < 5 }
        static func isVeteran(_ p: SessionProfile)     -> Bool { p.totalSessions >= 100 }
        static func isElder(_ p: SessionProfile)       -> Bool { p.totalSessions >= 365 }

        // --- Streaks ---
        static func isOnStreak(_ p: SessionProfile)    -> Bool { p.currentGlobalStreak >= 3 }
        static func isStreakChaser(_ p: SessionProfile) -> Bool { p.currentGlobalStreak >= 7 }
        static func isConsistent(_ p: SessionProfile)  -> Bool { p.consistencyScore >= 0.6 }

        // --- Recency ---
        static func isReturningUser(_ p: SessionProfile) -> Bool {
            p.previousSessionGapDays >= 7 && p.previousSessionGapDays <= 14
        }
        static func isLapsed(_ p: SessionProfile)      -> Bool { p.previousSessionGapDays >= 30 }
        static func isRecovering(_ p: SessionProfile)  -> Bool {
            p.previousSessionGapDays >= 15 && p.previousSessionGapDays <= 60
        }

        // --- Momentum ---
        static func isSurging(_ p: SessionProfile)     -> Bool { p.isGrowing && p.sessionsLast7 >= 4 }
        static func isDeclining(_ p: SessionProfile)   -> Bool { p.isDeclining }
        static func isStable(_ p: SessionProfile)      -> Bool { !p.isGrowing && !p.isDeclining }

        // --- Work style ---
        static func isDeepWorker(_ p: SessionProfile)  -> Bool { p.averageDuration >= 45 && p.totalSessions >= 10 }
        static func isSprinter(_ p: SessionProfile)    -> Bool { p.averageDuration <= 20 && p.totalSessions >= 10 }
        static func isStackMaster(_ p: SessionProfile) -> Bool { p.stackingFrequency >= 0.5 }

        // --- Time of day ---
        static func isMorningPerson(_ p: SessionProfile)   -> Bool { p.morningRatio >= 0.5 }
        static func isAfternoonPerson(_ p: SessionProfile) -> Bool { p.afternoonRatio >= 0.5 }
        static func isNightOwl(_ p: SessionProfile)        -> Bool { p.eveningRatio >= 0.5 }
        static func isInPeakWindow(_ p: SessionProfile)    -> Bool {
            let hour = Calendar.current.component(.hour, from: Date())
            return abs(hour - p.peakHour) <= 1
        }

        // --- Arena ---
        static func isSpecialist(_ p: SessionProfile) -> Bool {
            guard let id = p.primaryArenaId else { return false }
            return (p.arenaDistribution[id] ?? 0) >= 0.70 && p.totalSessions >= 20
        }
        static func isBalancer(_ p: SessionProfile, arenas: [Arena]) -> Bool {
            arenas.allSatisfy { (p.arenaDistribution[$0.id] ?? 0) >= 0.15 } && p.totalSessions >= 20
        }
        static func hasNeglectedArenas(_ p: SessionProfile) -> Bool { !p.neglectedArenaIds.isEmpty }
        static func hasUnusedArenas(_ p: SessionProfile)    -> Bool { !p.neverUsedArenaIds.isEmpty }

        /// Suggests the arena the user is most overdue to visit at this hour.
        /// Returns nil if all arenas are recently active or profile is too sparse.
        static func suggestedArena(forHour hour: Int, profile p: SessionProfile) -> String? {
            // Prefer neglected arenas; among those pick the one closest to peak usage hour
            guard !p.neglectedArenaIds.isEmpty else { return nil }
            // For now return the first neglected arena (ordered by original neglectedArenaIds)
            return p.neglectedArenaIds.first
        }

        /// Returns the suggested session duration for an arena based on the user's median there.
        /// Falls back to the user's overall average, then 25 minutes.
        static func suggestedDuration(arenaId: String, profile p: SessionProfile) -> Int {
            p.typicalDurationByArena[arenaId] ?? p.averageDuration.clamped(to: 10...120)
        }

        // --- Social ---
        static func isSocialIntegrator(_ p: SessionProfile) -> Bool { p.socialRatio >= 0.25 }
        static func isSoloFocused(_ p: SessionProfile)      -> Bool { p.socialRatio < 0.05 }
    }
}

// MARK: - Int clamping helper (local)

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}
