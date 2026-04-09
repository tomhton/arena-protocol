# CONTEXT.md — Arena Protocol
> Paste this at the start of every Claude session. Last updated: 2026-04-09 (v2.33.0).

---

## App Identity

**Name:** Arena Protocol
**One-liner:** A dark-themed iOS life-management app built around timed focus sessions across four life "arenas" (Alignment, Work, Recovery, Movement) with a Social modifier, gamification, habit tracking, and daily rituals.
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

## Development Setup

| Role | Tool |
|---|---|
| Planning + prompting | Claude.ai (web, any device) |
| File edits + git operations | Claude Code (terminal, MacBook) |
| Building + signing + device deploy | Xcode (MacBook) |
| Testing | iPhone 17 Pro Max — OTA via TestFlight or direct from Xcode |

**Workflow rule:** Claude Code pushes require a `git pull` before touching Xcode. Xcode config changes require a `git push` afterward. Claude.ai handles planning and diagnosis only — never touches the repo directly.

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
| 2.9.1 | 2026-03-19 | Bug fixes: STUCK + mandatory Live Activities. Calendar writes use default source, auto-request permission, log errors. Event titles show quest note. |
| 2.9.2 | 2026-03-19 | Bug fix: calendar events write to defaultCalendarForNewEvents (Google Calendar). Dropped custom calendar creation — blocked by CalDAV (EKErrorDomain Code=17). |
| 2.10.0 | 2026-03-19 | Calendar ↔ app full sync: EKEvent ID tracking, update/delete on finishEarly/abandon/joint remove. Interval timers log to calendar. Calendar resume banner in SelectView. Live Activity fixed for joint arenas + stash. |
| 2.11.0 | 2026-03-19 | New arenas (Preparation, Labor, Mental Recovery, Physical Activity). Social modifier on HomeView — tags any session or runs standalone. Customisable protocols (ProtocolEditorView). Social Bool threaded through all navigation. |
| 2.12.0 | 2026-03-19 | Active session banner replaces header + floating pill on HomeView. Arena color flood on background. Pause/resume from banner. `DataStore.togglePause()` added. |
| 2.13.0 | 2026-03-19 | Arena renames: Alignment, Work, Recovery, Movement. Arena icon (◎ ◆ ◑ ◉) now rendered on home screen cards. |
| 2.14.0 | 2026-03-19 | Multi-arena session banner: all stacked sessions shown in top banner. Bug fix: banner no longer reverts to idle on swipe-down stash. Bottom tray removed. |
| 2.15.0 | 2026-03-19 | PRIMARY / JOINT / STACKED event type distinction on HomeView banner, ActiveSessionView breakdown, and Live Activity lock screen + expanded. Per-arena individual timers in banner (primary counts to own end; joints show scheduledEnd countdown or "in Xm"). Color flood tracks currently-running arena. |
| 2.16.0 | 2026-03-19 | Fully live per-arena timers in session banner. 5-second clock drives branch switching (pending → active → done) for all joint rows. Banner accent bar and background animate to currently-running arena color. Primary row shows DONE when joint takes over. |
| 2.17.0 | 2026-03-20 | Timeline-based session banner. `ActiveSessionState` gets `timeline`/`currentSlot`/`nextSlot` backend. Banner label → "CURRENTLY IN". Big row always shows live current arena. Single "UP NEXT" row with live countdown to next arena start. All controls and colors track `currentSlot`. |
| 2.18.0 | 2026-03-20 | Xcode build fix (`PRODUCT_NAME` added to main app target). Live Activity arena identity (`arenaLabel/Color/Icon`) moved to `ContentState` so `Activity.update()` can change displayed arena on transition. |
| 2.19.0 | 2026-03-20 | Live Activity + HomeView banner now update on arena transitions from any screen. `DataStore.syncLiveActivity(now:)` drives updates; HomeView 1 s timer calls it continuously. |
| 2.20.0 | 2026-03-20 | App shortcuts dock: scrollable row of 56 pt rounded-square icons, long-press edit mode (shake + × delete + + add), 20-app curated catalog, custom app form, UserDefaults persistence. |
| 2.21.0 | 2026-03-20 | Home UX rework: unified inline nav buttons, CURRENTLY IN tab with full timeline + clock end times, iOS-style jiggle edit mode for arena grid (no list switch). |
| 2.22.0 | 2026-03-20 | Session intelligence backbone + Forge narrative framework. `SessionIntelligence.swift`: `SessionProfile` (25+ fields), `UserArchetype` (10 cases), `buildSessionProfile()`. `ForgeEngine.swift`: 17 narrative branches, 25 testable queries, `ForgeNarrative → EmberDrop` pipeline. `checkAndClaimEmberDrop()` now runs ForgeEngine first, falls back to legacy drops. `AI_BRAIN_MAP.md` developer reference added. |
| 2.26.0 | 2026-03-24 | Schedule & deadline system. `ScheduledBlock` (future session/protocol + notification) and `ArenaDeadline` (session-count goal with due date + auto-completion) added to DataStore. `ScheduleView` new screen with creation sheets for both types. HomeView "UP NEXT" banner for imminent scheduled blocks. SCHEDULE button in HomeView bottom row. ⏰ button on protocol cards opens `ScheduleProtocolSheet`. |
| 2.27.0 | 2026-03-24 | Arena rank progression system. 8 rank tiers (Dormant → Eternal Flame) based on peak consecutive-day streak per arena. Persistent `ArenaRankState` saved to UserDefaults. Arena cards: vibrant under-glow driven by today's session count, rank-based border progression (gradient borders, animated rotation, corner glows, multi-layer effects at higher tiers). Rank label on cards. Reset option in arena editor. App dock restored below intervals. One-page HomeView overhaul: inline session display, completion overlay, swipe collapse/expand. |
| 2.27.1 | 2026-04-01 | Bug fixes: DONE button crash (force-unwrap on nil `active!` during view removal transition), session start flash (stale `sessionNow` caused 1s uncolored background), social-only arena not opening (lookup missed `socialArena` stored outside main array). Live Activity background transitions: `scheduleLiveActivityTransitions()` uses `performExpiringActivity` to push arena changes while locked; foreground sync on `scenePhase` change; `staleDate` set to current arena end. |
| 2.28.0 | 2026-04-01 | Arena button skins: 10 material skins (Slate→Void, common→legendary) droppable from eggs (40% chance), equippable per arena from inventory. Pure SwiftUI material renderer (Canvas textures + bevel + engrave). Calendar auto-start: bracket-prefixed events trigger session prompts via notifications. Smart CalendarDayView: visibility tiers, 3 layouts, tappable events. HomeView redesign: calendar at top, gold gradient header. |
| 2.29.0 | 2026-04-02 | Live Activity tappable arenas: each upcoming joint arena shown as individual tappable Link in Dynamic Island + lock screen. Retractable checklist system: scoped to session/day/week/month/year, progressive disclosure UX, lock-in commitment mechanic. HomeView: intervals collapse, protocol long-press drag-to-reorder. Removed duplicate CalendarSyncManager.swift. |
| 2.33.0 | 2026-04-09 | SCHEDULE button promoted to full-width colored quick action on HomeView. Scheduled blocks sync to Google Calendar with `[ARENA_LABEL]` format so they appear in CalendarDayView widget. `ScheduledBlock.calEventId` tracks calendar events; removal cleans up calendar. |

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
- `ArenaProtocolWidgetLiveActivity.swift` — arena identity fields (`arenaLabel`, `arenaColor`, `arenaIcon`) moved to `context.state.*` (v2.18.0); `questNote` remains `context.attributes.*`
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
│   │   ├── ArenaProtocolApp.swift          ← @main entry point, WindowGroup, TipKit config
│   │   ├── ArenaAppIntents.swift           ← App Intents for Siri/Shortcuts (StartArena, AddChecklistTask)
│   │   ├── ArenaTips.swift                 ← TipKit tips (ProtocolReorder, ChecklistTab, SiriShortcuts)
│   │   ├── Models/
│   │   │   └── DataStore.swift            ← ⭐ MOST IMPORTANT — all models, defaults,
│   │   │                                      persistence, gamification helpers
│   │   ├── Views/
│   │   │   ├── RootView.swift             ← ⭐ Screen router + GrainOverlay + Color extensions + onOpenURL deeplink handler
│   │   │   ├── HomeView.swift             ← Dashboard hub (decomposed): session display, overlays, quick actions, tools, footer
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
│   │   │   ├── ScheduleView.swift         ← Schedule blocks + deadlines management
│   │   │   └── ArenaEditorView.swift      ← Arena CRUD (list + individual editor)
│   │   ├── Components/
│   │   │   ├── ArenaCardView.swift        ← Card UI + rank borders + under-glow + skin material + Canvas illustrations + AddArenaCardView
│   │   │   ├── SkinMaterialView.swift    ← Pure SwiftUI material renderer (10 textures + bevel + engrave modifier)
│   │   │   ├── CircularTimerView.swift    ← Reusable circular progress timer
│   │   │   ├── AppShortcutsBar.swift      ← Infinite wrap-around carousel dock (3× tripled items, ScrollViewReader reset, CURATED_DOCK_APPS 20 apps, edit mode, picker sheet, DockApp struct)
│   │   │   ├── EmberDropModal.swift       ← Achievement popup overlay
│   │   │   ├── CalendarDayView.swift      ← Calendar day strip on HomeView
│   │   │   ├── CompletionOverlay.swift    ← Session completion overlay
│   │   │   ├── FlowLayout.swift           ← Flow layout helper
│   │   │   ├── InlineSessionConfig.swift  ← Expanded arena card session config
│   │   │   ├── SessionDisplayView.swift   ← Inline session display for HomeView (progress bar, interactive timeline bubbles, JointEntryEditSheet)
│   │   │   ├── ForgeDropModal.swift       ← Forge narrative drop modal
│   │   │   ├── ChecklistPanelView.swift   ← Retractable checklist panel (scoped: session/day/week/month/year)
│   │   │   ├── HomeHeaderView.swift       ← Header section (date + rotating quote + subtitle row)
│   │   │   ├── ProtocolsInlineView.swift  ← Horizontal protocol cards + drag-to-reorder (simultaneousGesture fix)
│   │   │   ├── ArenaGridView.swift        ← Edit toggle + 2-column arena grid (incl. social arena as last card) + reorder list
│   │   │   └── ChecklistTabView.swift     ← Persistent bottom-left checklist sliding panel + tab
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
    case select(Arena, Bool)                // arena, social modifier
    case active(Arena, Int, String, Bool)   // arena, durationMins, note, social
    case complete(Arena, Int, String, Bool)
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
    case whatsNew
    case inventory
    case profile
    case schedule
}
```

To add a new screen: add a case here, add a route in `RootView.body`, create the view file, add it to `project.pbxproj`.

The app handles deep links via `.onOpenURL` in `RootView.swift`:
- `arenaprotocol://active` — pops to home and expands session display (from Dynamic Island/lock screen tap)
- `arenaprotocol://arena/{id}` — pops to home and expands that arena's card (from Live Activity tappable arena entries)

