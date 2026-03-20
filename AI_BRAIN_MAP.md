# AI_BRAIN_MAP.md — Arena Protocol Session Intelligence
> Developer reference for the local, zero-API session intelligence layer.
> Last updated: 2026-03-20 (v2.22.0)

---

## Overview

Arena Protocol learns from session history entirely on-device. No API calls, no accounts, no external models. The intelligence layer consists of two components:

| Component | File | Role |
|---|---|---|
| **SessionIntelligence** | `Models/SessionIntelligence.swift` | Computes a `SessionProfile` from raw `[Session]` + `[Arena]` |
| **ForgeEngine** | `Models/ForgeEngine.swift` | Evaluates narratives from a `SessionProfile`, produces `ForgeNarrative` |

The DataStore owns both: `store.sessionProfile` (computed var) and `checkAndClaimEmberDrop()` (calls ForgeEngine first, then falls back to legacy EMBER_DROPS).

---

## Data Flow

```
[Session] + [Arena]
       │
       ▼
buildSessionProfile(from:arenas:)
       │
       ▼
SessionProfile  ◄── 25+ computed fields
       │
       ▼
ForgeEngine.evaluate(profile:arenas:lastSession:seenDropIds:)
       │
       ▼
ForgeNarrative?  ──── .toEmberDrop() ──── EmberDropModal
                      (existing pipeline, unchanged)
```

`RootView.swift` calls `store.checkAndClaimEmberDrop()` after every session completion. The drop ID is stored in `store.seenDrops` (`[String]`) to prevent replay.

---

## SessionProfile Field Reference

### Volume
| Field | Type | Description |
|---|---|---|
| `totalSessions` | `Int` | All-time session count |
| `totalMinutes` | `Int` | All-time minutes logged |
| `activeDaysLast30` | `Int` | Distinct days with ≥1 session in last 30 days |
| `consistencyScore` | `Double` | `activeDaysLast30 / 30` — 0.0 to 1.0 |

### Recency & Momentum
| Field | Type | Description |
|---|---|---|
| `sessionsLast7` | `Int` | Sessions in the last 7 days |
| `sessionsPrior7` | `Int` | Sessions 8–14 days ago |
| `weeklyTrend` | `Double` | `last7 / prior7` (2.0 if prior7=0 and last7>0) |
| `isGrowing` | `Bool` | `weeklyTrend ≥ 1.5 AND last7 ≥ 3` |
| `isDeclining` | `Bool` | `weeklyTrend ≤ 0.5 AND prior7 ≥ 3` |
| `daysSinceLastSession` | `Int` | Days since most recent session (0 = today) |
| `previousSessionGapDays` | `Int` | Gap between the two most recent sessions — key for comeback detection |

### Duration Patterns
| Field | Type | Description |
|---|---|---|
| `averageDuration` | `Int` | Minutes — `totalMinutes / totalSessions` |
| `typicalDurationByArena` | `[String: Int]` | Median duration per arena (arenaId → minutes) |

**Use cases:** Session timer default, ForgeEngine deep-worker/sprinter detection, UI suggestion chips.

### Time of Day
| Field | Type | Description |
|---|---|---|
| `peakHour` | `Int` | Most common session start hour (0–23) |
| `morningRatio` | `Double` | Fraction of sessions starting 05–11 |
| `afternoonRatio` | `Double` | Fraction of sessions starting 12–17 |
| `eveningRatio` | `Double` | Fraction of sessions starting 18–23 + 00–04 |

**Use cases:** Smart nudge timing, `Queries.isInPeakWindow()`, future scheduled notification logic.

### Arena Affinity
| Field | Type | Description |
|---|---|---|
| `primaryArenaId` | `String?` | Most-used arena (nil if no sessions) |
| `arenaSessionCounts` | `[String: Int]` | Per-arena all-time session count |
| `arenaDistribution` | `[String: Double]` | Per-arena fraction of total sessions |
| `neglectedArenaIds` | `[String]` | Used arenas with <10% share AND no session in 14 days |
| `neverUsedArenaIds` | `[String]` | Arenas with 0 sessions ever |

**Use cases:** Specialist detection, neglect nudges, empty-state suggestions in HomeView, arena card ordering hints.

