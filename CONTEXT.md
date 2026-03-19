# CONTEXT.md — Arena Protocol
> Paste this at the start of every Claude session. Last updated: 2026-03-19 (v2.9.0).

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
| 2.0.2 | 2026-03-16 | `ActiveSessionState` added to DataStore; minimize-to-pill UX; session survives navigation |
| 2.0.3 | 2026-03-16 | Live Activity fully working on device — Dynamic Island compact/expanded, lock screen banner, tap deeplink. Fixed deployment target, GENERATE_INFOPLIST, CFBundleName, SharedStore crash, fresh-start gate. Debug test code cleaned up. |
| 2.0.4 | 2026-03-17 | Live Activity regression fix — widget was using wrong attributes type (black Island). Compact slot sizing. Expanded layout polish. |
| 2.0.5 | 2026-03-17 | Forge system foundation. Dynamic Island circle clock. Lock screen redesign. Home screen widgets rebuilt. Stash & stack sessions. Keyboard fix. |
| 2.1.0 | 2026-03-17 | Full SwiftUI navigation reform. `NavigationStack` replaces ZStack+switch. Native iOS transitions. All scroll issues resolved. |
| 2.1.1 | 2026-03-17 | Swipe-back restored via UINavigationController extension. Dynamic Island compact ring now shows live countdown number. |
| 2.2.0 | 2026-03-17 | Joint arenas (+ button, gradient ring, multi-session log). Drag-to-reorder arena grid. Color wheel in arena editor. |
| 2.3.0 | 2026-03-17 | Multi-timer brainwork redesign. Arena breakdown card with proportional bars. Mindless/interval periods row on HomeView. `IntervalTimerView` screen. |
| 2.3.1 | 2026-03-17 | State persistence: joint arenas survive navigation; arena editor auto-saves on swipe-back. |
| 2.4.0 | 2026-03-17 | New default arenas (Alignment & Planning, Execution & Mastery, Health & Recovery, Connection & Community). Arena editor: free-text/emoji icon input, expanded icon grid, sub-arenas category editor. |
| 2.5.0 | 2026-03-17 | EventKit calendar integration + end time on all timers. |
| 2.6.0 | 2026-03-17 | Google Calendar read feed. NEXT BLOCK banner on home. FROM YOUR CALENDAR in SelectView. |
| 2.7.0 | 2026-03-18 | Idle Live Activity (ENTER THE ARENA on lock screen). In-app What's New changelog. Long-press arena → edit mode + drag-to-reorder on HomeView. |
| 2.8.0 | 2026-03-18 | Bug fixes: idle Live Activity no longer shows 24hr countdown. Long-press edit mode fixed (simultaneousGesture). Drag-to-reorder replaced with List + .onMove in edit mode. |
| 2.8.1 | 2026-03-18 | Bug fix: deleted arena no longer reappears (onDisappear persist() re-insertion). |
| 2.9.0 | 2026-03-19 | Protocol Live Activity: each block drives lock screen + Dynamic Island. In-app changelog synced to v2.9.0. README rewritten. |

### v2.0.5 Changes
- `FORGE_SYSTEM_ROADMAP.md` — full progression spec: streak tiers, egg incubation (5 rarities), Rebirth Island 1–10, inventory screen layout, 4-phase multiplayer plan, Swift data model definitions, build order
- `DataStore.swift` — `stackedSessions: [ActiveSessionState]` + `stashSession()` / `unstashSession(arenaId:)` / `abandonStackedSession(arenaId:)`; `ActiveSessionState` gains `startTime: Date`
- `ArenaLiveActivityAttributes.swift` — `startTime: Date` added to static attributes
- `ArenaProtocolWidgetLiveActivity.swift` — compact leading uses `ProgressView(timerInterval:)` circular ring with arena icon; minimal slot uses ring only; lock screen banner redesigned with 40pt circular progress replacing plain icon
- `ArenaProtocolWidget.swift` — full rewrite: real `SmallWidgetView` + `MediumWidgetView`; smart timeline refresh; deep links to active session or home
- `ActiveSessionView.swift` — `import WidgetKit`; `SharedStore.writeActiveSession` + `WidgetCenter.reloadAllTimelines()` on start/end; swipe-down gesture stashes session; `stashSession()` function; "↓ swipe to stack" hint
- `HomeView.swift` — "ENTER THE ARENA" enlarged to 28pt, removed broken navigate(.home); session tray handles foreground + stacked pills; EGG BONUS ACTIVE badge when ≥2 arenas stacked
- `SelectView.swift` — keyboard trap fixed: `@FocusState` + toolbar DONE button + `scrollDismissesKeyboard(.interactively)`

