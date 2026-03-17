# FORGE SYSTEM ROADMAP
> Arena Protocol — Progression, Inventory & Multiplayer Layer
> Created: 2026-03-17

---

## Vision

The Forge System transforms Arena Protocol from a solo focus timer into a living progression world. Every session you complete feeds into a loop of streaks → egg drops → incubation → hatching → rewards → prestige. The multiplayer layer means your eggs, forge marks, and rebirth progress are visible to others — and others' progress is visible to you. The end-game is Rebirth Island 10 and the rarest egg in existence: the Echo Egg.

The north star: **your phone's lock screen and Dynamic Island should always reflect where you are in the world, not just what timer is running.**

---

## System 1 — Streak Stages

### Per-Arena Streak Tiers

Each arena tracks consecutive days independently. Hitting a tier triggers a drop and a visual state change on the arena card.

| Day | Tier Name       | Glyph | Trigger Effect                                  |
|-----|-----------------|-------|-------------------------------------------------|
| 1   | SPARK           | ▸     | Streak begins. No drop.                         |
| 3   | KINDLED         | ◆     | Common Egg drops. Forge First Blood possible.   |
| 7   | THE UNBROKEN    | ★     | Global title unlocks. Uncommon Egg incubates.   |
| 14  | EMBER           | ⬟     | Common Egg upgrades to Uncommon on hatch.       |
| 21  | FORGED          | ✦     | Rare Egg drops. Forge milestone (21 sessions).  |
| 30  | TEMPERED        | ❋     | Rare Egg begins incubation.                     |
| 60  | ASCENDANT       | ⟡     | Rare hatches. Rebirth Island 1 unlocked.        |
| 100 | MYTHIC          | ◈     | Epic Egg drops.                                 |
| 365 | ETERNAL         | ✸     | Legendary Egg drops. Rebirth Island 10 path opens. |

### Global Streak (all arenas combined)
A parallel streak tracks whether *any* session was completed today. Used for global title progression and multiplayer leaderboard ranking.

---

## System 2 — Egg Incubation

### Egg Rarities

Eggs do not hatch on time — they hatch on **sessions completed after the drop**. This keeps the system session-driven, not idle.

| Rarity    | Hatch Cost    | Drop Sources                              |
|-----------|---------------|-------------------------------------------|
| Common    | 5 sessions    | Forge Day 3 / session milestone 3         |
| Uncommon  | 15 sessions   | Streak Day 14 / session milestone 13      |
| Rare      | 30 sessions   | Streak Day 30 / session milestone 21      |
| Epic      | 60 sessions   | Streak Day 60 / session milestone 50      |
| Legendary | 100 sessions  | Streak Day 365 / Rebirth cycle            |

### Hatch Rewards by Rarity

| Rarity    | Possible Contents                                                    |
|-----------|----------------------------------------------------------------------|
| Common    | Arena icon variant, title fragment (non-equippable lore piece)       |
| Uncommon  | New forge glyph skin, arena color accent unlock                      |
| Rare      | Title unlock, animated forge mark, protocol template                 |
| Epic      | Badge frame, arena card aura, animated timer ring skin               |
| Legendary | Rebirth Island gate key, "THE UNDYING" / "THE REBORN" title, Echo Egg |

### Echo Egg (Rarest)
Drops only on Rebirth Island 10 completion. When hatched (100 sessions), it replays a ghost animation of your highest-volume arena day — a visual memory of your best performance. In multiplayer, Echo Eggs are public: other players can see your ghost replay on the shared world map.

---

## System 3 — Rebirth Island (Prestige)

Rebirth is triggered per-arena when you hit the Eternal forge mark (111 sessions). The arena's session count resets to 0. Each reset unlocks one permanent Island tier.

| Island | Name              | Requirement              | Permanent Unlock                                      |
|--------|-------------------|--------------------------|-------------------------------------------------------|
| 1      | The Shore         | 111 sessions (reset 1)   | Gold forge mark border                                |
| 2      | The Descent       | 111 sessions (reset 2)   | Arena aura glyph                                      |
| 3      | The Passage       | reset 3                  | Dark background variant per arena                     |
| 4      | The Deep          | reset 4                  | Pulse animation on timer ring                         |
| 5      | The Core          | reset 5                  | Session impact particles on complete screen           |
| 6      | The Ascent        | reset 6                  | Animated arena card illustration                      |
| 7      | The Convergence   | reset 7                  | "THE UNDYING" title                                   |
| 8      | The Threshold     | reset 8                  | Legendary Egg guaranteed on next milestone            |
| 9      | The Void          | reset 9                  | Forge marks show legacy total (not reset count)       |
| 10     | REBIRTH ISLAND    | reset 10                 | "THE REBORN" title + Echo Egg drops                   |

Rebirth is **per-arena**. Reaching Island 10 in all four arenas simultaneously unlocks a fifth hidden arena: **THE VOID** (placeholder — no mechanic defined yet).

---

## System 4 — Inventory

### InventoryItem Types

```
type: "egg"          — incubating or hatched egg with rarity + progress
type: "title"        — equippable title string shown on profile + home header
type: "glyph"        — equippable arena icon variant
type: "badge"        — frame/border cosmetic for arena card
type: "aura"         — animated effect on timer ring or arena card
type: "fragment"     — non-equippable lore piece, collectible only
type: "echo"         — Echo Egg replay data (session snapshot)
```

### Inventory Screen Layout

```
┌─────────────────────────────────┐
│ INVENTORY                       │
│ ─────────────────────────────── │
│ INCUBATING (2)                  │
│  ◆ Uncommon Egg — 9/15 sessions │
│  ★ Rare Egg     — 4/30 sessions │
│ ─────────────────────────────── │
│ HATCHED (tabs: All / Titles /   │
│          Glyphs / Auras / Echo) │
│  [grid of unlocked items]       │
│ ─────────────────────────────── │
│ WHAT IS POSSIBLE                │
│  [greyed preview of locked      │
│   Legendary + Island 10 items]  │
│  "Reach Rebirth Island 10 →"    │
└─────────────────────────────────┘
```