---

## Screen Inventory

| Screen | File | What it does |
|---|---|---|
| **Home** | `HomeView.swift` | Single-page hub (decomposed): inline session display (swipe collapse/expand), expanded arena overlay, completion overlay, forge/ember modals. Sections extracted to components: `HomeHeaderView`, `ArenaGridView`, `ProtocolsInlineView`, `IntervalsSectionView`, `ChecklistTabView`. Also contains: calendar day view, quick actions, quick tools, egg strip, app shortcuts dock, footer. Social arena now appears as last card in the arena grid. |
| **Morning Check-in** | `MorningCheckinView.swift` | 3-step ritual (Reading 5m, Goals 5m, Movement 5m), animated progress bar, skip option. Shows once per day. |
| **Select** | `SelectView.swift` | Arena detail + quest note textarea, sub-arena pills → example task list, duration picker (5/10/30/60/90/custom), Google Calendar option, launches session |
| **Active Session** | `ActiveSessionView.swift` | Live countdown ring, arena name, quest note, focus hint, pause/resume, done/abandon. Minimize button (chevron.down, top-trailing) returns to Home while keeping session alive in `store.activeSession`. Resumes from stored state on re-entry. Manages Live Activity lifecycle (start on session begin, update on pause/resume, end on done/abandon). Tapping the Dynamic Island or lock screen banner deep-links to this screen via `arenaprotocol://active`. |
| **Complete** | `ActiveSessionView.swift` (CompleteView) | Session complete screen with icon pop animation, saves session, triggers ember drop check |
| **Protocols** | `ProtocolsView.swift` | List of protocols with block strips, edit, BEGIN → button, ⏰ schedule button per card |
| **Active Protocol** | `ProtocolsView.swift` (ActiveProtocolView) | Segmented multi-block timer, advances blocks automatically, overall + per-block progress |
| **History** | `HistoryView.swift` | Stats cards (sessions/minutes/days), CSV/JSON export, 4 tabs: Chart (7-day bar + arena breakdown), Habits (70-day grid), Log (reverse session list), Journal |
| **Notes** | `NotesView.swift` | TextEditor + add button, timestamped idea list, delete per item |
| **Wind Down** | `WindDownView.swift` | Step-through: journal entry → yes/no for each habit, saves logs, step progress bar |
| **Habit Manager** | `HabitManagerView.swift` | List habits, CRUD editor (name, goal, color picker) |
| **Settings** | `SettingsView.swift` | Wind-down time DatePicker (wheel), nav to Manage Habits + Manage Arenas |
| **Arena List Editor** | `ArenaEditorView.swift` (ArenaListEditorView) | 2-col grid in edit mode, + NEW card |
| **Arena Editor** | `ArenaEditorView.swift` (ArenaEditorView) | Full form: name, subtitle, icon grid, color circles, description, examples textarea, save/delete |
| **Stuck** | `StuckView.swift` | 3 phases: config (duration + optional intention) → countdown ring → mandatory arena pick |
| **Schedule** | `ScheduleView.swift` | Upcoming scheduled blocks (arena/protocol + time + START), active deadlines (progress bar, days left, overdue), completed deadlines. Sheets: AddScheduledBlockSheet, AddDeadlineSheet. |

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

