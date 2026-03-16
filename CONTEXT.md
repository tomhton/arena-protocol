# CONTEXT.md — Arena Protocol
> Paste this at the start of every Claude session. Last updated: 2026-03-13.

---

## App Identity

**Name:** Arena Protocol
**One-liner:** A dark-themed iOS life-management app built around timed focus sessions across four life "arenas" (Body, Spirit, Tribe, Craft) with gamification, habit tracking, and daily rituals.
**Bundle ID:** `com.arenaprotocol.app`
**Repo:** `tomhton/arena-protocol`
**Active branch:** `main`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6 |
| UI | SwiftUI (no UIKit) |
| State | `@Observable` (iOS 17+ Observation framework) |
| Persistence | `UserDefaults` + `Codable` (JSON) |
| Notifications | `UNUserNotificationCenter` |
| Min target | iOS 18.0 |
| Package | Swift Package Manager (`ios/Package.swift`) |
| CI (cloud) | Codemagic (`native-swift-ios` workflow) + GitHub Actions (`build-native-ios.yml`) |
| Tests | Swift Testing framework (`@Suite`, `@Test`) |
| Legacy (archived) | React 18 + Vite + Capacitor 6 — still in `src/` for reference |

---

## Version History

| Version | Date | Summary |
|---|---|---|
| 1.0.0 | pre-2026 | React/Capacitor hybrid app (`src/App.jsx`, 1971 lines) |
| 2.0.0 | 2026-03-13 | **Full native SwiftUI rewrite** — 25 Swift files, all features preserved |

### v2.0.0 Changes
- Ground-up rewrite from Capacitor/React → native Swift/SwiftUI
- `@Observable` DataStore replaces localStorage
- Native Canvas illustrations replace React SVG watermarks
- Native circular timer, share sheet, deep-link app shortcuts
- 30+ unit tests added
- `TESTBENCH_SETUP_WIN11.md` — Windows 11 → iOS device pipeline guide
- `codemagic.yaml` updated with `native-swift-ios` workflow
- `.github/workflows/build-native-ios.yml` added

---

## File Map

```
arena-protocol/
├── CONTEXT.md                              ← YOU ARE HERE
├── TESTBENCH_SETUP_WIN11.md                ← Windows 11 build/install guide
├── codemagic.yaml                          ← CI: native-swift-ios + legacy workflows
├── .github/workflows/build-native-ios.yml ← GitHub Actions build
├── ios/
│   ├── Package.swift                       ← SPM manifest, iOS 18+, Swift 6
│   ├── ArenaProtocol/
│   │   ├── ArenaProtocolApp.swift          ← @main entry, WindowGroup
│   │   ├── Models/
│   │   │   └── DataStore.swift            ← ALL models + defaults + persistence + helpers
│   │   ├── Views/
│   │   │   ├── RootView.swift             ← Screen router (Screen enum + navigate func)
│   │   │   ├── HomeView.swift             ← Dashboard: arena grid, shortcuts, ember particles
│   │   │   ├── SelectView.swift           ← Session config: quest, sub-arena, duration
│   │   │   ├── ActiveSessionView.swift    ← Live timer + CompleteView
│   │   │   ├── ProtocolsView.swift        ← Protocol list/editor + ActiveProtocolView
│   │   │   ├── MorningCheckinView.swift   ← 15-min morning ritual (3 habits)
│   │   │   ├── WindDownView.swift         ← Evening: journal + habit check
│   │   │   ├── HabitManagerView.swift     ← CRUD for habits
│   │   │   ├── HistoryView.swift          ← Stats: chart, habits, log, journal + export
│   │   │   ├── NotesView.swift            ← Quick idea capture
│   │   │   ├── SettingsView.swift         ← Wind-down time, nav to habits/arenas
│   │   │   ├── StuckView.swift            ← Emergency: grace period → arena pick
│   │   │   └── ArenaEditorView.swift      ← Arena CRUD (ArenaListEditorView + ArenaEditorView)
│   │   ├── Components/
│   │   │   ├── ArenaCardView.swift        ← Card UI + Canvas illustrations + AddArenaCardView
│   │   │   ├── CircularTimerView.swift    ← Reusable circular progress timer
│   │   │   ├── AppShortcutsBar.swift      ← 6 app shortcut buttons (deep link + fallback)
│   │   │   └── EmberDropModal.swift       ← Achievement popup overlay
│   │   └── Resources/
│   │       └── Info.plist                 ← Bundle config, URL schemes, dark mode
│   └── Tests/
│       └── ArenaProtocolTests/
│           └── ArenaProtocolTests.swift   ← 30+ unit tests
└── src/                                   ← LEGACY React source (archived, do not edit)
    ├── App.jsx                            ← Original 1971-line monolith (reference only)
    └── main.jsx
```