### v2.0.4 Changes
- `ArenaProtocolWidgetLiveActivity.swift` — removed inline `ArenaActivityAttributes` (wrong type — caused black Dynamic Island); now uses shared `ArenaLiveActivityAttributes`
- `ArenaProtocolWidgetLiveActivity.swift` — static fields (`arenaLabel`, `arenaColor`, `arenaIcon`, `questNote`) moved to `context.attributes.*`; dynamic fields (`endTime`, `isPaused`) remain `context.state.*`
- `ArenaProtocolWidgetLiveActivity.swift` — compact leading fixed to `frame(width: 20, height: 20)`; compact trailing capped at `frame(maxWidth: 60)`
- `ArenaProtocolWidgetLiveActivity.swift` — expanded regions use `frame(maxWidth: .infinity, alignment:)` with consistent `padding(.horizontal, 12).padding(.vertical, 8)`

### v2.0.3 Changes
- `ActiveSessionView.swift` — added fresh-start gate; on minimize return, reattaches to existing Activity via `Activity.activities.first` instead of requesting a new one
- `project.pbxproj` — widget extension `IPHONEOS_DEPLOYMENT_TARGET` fixed from `26.2` → `18.6`
- `project.pbxproj` — widget extension `GENERATE_INFOPLIST_FILE` fixed from `YES` → `NO`
- `project.pbxproj` — widget extension `SWIFT_VERSION` fixed from `5.0` → `6.0`
- `SharedStore.swift` — removed force unwrap on `UserDefaults(suiteName:)!` → `?? .standard`
- `ArenaProtocolWidget.swift` — removed force unwrap on `Calendar.current.date(...)!` → `?? currentDate`
- `ArenaProtocolWidgetLiveActivity.swift` — `activityBackgroundTint` changed to `Color.clear`
- `ArenaProtocolWidgetLiveActivity.swift` — added `widgetURL` for tap deeplink (`arenaprotocol://active`)
- `ArenaProtocolWidgetLiveActivity.swift` — debug test code removed; all layouts restored to production (compact leading: arena icon in arena color; compact trailing: countdown timer or PAUSED in arena color; lock screen banner: colored left strip + arena icon + label + quest note + timer/PAUSED)
- `RootView.swift` — added `onOpenURL` handler routing `arenaprotocol://active` to active session screen
- `ArenaProtocolWidget/Info.plist` — added `CFBundleName` and `CFBundleInfoDictionaryVersion`

### v2.0.2 Changes
- `DataStore.swift` — added `ActiveSessionState` struct (transient, not Codable): `arena`, `durationMins`, `note`, `endTime`, `isPaused`, `pausedRemaining`
- `DataStore.swift` — added `var activeSession: ActiveSessionState? = nil`, `startSession(arena:durationMins:note:)`, and `endSession()`
- `ActiveSessionView.swift` — `.onAppear` resumes from stored `endTime`/`pausedRemaining` if session already exists; `togglePause()` syncs state back to `store.activeSession`; `endSession()` called on expiry, DONE, and ABANDON (not on minimize); minimize button (`chevron.down`, top-trailing) navigates `.home` while leaving `store.activeSession` intact
- `HomeView.swift` — floating timer pill (280×56pt capsule, bottom-center) appears when `store.activeSession != nil`; shows arena color dot + label + live `Text(endTime, style: .timer)`; tap returns to session; ✕ button shows `confirmationDialog` → `store.endSession()`; animates in/out with spring transition

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
├── CHANGELOG.md                            ← versioned change log
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
│   │   │   ├── RootView.swift             ← ⭐ Screen router + GrainOverlay + Color extensions + onOpenURL deeplink handler
│   │   │   ├── HomeView.swift             ← Dashboard: arena grid, shortcuts, ember particles, timer pill
│   │   │   ├── SelectView.swift           ← Session config: quest, sub-arena, duration
│   │   │   ├── ActiveSessionView.swift    ← Live timer + minimize + CompleteView + Live Activity management
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
│   ├── ArenaProtocolWidget/               ← Widget + Live Activity extension target
│   │   ├── ArenaProtocolWidget.swift      ← WidgetKit placeholder (home screen widget — next up)
│   │   ├── ArenaProtocolWidgetLiveActivity.swift ← ✅ Live Activity: Dynamic Island + lock screen
│   │   ├── SharedStore.swift              ← App Group UserDefaults bridge (suite name shared with main app)
│   │   └── Info.plist                    ← Widget extension bundle config (CFBundleName required)
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
| `ArenaProtocolWidget/ArenaProtocolWidgetLiveActivity.swift` | Live Activity layout changes |
| `ArenaProtocolWidget/SharedStore.swift` | App Group data bridge for widgets |