### ScheduledBlock
```swift
struct ScheduledBlock: Identifiable, Codable {
    var id: String              // UUID
    var kind: ScheduledKind     // .arena | .arenaProtocol
    var itemId: String          // arenaId or protocolId
    var itemLabel: String       // cached display name
    var itemGlyph: String       // cached icon/glyph
    var itemColor: String       // cached hex color
    var scheduledAt: Date
    var durationMins: Int       // arena: user-specified; protocol: sum of blocks
    var note: String
    var notificationId: String? // set after notification is scheduled
    var calEventId: String?     // Google Calendar event identifier
}
// Persisted: "arena_schedule"
```

### ArenaDeadline
```swift
struct ArenaDeadline: Identifiable, Codable {
    var id: String
    var arenaId: String
    var arenaLabel: String      // cached
    var arenaColor: String      // cached hex
    var targetDate: Date
    var targetSessions: Int     // complete this many sessions by targetDate
    var note: String
    var isCompleted: Bool       // auto-set when count reaches target
}
// Persisted: "arena_deadlines"
```

### ActiveSessionState (transient — not Codable, not persisted)
```swift
struct ActiveSessionState {
    var arena: Arena
    var durationMins: Int
    var note: String
    var startTime: Date          // recorded at session start
    var endTime: Date            // total session end (primary + all joints)
    var isPaused: Bool = false
    var pausedRemaining: TimeInterval = 0
    var jointArenas: [Arena] = []            // legacy — use jointEntries
    var jointEntries: [JointArenaEntry] = [] // typed joint arenas with scheduling
    var calEventId: String? = nil
    var social: Bool = false
}

struct JointArenaEntry: Identifiable {
    let id: UUID
    let arena: Arena
    let minutes: Int
    var calEventId: String? = nil
    var scheduledStart: Date  // = previous arena's end time
    var scheduledEnd: Date    // = scheduledStart + minutes * 60
}
```
`DataStore` also holds `stackedSessions: [ActiveSessionState]` — arenas stashed via swipe-down.