### Streaks
| Field | Type | Description |
|---|---|---|
| `currentGlobalStreak` | `Int` | Consecutive days with any session (from today or yesterday) |
| `longestGlobalStreak` | `Int` | All-time best global streak |
| `currentArenaStreaks` | `[String: Int]` | Per-arena current streak |

### Sequences
| Field | Type | Description |
|---|---|---|
| `stackingFrequency` | `Double` | Fraction of active days with 2+ arenas |
| `commonTransitions` | `[ArenaTransition]` | Top 3 arena-to-arena pairs (ordered by frequency) |

**Use cases:** `isStackMaster()`, future "you usually follow X with Y" suggestions, JointArenaPicker ordering.

### Social
| Field | Type | Description |
|---|---|---|
| `socialRatio` | `Double` | Fraction of sessions with `social == true` |

### Archetype
| Field | Type | Description |
|---|---|---|
| `archetype` | `UserArchetype` | Single label summarising the user's dominant pattern |

---

## UserArchetype Decision Tree

```
totalSessions < 5             → .newcomer
totalSessions ≥ 100           → .veteran
previousSessionGapDays 15–60  → .recovering
previousSessionGapDays ≥ 7    → .returning
isGrowing                     → .surging
currentGlobalStreak ≥ 7       → .streakChaser
total ≥ 20 AND primary ≥ 70%  → .specialist
total ≥ 20 AND all ≥ 15%      → .balancer
avg ≥ 45                      → .deepWorker
else                          → .sprinter
```

---

## ForgeEngine Narrative Catalogue

All drop IDs are prefixed `forge_` to avoid collision with legacy `drop_` IDs.

### Tier 1 — First Contact
| ID | Trigger | Glyph |
|---|---|---|
| `forge_debut` | `totalSessions == 1` | ▸ |
| `forge_first_{arenaId}` | `arenaSessionCounts[id] == 1 AND total > 1` | arena.icon |

### Tier 2 — Volume Milestones
| ID | Trigger | Glyph |
|---|---|---|
| `forge_global_5` | `totalSessions ≥ 5` | ◆ |
| `forge_global_10` | `totalSessions ≥ 10` | ★ |
| `forge_global_25` | `totalSessions ≥ 25` | ⬟ |
| `forge_global_50` | `totalSessions ≥ 50` | ✦ |
| `forge_global_100` | `totalSessions ≥ 100` | ❋ |
| `forge_global_200` | `totalSessions ≥ 200` | ⟡ |
| `forge_global_365` | `totalSessions ≥ 365` | ◈ |
| `forge_arena_{id}_{n}` | `arenaSessionCounts[id] ≥ n` where n ∈ [3,7,13,21,33,50,77,111] | varies |

### Tier 3 — Streak Milestones
| ID | Trigger |
|---|---|
| `forge_streak_3` | `currentGlobalStreak ≥ 3` |
| `forge_streak_7` | `currentGlobalStreak ≥ 7` |
| `forge_streak_14` | `currentGlobalStreak ≥ 14` |
| `forge_streak_21` | `currentGlobalStreak ≥ 21` |
| `forge_streak_30` | `currentGlobalStreak ≥ 30` |
| `forge_streak_60` | `currentGlobalStreak ≥ 60` |
| `forge_streak_100` | `currentGlobalStreak ≥ 100` |

### Tier 4 — Momentum Events
| ID | Trigger |
|---|---|
| `forge_comeback` | `previousSessionGapDays ≥ 7 AND totalSessions ≥ 5` |
| `forge_surge` | `isGrowing AND sessionsLast7 ≥ 5` |

### Tier 5 — Balance
| ID | Trigger |
|---|---|
| `forge_all_arenas` | All arenas have ≥1 session AND arenas.count ≥ 3 |
| `forge_balancer` | `archetype == .balancer` |
| `forge_multistreak` | 2+ arenas with `currentArenaStreak ≥ 7` |

### Tier 6 — Behavioral Patterns
| ID | Trigger |
|---|---|
| `forge_deep_worker` | `averageDuration ≥ 45 AND totalSessions ≥ 10` |
| `forge_sprinter` | `averageDuration ≤ 20 AND totalSessions ≥ 15` |
| `forge_specialist_{arenaId}` | `arenaDistribution[id] ≥ 0.70 AND total ≥ 20` |
| `forge_social` | `social session count ≥ 5` |