### Do not touch
| File | Why |
|---|---|
| `src/` | Archived React/Capacitor legacy — reference only |
| `.xcodeproj/xcshareddata/xcschemes/*.xcscheme` | Xcode manages these; only edit if changing build config |

---

## Navigation System

Navigation uses `NavigationStack(path: $path)` in `RootView.swift`. A `navigate(_ screen: Screen)` closure is passed to all views.

- `navigate(.home)` → `path = NavigationPath()` — pops to root (HomeView)
- `navigate(.anyOtherScreen)` → `path.append(screen)` — pushes with native iOS slide transition
- Built-in edge-swipe-back on all screens (no custom gesture code)
- `.active` and `.complete` screens have `.navigationBarBackButtonHidden(true)` — no accidental pop during a timer
- Checkin screen: pre-pushed onto initial path if not dismissed today
- `ArenaEditorView` uses `@Environment(\.dismiss)` instead of `navigate` (no forward nav needed)

```swift
enum Screen: Hashable {
    case home       // sentinel — navigate(.home) pops to root, never pushed
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

The app also handles the `arenaprotocol://active` deep link via `.onOpenURL` in `RootView.swift`, which routes to the active session screen when tapped from the Dynamic Island or lock screen Live Activity.

---

## Screen Inventory

| Screen | File | What it does |
|---|---|---|
| **Home** | `HomeView.swift` | 2-column arena grid, header with title/streak count, edit toggle, app shortcuts bar, Protocols + I AM STUCK buttons, morning/wind-down footer nav. Floating timer pill (bottom-center capsule) appears when `store.activeSession != nil` — tap to return to session, ✕ to abandon. |
| **Morning Check-in** | `MorningCheckinView.swift` | 3-step ritual (Reading 5m, Goals 5m, Movement 5m), animated progress bar, skip option. Shows once per day. |
| **Select** | `SelectView.swift` | Arena detail + quest note textarea, sub-arena pills → example task list, duration picker (5/10/30/60/90/custom), Google Calendar option, launches session |
| **Active Session** | `ActiveSessionView.swift` | Live countdown ring, arena name, quest note, focus hint, pause/resume, done/abandon. Minimize button (chevron.down, top-trailing) returns to Home while keeping session alive in `store.activeSession`. Resumes from stored state on re-entry. Manages Live Activity lifecycle (start on session begin, update on pause/resume, end on done/abandon). Tapping the Dynamic Island or lock screen banner deep-links to this screen via `arenaprotocol://active`. |
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

### ActiveSessionState (transient — not Codable, not persisted)
```swift
struct ActiveSessionState {
    var arena: Arena
    var durationMins: Int
    var note: String
    var startTime: Date          // recorded at session start — used for progress ring + Forge drop timing
    var endTime: Date
    var isPaused: Bool = false
    var pausedRemaining: TimeInterval = 0
}
```
`DataStore` also holds `stackedSessions: [ActiveSessionState]` — arenas stashed via swipe-down. Multiple stacked arenas activate an EGG BONUS multiplier in the Forge System.