**Three running arena types:**
- **PRIMARY** — `store.activeSession.arena` — foreground timer
- **JOINT** — `store.activeSession.jointEntries` — queued arenas with individual `scheduledStart`/`scheduledEnd`
- **STACKED** — `store.stackedSessions` — independently-running sessions minimized via swipe-down

**Timeline helpers (extension on `ActiveSessionState`):**
```swift
// Ordered slots: primary first, then each joint in sequence
var timeline: [(arena: Arena, start: Date, end: Date)]

// Slot where start ≤ now < end — nil if between slots or complete
func currentSlot(now: Date = Date()) -> (arena: Arena, start: Date, end: Date)?

// Slot immediately after current, or first upcoming if none active
func nextSlot(now: Date = Date()) -> (arena: Arena, start: Date, end: Date)?
```
Use these everywhere you need "what is running now" or "what starts next". Never manually walk `jointEntries` to determine the current arena.

### ArenaLiveActivityAttributes (ActivityKit — shared by app + widget extension)
```swift
struct ArenaLiveActivityAttributes: ActivityAttributes, Sendable {
    // Static (set once at Activity.request — never changes during session)
    let arenaId: String
    let questNote: String
    let startTime: Date

    static let appGroupID = "group.arena.protocol"

    // Dynamic (updated via Activity.update on pause/resume/joint add/arena transition)
    struct ContentState: Codable, Hashable, Sendable {
        var endTime: Date
        var isPaused: Bool
        var pausedRemaining: TimeInterval
        var isIdle: Bool = false
        var isMandatory: Bool = false
        var jointCount: Int = 0
        var arenaLabel: String = ""
        var arenaColor: String = "#E8C547"
        var arenaIcon: String = "◉"
        var currentArenaStart: Date = Date()
        var sessionEndTime: Date = Date()
        var nextArenaLabel: String = ""
        var nextArenaIcon: String = ""
        var upcomingArenas: [UpcomingArena] = []  // tappable arena entries for DI/lock screen
    }
}

struct UpcomingArena: Codable, Hashable, Sendable {
    var id: String; var label: String; var icon: String; var color: String
}
```
**IMPORTANT:** `arenaLabel`, `arenaColor`, `arenaIcon` are in `ContentState` (not static attributes) so `Activity.update()` can change the displayed arena when a joint takes over. All widget/lock-screen rendering reads `context.state.arenaLabel/Color/Icon`.
Defined in `ArenaProtocol/ArenaLiveActivityAttributes.swift` — compiled into **both** the main app target and the widget extension target.