---

## Screen Inventory

| Screen | File | What it does |
|---|---|---|
| **Home** | `HomeView.swift` | 2-column arena grid, header with title/streak count, edit toggle, app shortcuts bar, Protocols + I AM STUCK buttons, morning/wind-down footer nav |
| **Morning Check-in** | `MorningCheckinView.swift` | 3-step ritual (Reading 5m, Goals 5m, Movement 5m), animated progress bar, skip option. Shows once per day. |
| **Select** | `SelectView.swift` | Arena detail + quest note textarea, sub-arena pills → example task list, duration picker (5/10/30/60/90/custom), Google Calendar option, launches session |
| **Active Session** | `ActiveSessionView.swift` | Live countdown ring, arena name, quest note, focus hint, pause/resume, done/abandon |
| **Complete** | `ActiveSessionView.swift` (CompleteView) | Session complete screen with icon pop animation, saves session, triggers ember drop check |
| **Protocols** | `ProtocolsView.swift` | List of 4 protocols with block strips, edit durations/name/desc, BEGIN PROTOCOL button |
| **Active Protocol** | `ProtocolsView.swift` (ActiveProtocolView) | Segmented multi-block timer, advances blocks automatically, overall + per-block progress |
| **History** | `HistoryView.swift` | Stats cards (sessions/minutes/days), CSV/JSON export, 4 tabs: Chart (7-day bar + arena breakdown), Habits (70-day grid), Log (reverse session list), Journal |
| **Notes** | `NotesView.swift` | TextEditor + add button, timestamped idea list, delete per item |
| **Wind Down** | `WindDownView.swift` | Step-through: journal entry → yes/no for each habit, saves logs, step progress bar |
| **Habit Manager** | `HabitManagerView.swift` | List habits, CRUD editor (name, goal, color picker) |
| **Settings** | `SettingsView.swift` | Wind-down time DatePicker (wheel), nav to Manage Habits + Manage Arenas |
| **Arena List Editor** | `ArenaEditorView.swift` (ArenaListEditorView) | 2-col grid in edit mode, + NEW card |
| **Arena Editor** | `ArenaEditorView.swift` (ArenaEditorView) | Full form: name, subtitle, icon grid, color circles, description, examples textarea, save/delete |
| **Stuck** | `StuckView.swift` | 3 phases: config (duration + optional intention) → countdown ring → mandatory arena pick |

---

## Navigation System

Navigation is handled by a `Screen` enum in `RootView.swift` and a `navigate(_ screen: Screen)` closure passed down to all views. There is **no NavigationStack** — all routing is a single `switch screen` block in `RootView.body`.

```swift
enum Screen: Hashable {
    case home
    case checkin
    case select(Arena)
    case active(Arena, Int, String)    // arena, durationMins, note
    case complete(Arena, Int, String)
    case protocols
    case activeProtocol(ArenaProtocolModel)
    case history
    case notes
    case winddown
    case habits
    case settings
    case arenaEditor
    case editArena(Arena)
    case newArena
    case stuck
}
```

