# CONTEXT.md — Arena Protocol
> Paste this at the start of every Claude session. Last updated: 2026-03-16.

---

## App Identity

**Name:** Arena Protocol
**One-liner:** A dark-themed iOS life-management app built around timed focus sessions across four life "arenas" (Body, Spirit, Tribe, Craft) with gamification, habit tracking, and daily rituals.
**Bundle ID:** `com.arenaprotocol.app`
**Repo:** `tomhton/arena-protocol`
**Active branch:** `main`
**Status:** ✅ Confirmed running on iPhone 17 Pro Max (physical device) and iOS Simulator

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6 |
| UI | SwiftUI (no UIKit, no AppDelegate, no SceneDelegate) |
| Lifecycle | `@main ArenaProtocolApp` — pure SwiftUI `WindowGroup` |
| State | `@Observable` (iOS 17+ Observation framework) |
| Persistence | `UserDefaults` + `Codable` (JSON) |
| Notifications | `UNUserNotificationCenter` |
| Min target | iOS 18.0 |
| Xcode project | `ios/ArenaProtocol.xcodeproj` (Xcode 16+, Swift 6) |
| Package | `ios/Package.swift` (SPM — retained for CI / `swift test`) |
| Tests | Swift Testing framework (`@Suite`, `@Test`) |
| Legacy (archived) | React 18 + Vite + Capacitor 6 — still in `src/` for reference only |

---

## Version History

| Version | Date | Summary |
|---|---|---|
| 1.0.0 | pre-2026 | React/Capacitor hybrid app (`src/App.jsx`, 1971 lines) |
| 2.0.0 | 2026-03-13 | Full native SwiftUI rewrite — 25 Swift files, all features preserved |
| 2.0.1 | 2026-03-16 | Xcode project added, Swift 6 compile fixes, Info.plist crash fix, confirmed on-device |

### v2.0.1 Changes
- `ios/ArenaProtocol.xcodeproj` created — all 19 source files wired, shared schemes, `DEVELOPMENT_TEAM` placeholder
- `SelectView.swift` — fixed Swift 6 `if-let` ternary syntax error in `effectiveDuration`
- `Info.plist` — removed `UIApplicationSceneManifest` block (referenced non-existent `SceneDelegate`, caused launch crash)
- Confirmed build and run on iPhone 17 Pro Max and iOS Simulator

---

## File Map

```
arena-protocol/
├── CONTEXT.md                              ← YOU ARE HERE — paste at session start
├── TESTBENCH_SETUP_WIN11.md                ← Windows 11 build/install guide
├── codemagic.yaml                          ← CI: native-swift-ios + legacy workflows
├── .github/workflows/build-native-ios.yml ← GitHub Actions build
├── ios/
│   ├── ArenaProtocol.xcodeproj/            ← ✅ OPEN THIS IN XCODE
│   │   ├── project.pbxproj                ← project graph (don't hand-edit)
│   │   └── xcshareddata/xcschemes/
│   │       ├── ArenaProtocol.xcscheme     ← run/test scheme
│   │       └── ArenaProtocolTests.xcscheme
│   ├── Package.swift                       ← SPM manifest — do not remove, used by swift test
│   ├── README_XCODE_SETUP.md              ← step-by-step Xcode setup guide
│   ├── ArenaProtocol/
│   │   ├── ArenaProtocolApp.swift          ← @main entry point, WindowGroup
│   │   ├── Models/
│   │   │   └── DataStore.swift            ← ⭐ MOST IMPORTANT — all models, defaults,
│   │   │                                     persistence, gamification helpers
│   │   ├── Views/
│   │   │   ├── RootView.swift             ← ⭐ Screen router + GrainOverlay + Color extensions
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
│   │   │   └── ArenaEditorView.swift      ← Arena CRUD (list + individual editor)
│   │   ├── Components/
│   │   │   ├── ArenaCardView.swift        ← Card UI + Canvas illustrations + AddArenaCardView
│   │   │   ├── CircularTimerView.swift    ← Reusable circular progress timer
│   │   │   ├── AppShortcutsBar.swift      ← 6 app shortcut buttons (deep link + fallback)
│   │   │   └── EmberDropModal.swift       ← Achievement popup overlay
│   │   └── Resources/
│   │       └── Info.plist                 ← Bundle config, URL schemes, dark mode
│   └── Tests/
│       └── ArenaProtocolTests/
│           └── ArenaProtocolTests.swift   ← 30+ unit tests (Swift Testing)
└── src/                                   ← ⛔ LEGACY React source — archived, do not edit
    ├── App.jsx                            ← original 1971-line monolith (reference only)
    └── main.jsx
```

---

## Which Files Matter Going Forward

### Touch regularly
| File | Why |
|---|---|
| `Models/DataStore.swift` | Every new model, persistence key, or gamification rule lives here |
| `Views/RootView.swift` | Adding a new screen requires a new `Screen` case and a route here; Color extensions live here too |
| The relevant `Views/*.swift` | Feature work happens in individual view files |
| `Resources/Info.plist` | Permissions, URL schemes, orientation changes |

### Touch occasionally
| File | Why |
|---|---|
| `ArenaProtocolApp.swift` | Only if adding app-level state or environment objects |
| `Components/*.swift` | Only if modifying shared UI (timer ring, arena card, shortcut bar) |
| `ArenaProtocol.xcodeproj/project.pbxproj` | Only when adding new Swift source files to the project |
| `Package.swift` | Only if adding a Swift Package dependency |

### Do not touch
| File | Why |
|---|---|
| `src/` | Archived React/Capacitor legacy — reference only |
| `.xcodeproj/xcshareddata/xcschemes/*.xcscheme` | Xcode manages these; only edit if changing build config |