### ArenaRankState (per-arena rank progression)
```swift
enum ArenaRankTier: Int, Codable, CaseIterable, Comparable {
    case dormant = 0       // 0 streak
    case sparked = 1       // 1–2 days
    case kindling = 2      // 3–6 days
    case burning = 3       // 7–13 days
    case blazing = 4       // 14–20 days
    case inferno = 5       // 21–33 days
    case transcendent = 6  // 34–49 days
    case eternalFlame = 7  // 50+ days
}

struct ArenaRankState: Codable, Identifiable {
    var id: String { arenaId }
    var arenaId: String
    var peakStreak: Int              // highest streak ever achieved
    var achievedRank: ArenaRankTier  // locked-in rank from peak streak (high-water mark)
    var achievedAt: Double           // epoch ms when current rank was reached
}
```
Ranks are permanent — once earned via peak streak, they persist even after the streak breaks. `resetArenaRank(arenaId:)` resets to dormant (prestige integration point). Persisted to `"arena_ranks"`.

### ButtonSkin (arena card material skins)
```swift
struct ButtonSkin: Identifiable, Codable {
    let id: String          // "slate", "obsidian", etc.
    let name: String        // "SLATE"
    let material: String    // rendering key for SkinMaterialView
    let rarity: EggRarity
    let description: String
    let glyph: String       // "▬", "◆", etc.
}
```
`SKIN_CATALOG` (10 skins in `DataStore.swift`): Slate & Leather (common), Obsidian & Bronze (uncommon), Marble & Ironwood (rare), Volcanic & Frosted Glass (epic), Celestial & Void (legendary).

Skins are `InventoryItem` with `type: .skin`. `PlayerProfile.equippedSkins: [String: String]` maps arenaId → skinName. One skin can be equipped to one arena at a time. `equipSkin(_:to:)` / `unequipSkin(from:)` / `equippedSkin(for:)` in DataStore.

Egg hatching has 40% chance to drop a skin (if available for that rarity and not already owned). Rendering: `SkinMaterialView` replaces `ArenaCardView.cardBackground` when a skin is equipped; text gets `.engraved()` modifier.

Visual effects per rank: border width/opacity scales up, corner glow accents from kindling+, angular gradient borders from burning+, animated rotation from transcendent+, triple-layer ornate borders at eternalFlame. Today's session count drives a separate under-glow intensity (0 sessions = none, 4+ = full vibrant glow with pulse).