### ArenaLiveActivityAttributes (ActivityKit — shared by app + widget extension)
```swift
struct ArenaLiveActivityAttributes: ActivityAttributes, Sendable {
    // Static (set once at Activity.request — never changes during session)
    let arenaId: String
    let arenaLabel: String
    let arenaColor: String      // hex e.g. "#C0392B"
    let arenaIcon: String       // single unicode char e.g. "◉"
    let questNote: String

    static let appGroupID = "group.arena.protocol"

    // Dynamic (updated via Activity.update on pause/resume)
    struct ContentState: Codable, Hashable, Sendable {
        var endTime: Date
        var isPaused: Bool
        var pausedRemaining: TimeInterval
    }
}
```
Defined in `ArenaProtocol/ArenaLiveActivityAttributes.swift` — compiled into **both** the main app target and the widget extension target.

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
    var arenas:        [Arena]
    var sessions:      [Session]
    var habits:        [Habit]
    var habitLogs:     [HabitLog]
    var journals:      [JournalEntry]
    var ideas:         [IdeaNote]
    var settings:      AppSettings        // { windDownTime: "21:30" }
    var protocols:     [ArenaProtocolModel]
    var seenDrops:     [String]           // ember drop ids already shown
    var checkin:       MorningCheckin     // { date, completed: [habitId] }
    var activeSession: ActiveSessionState? = nil  // transient — nil when no session running

    // Computed
    var letteredArenas: [Arena]       // auto-assigns A/B/C/D letters
    var todaySessions: Int

    // Session lifecycle
    func startSession(arena: Arena, durationMins: Int, note: String)  // sets activeSession
    func endSession()                                                   // sets activeSession = nil
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
- `HomeView.swift`: timer pill uses `Text(endTime, style: .timer)` — counts up after `endTime` passes; ensure `store.endSession()` is called before natural expiry reaches zero to avoid negative display
- `ArenaProtocolWidgetLiveActivity.swift`: `Color(hex:)` helper is duplicated from `RootView.swift` because widget extensions don't share the main app module — intentional, keep in sync if palette changes

---

## Up Next (Feature Queue)

1. **App redirects** — URL scheme deep links for every screen (`arenaprotocol://select?arena=body`, `arenaprotocol://history`, etc.). Expose as Shortcuts actions.
2. **Google Calendar feed** — Read user's calendar blocks via EventKit / Google Calendar API; surface current/next block as suggested arena + duration in SelectView. North star feature.
3. **Forge System — DataStore models** — Add `InventoryEgg`, `InventoryItem`, `RebirthState`, `PlayerProfile` to DataStore. Full spec in `FORGE_SYSTEM_ROADMAP.md`.
4. **Forge System — Drop engine** — Expand `checkAndClaimEmberDrop` into a `ForgeEngine` evaluating streak tiers, milestones, stacked-arena bonuses.
5. **Forge System — InventoryView** — Incubating eggs, hatched items, "WHAT IS POSSIBLE" locked preview.
6. **Xcode Cloud → TestFlight pipeline** — Auto-sign, auto-deploy on push to main.
7. **iCloud sync** — Migrate from `UserDefaults` to CloudKit.

✅ **Completed:** Live Activity / Dynamic Island (v2.0.3–2.0.5) — compact circle clock, lock screen banner, expanded layout, tap deeplink, pause/resume, stash & stack sessions, WidgetKit home screen widgets, keyboard fix.

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

`Color(hex:)` initialiser and semantic aliases (`Color.background`, `.textPrimary`, `.textMuted`, `.cardBg`, `.cardBorder`) are defined in `RootView.swift`. A duplicate `Color(hex:)` helper exists in `ArenaProtocolWidgetLiveActivity.swift` for widget extension scope.

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

> **Note:** Live Activity / Dynamic Island requires a physical device — iOS Simulator does not support Live Activities. Always test widget changes on device.

---

## Product Vision

Arena Protocol is one app in a planned suite of lifestyle productivity apps aimed at completely transforming how people manage their time throughout the day. The north star feature is Google Calendar integration synced to live widgets — the user's lock screen and Dynamic Island should always show what they should be focused on right now based on their actual calendar blocks. The app should feel like a mission control for your day, not a timer utility.