---

## Navigation System

Navigation is a `Screen` enum in `RootView.swift` and a `navigate(_ screen: Screen)` closure passed to all views. There is **no NavigationStack** — all routing is a single `switch screen` in `RootView.body`.

```swift
enum Screen: Hashable {
    case home
    case checkin
    case select(Arena)
    case active(Arena, Int, String)         // arena, durationMins, note
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

To add a new screen: add a case here, add a route in `RootView.body`, create the view file, add it to `project.pbxproj`.

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

## Key Data Structures

All defined in `ios/ArenaProtocol/Models/DataStore.swift`.

### Arena
```swift
struct Arena: Identifiable, Codable, Equatable {
    var id: String           // "body" | "spirit" | "tribe" | "craft" | custom uid
    var label: String        // "BODY" (uppercase)
    var letter: String       // "A" "B" "C" "D" — auto-assigned by Arena.reletter()
    var color: String        // hex "#C0392B"
    var subtitle: String     // "move · fuel · rest"
    var description: String
    var icon: String         // single unicode char "◉"
    var examples: [String]
    var subArenas: [String: [String]]  // "MOVE": ["10 min walk", ...]
}
```

### Session
```swift
struct Session: Identifiable, Codable {
    var id: String           // UUID string
    var arenaId: String
    var duration: Int        // minutes
    var date: String         // "yyyy-MM-dd"
    var note: String
    var ts: Double           // epoch ms (Date().timeIntervalSince1970 * 1000)
}
```

### ArenaProtocolModel / ProtocolBlock
```swift
struct ArenaProtocolModel: Identifiable, Codable {
    var id: String; var name: String; var glyph: String
    var color: String; var description: String
    var blocks: [ProtocolBlock]
}
struct ProtocolBlock: Codable, Equatable {
    var arenaId: String; var label: String; var duration: Int; var color: String
}
```

### Habit / HabitLog
```swift
struct Habit: Identifiable, Codable {
    var id: String; var name: String; var goal: String
    var color: String; var createdAt: String
}
struct HabitLog: Codable {
    var habitId: String; var date: String  // "yyyy-MM-dd"
    var value: Bool; var ts: Double
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
| Key | Type |
|---|---|
| `arena_custom_arenas` | `[Arena]` |
| `arena_sessions` | `[Session]` |
| `arena_habits` | `[Habit]` |
| `arena_habit_logs` | `[HabitLog]` |
| `arena_journals` | `[JournalEntry]` |
| `arena_ideas` | `[IdeaNote]` |
| `arena_settings` | `AppSettings` |
| `arena_protocols` | `[ArenaProtocolModel]` |
| `arena_seen_drops` | `[String]` |
| `arena_checkin` | `MorningCheckin` |
| `arena_checkin_dismissed` | `String` — date string, skip checkin if == today |
| `timerEndTime` | `Double` — timer end epoch for background resume |

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

## Known Issues / Active Work

- `SettingsView.swift`: wind-down time initializer reads from `UserDefaults` manually rather than through `DataStore` — minor inconsistency, acceptable for now
- `GrainOverlay` in `RootView.swift`: static noise dots (don't animate between renders) — intentional for performance
- Deep-link URL schemes in `Info.plist` should be verified against current app versions (Spotify, YouTube URLs may have changed)
- No iCloud sync — all data is local to device, not shared across devices
- The `Color.opacity(_:)` extension in `RootView.swift` (line 149) shadows the system method with an identical signature — harmless but worth cleaning up

---

## Up Next (Feature Queue)

1. **Live Activity / Dynamic Island timer** — ActivityKit extension showing active session countdown on lock screen and Dynamic Island (compact + expanded). Target: iPhone 17 Pro Max layout.
2. **WidgetKit extensions** — Lock screen widget (countdown + arena name) and small/medium home screen widget (current arena + start button).
3. **Google Calendar deep integration** — Read the user's calendar blocks for the day, surface them as suggested focus sessions in SelectView. When a calendar block matches an arena (e.g. "gym" → BODY), pre-fill the quest and duration.
4. **Xcode Cloud → TestFlight pipeline** — Trigger on push to main, auto-sign, auto-deploy to TestFlight internal group.
5. **iCloud sync** — Migrate from `UserDefaults` to `NSUbiquitousKeyValueStore` or CloudKit.
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

`Color(hex:)` initialiser and semantic aliases (`Color.background`, `.textPrimary`, `.textMuted`, `.cardBg`, `.cardBorder`) are defined in `RootView.swift`.

---

## Build & Deploy Quick Reference

```bash
# Open in Xcode (device/Simulator builds)
open ios/ArenaProtocol.xcodeproj

# Run logic tests without Xcode (Swift toolchain only)
cd ios && swift test

# Build for simulator via xcodebuild
xcodebuild -project ios/ArenaProtocol.xcodeproj \
  -scheme ArenaProtocol \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO clean build

# Push to trigger cloud build
git push origin main

# Watch GitHub Actions build
gh run list --workflow="build-native-ios.yml" --limit 3
gh run watch <run-id>
```

See `ios/README_XCODE_SETUP.md` for Team ID, device pairing, and first-run steps.

---

## Product Vision

Arena Protocol is one app in a planned suite of lifestyle productivity apps aimed at completely transforming how people manage their time throughout the day. The north star feature is Google Calendar integration synced to live widgets — the user's lock screen and Dynamic Island should always show what they should be focused on right now based on their actual calendar blocks. The app should feel like a mission control for your day, not a timer utility.