### Tier 7 — Ambient Nudges
| ID | Trigger |
|---|---|
| `forge_reflective` | `lastSession.note.count ≥ 50` |
| `forge_neglect_{arenaId}` | `arenaId` in `neglectedArenaIds` |

---

## Testable Queries API

`ForgeEngine.Queries` — pure functions, no side effects. Pass a `SessionProfile`, get a `Bool` (or a suggestion).

```swift
// Volume
Queries.isNewcomer(p)           // total < 5
Queries.isVeteran(p)            // total ≥ 100
Queries.isElder(p)              // total ≥ 365

// Streaks
Queries.isOnStreak(p)           // streak ≥ 3
Queries.isStreakChaser(p)       // streak ≥ 7
Queries.isConsistent(p)        // consistencyScore ≥ 0.6

// Recency
Queries.isReturningUser(p)     // gap 7–14 days
Queries.isLapsed(p)            // gap ≥ 30 days
Queries.isRecovering(p)        // gap 15–60 days

// Momentum
Queries.isSurging(p)           // trending up fast
Queries.isDeclining(p)         // trending down
Queries.isStable(p)            // neither

// Work style
Queries.isDeepWorker(p)        // avg ≥ 45 min, 10+ sessions
Queries.isSprinter(p)          // avg ≤ 20 min, 10+ sessions
Queries.isStackMaster(p)       // stacking ≥ 50% of days

// Time of day
Queries.isMorningPerson(p)
Queries.isAfternoonPerson(p)
Queries.isNightOwl(p)
Queries.isInPeakWindow(p)      // current hour within ±1 of peakHour

// Arena
Queries.isSpecialist(p)
Queries.isBalancer(p, arenas:)
Queries.hasNeglectedArenas(p)
Queries.hasUnusedArenas(p)
Queries.suggestedArena(forHour:profile:) -> String?
Queries.suggestedDuration(arenaId:profile:) -> Int

// Social
Queries.isSocialIntegrator(p)  // socialRatio ≥ 0.25
Queries.isSoloFocused(p)       // socialRatio < 0.05
```

---

## UI Integration Points

| Where | What to use |
|---|---|
| HomeView arena cards | `Queries.suggestedArena(forHour:profile:)` for a soft highlight |
| SelectView timer default | `Queries.suggestedDuration(arenaId:profile:)` |
| ActiveSessionView | `Queries.isInPeakWindow(p)` for peak-hour indicator |
| HistoryView / Stats | `store.sessionProfile` for all summary fields |
| Morning checkin nudge | `Queries.hasNeglectedArenas(p)` → surface dormant arena |
| Session completion | `store.checkAndClaimEmberDrop()` (already wired) |

---

## Extension Points (Future)

1. **Time-aware recurring narratives** — Today `forge_decline` fires once. Future: use `forge_decline_YYYY-MM` IDs to allow monthly re-evaluation.
2. **API-backed Forge** — Replace `ForgeEngine.evaluate()` with a Claude API call that receives `SessionProfile` as structured JSON. The `ForgeNarrative` struct maps directly to the API response schema.
3. **Predictive suggestions** — Use `commonTransitions` to suggest the next arena after completing one (e.g., "You usually follow WORK with RECOVERY").
4. **Habit correlation** — Extend `SessionProfile` with habit completion rates to identify when sessions and habits reinforce each other.
5. **Weekly report** — A scheduled narrative summarising `activeDaysLast30`, `weeklyTrend`, `currentGlobalStreak`, and an archetype statement. Could replace or augment the morning check-in.
6. **Arena unlock gates** — `Queries.hasUnusedArenas(p)` + time-in-app to surface a "new arena reveal" mechanic for newcomers.

---

## Testing

All `Queries.*` functions are pure and unit-testable. Example:

```swift
@Test func detectDeepWorker() {
    var sessions = (0..<15).map { _ in Session(arenaId: "work", duration: 60, ...) }
    let profile = buildSessionProfile(from: sessions, arenas: DEFAULT_ARENAS)
    #expect(ForgeEngine.Queries.isDeepWorker(profile))
}
```

ForgeEngine narratives are testable by calling `ForgeEngine.evaluate()` with a constructed `SessionProfile` and an empty `seenDropIds` array, then asserting on the returned `ForgeNarrative.id`.