### DockApp
```swift
struct DockApp: Identifiable, Codable {
    var id: String          // curated id ("spotify") or "custom_<uuid-prefix>" for custom entries
    var name: String        // display name
    var urlScheme: String   // e.g. "spotify://"
    var sfSymbol: String    // SF Symbol name
    var brandColor: String  // hex color
}
```
`CURATED_DOCK_APPS` (20 apps, in `AppShortcutsBar.swift`) is the picker catalog.
`DEFAULT_DOCK_APPS` (6 apps, in `DataStore.swift`) is the factory default dock.
`store.dockApps` is the user's live dock — persisted to `arena_dock_apps` in UserDefaults.

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
    var dockApps:      [DockApp]          // persisted to arena_dock_apps; default = 6 apps
    var settings:      AppSettings        // { windDownTime: "21:30" }
    var protocols:     [ArenaProtocolModel]
    var seenDrops:     [String]           // ember drop ids already shown
    var checkin:       MorningCheckin     // { date, completed: [habitId] }
    var arenaRanks:    [ArenaRankState]     // persisted to arena_ranks; peak-streak rank progression
    var checklists:    [Checklist]        // persisted to arena_checklists; scoped task lists
    var activeSession: ActiveSessionState? = nil    // transient — nil when no session running
    var stackedSessions: [ActiveSessionState] = [] // minimized sessions
    var liveArenaId: String = ""  // last arena id pushed to Live Activity; guards syncLiveActivity

    // Computed
    var letteredArenas: [Arena]       // auto-assigns A/B/C/D letters
    var todaySessions: Int

    // Session lifecycle
    func startSession(arena: Arena, durationMins: Int, note: String, social: Bool)
    func endSession()
    func togglePause()               // flips isPaused, recalculates endTime
    func stashSession()              // moves activeSession → stackedSessions
    func unstashSession(arenaId: String)  // pops from stackedSessions → activeSession
    func abandonStackedSession(arenaId: String)

    // Live Activity — called by HomeView's 1 s timer; also by ActiveSessionView on transitions
    func syncLiveActivity(now: Date = Date())
    // Compares currentSlot().arena.id to liveArenaId; if changed, builds ContentState
    // from activeSession (or stackedSessions.first) and pushes to Activity.activities.
    // No-op if arena hasn't changed. Guarded by #if canImport(ActivityKit).
    // IMPORTANT: HomeView is the always-running root view and drives this every second.
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
| `arena_dock_apps` | `[DockApp]` |
| `arena_settings` | `AppSettings` |
| `arena_protocols` | `[ArenaProtocolModel]` |
| `arena_seen_drops` | `[String]` |
| `arena_checkin` | `MorningCheckin` |
| `arena_ranks` | `[ArenaRankState]` |
| `arena_checklists` | `[Checklist]` |
| `arena_checkin_dismissed` | `String` — date string, skip checkin if == today |
| `arena_cal_processed` | `[String: Double]` — processed calendar event IDs for dedup |
| `timerEndTime` | `Double` — timer end epoch for background resume |

### App Group Keys (group.arena.protocol)
| Key | Type |
|---|---|
| `arena_widget_state` | `WidgetState` |
| `arena_sessions` | `[SessionStub]` — for widget session count |
| `arena_shared_arenas` | `[SharedArena]` — arena list for Shortcuts/Control Center |
| `arena_pending_intent` | `PendingArenaIntent` — Shortcut → app session start |
| `arena_pending_task` | `String` — Shortcut → app checklist task |

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
2. **Xcode Cloud → TestFlight pipeline** — Auto-sign, auto-deploy on push to main.
3. **iCloud sync** — Migrate from `UserDefaults` to CloudKit.

✅ **Completed:** Live Activity / Dynamic Island (v2.0.3–2.0.5) — compact circle clock, lock screen banner, expanded layout, tap deeplink, pause/resume, stash & stack sessions, WidgetKit home screen widgets, keyboard fix.
✅ **Completed:** Google Calendar integration (v2.28.0) — bracket-prefixed auto-start, smart CalendarDayView, tappable events.
✅ **Completed:** Forge System (v2.22.0–v2.28.0) — SessionIntelligence, ForgeEngine (17 narratives), InventoryView, egg incubation, arena button skins (10 materials, equippable per arena).

---

## Color Palette Reference

| Arena | Hex | Usage |
|---|---|---|
| Alignment | `#60A5FA` | Blue — plan/research |
| Work | `#E8C547` | Yellow — execute/build |
| Recovery | `#A78BFA` | Purple — rest/reflect |
| Movement | `#34D399` | Green — physical |
| Social | `#B794F4` | Purple — social modifier |
| Accent yellow | `#E8C547` | Primary CTA, morning, idle |
| Accent purple | `#B794F4` | Wind-down, history |
| Accent pink | `#FF8FA3` | Stuck protocol, mandatory |
| Accent teal | `#4ECDC4` | Intervals |
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