---

## System 5 — Multiplayer Layer

### Architecture Philosophy

The multiplayer system is **asynchronous and ambient** — no real-time gameplay, no push pressure. You see others' progress passively. Competition is opt-in through leaderboards. The social layer is motivational, not disruptive.

### Player Profile

Each player has a public profile containing:
- Active title (equipped)
- Equipped arena glyphs
- Forge marks per arena (Island tier shown as roman numeral: BODY III)
- Current streak counts
- Echo Egg replay (if hatched — viewable by others)
- Rebirth Island level per arena

### Multiplayer Features (phased)

**Phase 1 — Presence (no backend yet, prep data model)**
- `PlayerProfile` struct added to DataStore (local only)
- All cosmetics tagged as `isEquipped: Bool`
- Profile screen added — shows your own profile as others would see it

**Phase 2 — Leaderboard (read-only, CloudKit public database)**
- Players opt in to posting their profile to a shared CloudKit public record zone
- Home screen shows a "FORGE WORLD" strip: 3–5 nearby players ranked by total sessions this week
- No usernames — identified by title + arena glyphs only (privacy-first)

**Phase 3 — Guild / Tribe System**
- Small invite-only groups (max 7 players — "a Forge")
- Shared weekly session count goal
- Collective streak: if the group hits X sessions total this week, everyone gets a bonus egg drop
- Guild chat is out of scope — this is not a social app, it's a focus app

**Phase 4 — Echo Replay World Map**
- A read-only "world" screen showing active Echo Eggs from other Rebirth Island 10 players
- Each echo is a small animated glyph on a minimal map
- Tap to see their ghost session replay
- This is the rarest thing in the game — most players will never see it, which is the point

---

## Data Models (to be built)

```swift
// New models to add to DataStore.swift

struct InventoryEgg: Identifiable, Codable {
    var id: String                    // UUID
    var rarity: EggRarity             // common | uncommon | rare | epic | legendary | echo
    var droppedAt: Double             // epoch ms
    var sessionCountOnDrop: Int       // store.sessions.count when dropped
    var hatchThreshold: Int           // sessions needed after drop
    var isHatched: Bool
    var rewardId: String?             // points to InventoryItem.id after hatch
    var sourceArenaId: String?        // which arena triggered the drop
    var sourceTrigger: String         // "streak_7" | "forge_21" | "rebirth_1" etc.
}

struct InventoryItem: Identifiable, Codable {
    var id: String
    var type: InventoryItemType       // egg | title | glyph | badge | aura | fragment | echo
    var rarity: EggRarity
    var name: String
    var description: String
    var glyph: String                 // display character
    var isEquipped: Bool
    var unlockedAt: Double            // epoch ms
    var echoData: EchoReplay?         // only for type == .echo
}

struct EchoReplay: Codable {
    var arenaId: String
    var date: String                  // yyyy-MM-dd of the replayed day
    var sessionCount: Int             // how many sessions that day
    var totalMinutes: Int
    var snapshots: [EchoSnapshot]     // timestamps of each session start within that day
}

struct EchoSnapshot: Codable {
    var arenaId: String
    var startedAt: Double             // epoch ms
    var duration: Int                 // minutes
}

struct RebirthState: Codable {
    var arenaId: String
    var islandLevel: Int              // 0–10
    var totalSessionsAllTime: Int     // legacy count preserved across resets
    var rebirthDates: [String]        // yyyy-MM-dd of each reset
}

struct PlayerProfile: Codable {
    var playerId: String              // local UUID, stable
    var equippedTitleId: String?
    var equippedGlyphs: [String: String]  // arenaId → InventoryItem.id
    var rebirthStates: [RebirthState]
    var isPublic: Bool                // opt-in to leaderboard
    var joinedAt: Double              // epoch ms
}

enum EggRarity: String, Codable, CaseIterable {
    case common, uncommon, rare, epic, legendary, echo
}

enum InventoryItemType: String, Codable {
    case egg, title, glyph, badge, aura, fragment, echo
}
```

---

## Build Order

1. **DataStore models** — add all structs above, wire `eggs`, `inventory`, `rebirthStates`, `playerProfile` to UserDefaults
2. **Drop engine** — expand `checkAndClaimEmberDrop` into a full `ForgeEngine` that evaluates streak tiers, forge milestones, and rebirth gates after every session
3. **InventoryView** — incubating eggs with progress, hatched items grid, "WHAT IS POSSIBLE" locked preview
4. **Profile screen** — how your profile looks to others; equip titles and glyphs
5. **Rebirth flow** — confirmation modal on hitting Island gate, reset + permanent unlock animation
6. **Echo Egg UI** — ghost replay animation on CompleteView for Island 10 players
7. **CloudKit prep** — `PlayerProfile` serialization for future Phase 2 leaderboard post
8. **Forge World strip** — Home screen ambient leaderboard (Phase 2)

---

## Open Questions

- Should Rebirth reset **all** forge sessions or only the visual forge mark display? (Recommendation: reset display count, preserve `totalSessionsAllTime` for legacy bragging rights)
- Should eggs be losable? (e.g. break streak before hatch = egg cracks/degrades) — adds real tension but may feel punishing
- Guild max size: 7 feels right thematically (a Forge). Could be 4 (one per arena) — discuss
- Echo Egg: server-side or local-only first? Local first, cloud sync later.
- THE VOID (5th arena on Island 10 × 4): placeholder or cut? Keep as mystery reward, don't build yet.