---

## Key Data Structures

### Arena
```swift
struct Arena: Identifiable, Codable, Equatable {
    var id: String           // "body" | "spirit" | "tribe" | "craft" | custom uid
    var label: String        // "BODY" (uppercase)
    var letter: String       // "A" "B" "C" "D" — auto-assigned by Arena.reletter()
    var color: String        // hex "#C0392B"
    var subtitle: String     // "move · fuel · rest"
    var description: String  // long description shown in SelectView
    var icon: String         // single unicode char "◉"
    var examples: [String]   // task suggestions
    var subArenas: [String: [String]]  // "MOVE": ["10 min walk", ...]
}
```

### Session
```swift
struct Session: Identifiable, Codable {
    var id: String           // UUID string
    var arenaId: String      // matches Arena.id
    var duration: Int        // minutes
    var date: String         // "yyyy-MM-dd"
    var note: String         // quest/note text
    var ts: Double           // epoch ms (Date().timeIntervalSince1970 * 1000)
}
```

### ArenaProtocolModel
```swift
struct ArenaProtocolModel: Identifiable, Codable {
    var id: String           // "warrior" | "monk" | "builder" | "ember" | custom
    var name: String         // "THE WARRIOR"
    var glyph: String        // "⚔"
    var color: String        // hex
    var description: String
    var blocks: [ProtocolBlock]
}
struct ProtocolBlock: Codable, Equatable {
    var arenaId: String
    var label: String
    var duration: Int        // minutes
    var color: String        // hex
}
```

### Habit / HabitLog
```swift
struct Habit: Identifiable, Codable {
    var id: String
    var name: String
    var goal: String         // optional description
    var color: String        // hex
    var createdAt: String    // "yyyy-MM-dd"
}
struct HabitLog: Codable {
    var habitId: String
    var date: String         // "yyyy-MM-dd"
    var value: Bool          // true = done, false = not done
    var ts: Double
}
```

### DataStore (single source of truth)
```swift
@Observable final class DataStore {
    var arenas:    [Arena]
    var sessions:  [Session]
    var habits:    [Habit]
    var habitLogs: [HabitLog]
    var journals:  [JournalEntry]
    var ideas:     [IdeaNote]
    var settings:  AppSettings        // { windDownTime: "21:30" }
    var protocols: [ArenaProtocolModel]
    var seenDrops: [String]           // ember drop ids already shown
    var checkin:   MorningCheckin     // { date, completed: [habitId] }

    // Computed
    var letteredArenas: [Arena]       // auto-assigns A/B/C/D letters
    var todaySessions: Int
}
```

### UserDefaults Keys
| Key | Type | Description |
|---|---|---|
| `arena_custom_arenas` | `[Arena]` | User's arenas |
| `arena_sessions` | `[Session]` | All sessions ever |
| `arena_habits` | `[Habit]` | User's habits |
| `arena_habit_logs` | `[HabitLog]` | Daily habit yes/no |
| `arena_journals` | `[JournalEntry]` | Wind-down journal entries |
| `arena_ideas` | `[IdeaNote]` | Quick captured ideas |
| `arena_settings` | `AppSettings` | App settings |
| `arena_protocols` | `[ArenaProtocolModel]` | Protocol definitions |
| `arena_seen_drops` | `[String]` | Seen ember drop IDs |
| `arena_checkin` | `MorningCheckin` | Today's morning check-in |
| `arena_checkin_dismissed` | `String` | Date string — skip checkin if == today |
| `timerEndTime` | `Double` | Timer end epoch (background resume) |

---

## Gamification System

### Forge Marks (per-arena milestones)
Thresholds: `[3, 7, 13, 21, 33, 50, 77, 111]`
Marks: `▪ ▸ ◆ ★ ⬟ ✦ ❋ ⟡` → Names: First Blood → Eternal

### Titles (unlocked globally)
| Title | Condition |
|---|---|
| THE MOVING | 7+ body sessions |
| THE BURNING | 20+ body sessions |
| THE WITNESS | 5+ tribe sessions |
| THE BUILDER | 10+ craft sessions |
| THE SEEKER | 7+ spirit sessions |
| THE RETURNED | Sessions on 3+ distinct days |
| THE FORGE | Sessions in all 4 arenas |
| THE UNBROKEN | 7-day consecutive streak |

### Ember Drops (one-time surprise modals)
| ID | Trigger |
|---|---|
| drop_1 | 1st session |
| drop_5 | 5th session |
| drop_13 | 13th session |
| drop_3arena | 3 different arenas in one day |
| drop_week | 7 consecutive days |

---

## Known Issues / Active Bugs

- `SelectView.swift` line ~55: Swift `if-let` shorthand `isCustomActive, let v = ...` — verify compiles cleanly in Xcode 16 (may need standard `if isCustomActive, let v = Int(customMinutes)` form)
- `SettingsView.swift`: wind-down time initializer reads from UserDefaults manually rather than through `DataStore` — consider simplifying to use `store.settings.windDownTime` directly
- `GrainOverlay` in `RootView.swift` uses `Canvas` with random dots; dots don't change between renders (static noise). Acceptable for v2.0.
- Deep-link URL schemes in `Info.plist` must be verified against current app versions (Spotify, YouTube URLs may have changed)
- No iCloud sync — all data is local to device. Multi-device parity not supported.
- No `.xcodeproj` file — project is SPM-only. Xcode cannot open it for Simulator/device builds or signing without a proper Xcode project file. See Task 2 below.

---

## Up Next (Feature Queue)

1. **Live Activity / Dynamic Island timer** — ActivityKit extension showing active session countdown on lock screen, notification banners, and Dynamic Island (compact + expanded). Target: iPhone 17 Pro Max Dynamic Island layout.
2. **WidgetKit extensions** — Lock screen widget (countdown + arena name) and small/medium home screen widget (current arena + start button).
3. **Google Calendar deep integration** — Read the user's calendar blocks for the day and surface them as suggested focus sessions in SelectView. When a calendar block matches an arena (e.g. "gym" → BODY), pre-fill the quest and duration. Expand beyond the existing morning habit → 15-min block trigger.
4. **Xcode Cloud → TestFlight pipeline** — Trigger on push to main, auto-sign, auto-deploy to TestFlight internal group.
5. **iCloud sync** — Migrate persistence from UserDefaults to NSUbiquitousKeyValueStore or CloudKit so data follows the user across devices.
6. **Apple Watch companion** — Session timer on wrist via WatchConnectivity.

---

## Color Palette Reference

| Arena | Hex | Usage |
|---|---|---|
| Body | `#C0392B` | Red — physical |
| Spirit | `#D4A017` | Gold — inner |
| Tribe | `#B87333` | Copper — social |
| Craft | `#708090` | Slate — work |
| Accent yellow | `#E8C547` | Primary CTA, morning |
| Accent purple | `#B794F4` | Wind-down, history |
| Accent pink | `#FF8FA3` | Stuck protocol |
| Background | `#080810` | App background (near-black) |
| Text primary | `#E8E8E8` | Body text |

---

## Build & Deploy Quick Reference

```bash
# Run logic tests (macOS/Linux/Windows with Swift toolchain)
cd ios && swift test

# Build for simulator (macOS only)
cd ios && xcodebuild -scheme ArenaProtocol \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO clean build

# Push to trigger cloud build
git push origin main

# Watch GitHub Actions build
gh run list --workflow="build-native-ios.yml" --limit 3
gh run watch <run-id>
```

See `TESTBENCH_SETUP_WIN11.md` for the complete Windows 11 → device install pipeline.

---

## Product Vision

<!-- NOTE: Content for this section was not received — please fill in. -->
