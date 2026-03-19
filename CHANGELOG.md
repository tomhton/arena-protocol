# CHANGELOG — Arena Protocol

All meaningful changes to Arena Protocol are documented here.
Format: version — date — summary. Most recent version first.

---

## v2.7.0 — 2026-03-18

**Idle Live Activity · In-app changelog · Long-press edit mode.**

### Features
- **Idle Live Activity** — lock screen and Dynamic Island show "START THE DAY", "ENTER THE ARENA", "LOCK IN", or "CLOSE THE DAY" (time-aware) when no session is running. Activity starts automatically when HomeView appears, ends when a session starts, restarts when done.
- **What's New screen** — in-app changelog accessible from Settings → WHAT'S NEW. Shows recent version entries with headline and bullet points. Built from a hardcoded struct array (no file read required).
- **Long-press → edit mode** — long-pressing any arena card on HomeView enters edit mode with haptic feedback (replaces the need to find the EDIT ARENAS toggle). Drag-to-reorder now works directly on HomeView (previously only in ArenaListEditorView). Cards scale slightly when in edit mode for visual feedback.

### Internal
- `ArenaLiveActivityAttributes.ContentState` — added `isIdle: Bool` field
- `DataStore.swift` — `startIdleActivity()` / `endIdleActivity()` using ActivityKit
- `ArenaProtocolWidgetLiveActivity.swift` — idle branch in LockScreenBannerView, CompactLeadingView, CompactTrailingView
- `HomeView.swift` — `moveArena()` + drag-to-reorder on both grid columns; idle activity on appear
- `RootView.swift` — `Screen.whatsNew` case
- `WhatsNewView.swift` — new file

---

## v2.4.0 — 2026-03-17

**New default arenas. Expanded arena editor.**

### Features
- **New default arenas** — Alignment & Planning (blue `#60A5FA`, ◎), Execution & Mastery (gold `#E8C547`, ◆), Health & Recovery (green `#34D399`, ◉), Connection & Community (purple `#B794F4`, ◇). Each has curated subtitles, descriptions, examples, and sub-arena categories.
- **Free-text icon input** — arena editor now has a text field above the icon grid; type any emoji or Unicode character as the arena icon. CLEAR button reverts to grid selection.
- **Expanded icon grid** — `ARENA_ICONS` extended with emoji rows for focus/work, health, connection, and misc (32 → 50 icons).
- **Sub-arenas editor** — add/remove/rename sub-arena categories inline in the arena editor. Each category row expands to reveal an examples text field. Changes persist to `subArenas: [String: [String]]` on save.

---

## v2.3.1 — 2026-03-17

**State persistence across navigation.**

### Bug Fixes
- `ActiveSessionView` — joint arenas survive swipe-out and back: `addJoint`/`removeJoint` sync `jointEntries` + `endTime` to `store.activeSession`; `setup()` restores them on re-entry
- `ArenaEditorView` — swipe-back now auto-saves: `persist()` split from `handleSave()`; `onDisappear` calls `persist()`; new arenas use a stable `persistedId` to prevent duplicates

---

## v2.3.0 — 2026-03-17

**Multi-timer brainwork redesign. Mindless/interval periods.**

### Features
- **Arena breakdown card** — once a session starts, the area between the header and timer ring shows a breakdown card: one row per arena (primary + joints), each with a colored left strip, arena label, proportional time bar, `+Xm` duration label, and a × remove button. A total row appears at the bottom when joints are present. The "ADD ARENA" button lives inside this card.
- **Joint arena picker redesign** — redesigned from icon-only to a full labeled picker: horizontal arena chip scroll + horizontal duration presets (5 / 10 / 15 / 25 / 30 / 45 / 60 / other min) + CONFIRM button. Adding a joint extends `endTime` and `totalTime` live. Removing a joint contracts them.
- **Mindless/interval periods row** — horizontal scroll row on HomeView between `AppShortcutsBar` and the protocol button. Six presets: FLOW (5m), DRIFT (10m), WALK (20m), BREATHE (4m), REST (15m), RESET (30m). Teal `#4ECDC4` accent.
- **`IntervalTimerView`** — new screen. No-arena countdown timer: circular progress ring + big minute:second number + PAUSE / RESUME / DONE controls. Auto-navigates home on completion. Does not log to DataStore.

### Internal
- `DataStore.swift` — `JointArenaEntry: Identifiable` struct (`arena: Arena`, `minutes: Int`); `IntervalPreset` struct; `INTERVAL_PRESETS` constant.
- `ActiveSessionView.swift` — `jointEntries: [JointArenaEntry]` replaces `jointArenas: [Arena]`; `@State var totalTime: Int` (mutable); `addJoint(arena:minutes:)` / `removeJoint(_:)` extend/contract `endTime` and `totalTime`.
- `RootView.swift` — `case interval(String, Int)` added to `Screen` enum; routes to `IntervalTimerView`.
- `project.pbxproj` — `IntervalTimerView.swift` registered as source file.

---

## v2.2.0 — 2026-03-17

**Joint arenas. Drag-to-reorder. Color wheel.**

### Features
- **Joint arenas** — while a session is active, tap the `+` button next to the arena name to add a second (or third) arena to the session. Joint arena icons appear inline. The circular progress ring renders a full `AngularGradient` sweeping through all joined arena colors. On session end, sessions are logged for every arena in the joint.
- **Drag-to-reorder arenas** — in the arena list editor, long-press any card and drag it to a new position. Order is persisted immediately. The `letter` (A/B/C/D) auto-reassigns based on new position. Drop target dims to 60% opacity for visual feedback.
- **Color wheel** — arena editor COLOR section now has a native `ColorPicker` (full HSB wheel + sliders) above the preset swatches. Selecting a custom color via the wheel updates the live preview instantly. Preset swatches still sync back to the wheel when tapped.

### Internal
- `CircularTimerView` — signature changed from `color: Color` to `colors: [Color]`. Single-color case renders identically. Multi-color case uses `AngularGradient`. All callers updated (`ActiveSessionView`, `ProtocolsView`).
- `ActiveSessionState` — added `jointArenas: [Arena] = []` field.
- `Color.toHex()` extension added to `RootView.swift` for `ColorPicker` → hex conversion.

---

## v2.1.1 — 2026-03-17

**Swipe-back restored. Dynamic Island now shows countdown number inside ring.**

### Bug Fixes
- `RootView.swift` — `UINavigationController` extension resets `interactivePopGestureRecognizer?.delegate` to re-enable native left-edge swipe-back after hiding the toolbar (UIKit disables it when toolbar is hidden)
- `ArenaProtocolWidgetLiveActivity.swift` — compact leading `currentValueLabel` now shows live `Text(endTime, style: .timer)` countdown inside the progress ring instead of the static arena icon; paused state shows `II`; compact trailing timer bumped to 14pt bold; paused label changed to `PAUSED` text

---

## v2.1.0 — 2026-03-17

**Full SwiftUI navigation reform. Native iOS transitions. Scroll works everywhere.**

### Architecture
- `RootView.swift` — replaced `ZStack + switch screen` pattern with `NavigationStack(path:)`. Root is always `HomeView`; all other screens pushed via `path.append(Screen)`. `navigate(.home)` = `path = NavigationPath()` (pop to root). Natural iOS push/pop slide transitions. Built-in edge-swipe-back on all screens. No more root-level `highPriorityGesture` that was blocking scroll gestures app-wide.
- `Screen` enum — `.home` retained as a sentinel value (handled in `navigate()`, never pushed as a destination); all other cases unchanged
- `ArenaEditorView` — removed `navigate` parameter, now uses `@Environment(\.dismiss)` for back/save/delete. `ArenaListEditorView` keeps `navigate` closure for forward navigation.
- Active session and complete screens get `.navigationBarBackButtonHidden(true)` — no accidental pop during a timer
- Checkin: initial `NavigationPath` pre-populated with `.checkin` if not dismissed today — appears instantly, no animation jank
- `GrainOverlay` hoisted outside `NavigationStack` in outer `ZStack` — stays full-screen across all transitions

### Bug Fixes (all caused by root gesture conflict)
- Scrolling now works on every page: ArenaEditor, ArenaListEditor, WindDown, StuckView, HabitManager, History, Notes, Settings
- TextEditor fields in ArenaEditor/WindDown/StuckView no longer block outer scroll (`.scrollDisabled(true)` retained)
- Swipe-back from left edge works natively; no custom gesture code needed

### Up Next
- App redirects (Shortcuts / deep-link URLs for each screen)
- Google Calendar feed integration (read blocks → suggest sessions in SelectView)
- Forge System DataStore models + drop engine

---

## v2.0.5 — 2026-03-17

**Forge system foundation. Widget overhaul. Stash & stack sessions. Dynamic Island circle clock.**

### Features
- **Stash & Stack** — swipe down on active session to stash timer to background; supports multiple concurrent arenas running simultaneously; EGG BONUS ACTIVE badge appears on home screen when ≥2 arenas are stacked (hooks into Forge System egg drop multiplier)
- **Dynamic Island circle clock** — compact leading slot now shows a live `ProgressView(timerInterval:)` circular arc depleting in real time with arena icon inside; minimal slot shows the ring alone; replaces the plain static icon
- **Lock screen banner redesigned** — 40pt circular progress ring with arena icon replaces plain text icon; 4pt colored left strip retained; layout: ring → label+quest → countdown timer
- **Home screen widgets rebuilt** — `systemSmall` shows arena name + live countdown or session count; `systemMedium` two-column layout with arena info + timer; smart refresh (1 min when active, 15 min idle); both deep-link to active session or home
- **WidgetKit integration** — `ActiveSessionView` now calls `SharedStore.writeActiveSession` + `WidgetCenter.reloadAllTimelines()` on session start and end; widgets stay in sync with app state
- **"ENTER THE ARENA" header enlarged** — 28pt (was 22pt), removed broken `navigate(.home)` button wrapper

### Forge System (foundation)
- `FORGE_SYSTEM_ROADMAP.md` added — full spec for streak stages, egg incubation, Rebirth Island 1–10, inventory screen, 4-phase multiplayer architecture, and data model definitions
- `DataStore` — `stackedSessions: [ActiveSessionState]` added; `stashSession()`, `unstashSession(arenaId:)`, `abandonStackedSession(arenaId:)` added
- `ActiveSessionState` — `startTime: Date` added (used for progress ring math and future Forge drop timing)
- `ArenaLiveActivityAttributes` — `startTime: Date` added as static attribute

### Bug Fixes
- `SelectView.swift` — custom duration `numberPad` keyboard trap fixed: `@FocusState` + keyboard toolbar DONE button + `scrollDismissesKeyboard(.interactively)`; "other" button auto-focuses the field

---

## v2.0.4 — 2026-03-17

**Live Activity regression fixed. Compact Island sizing. Expanded layout polish.**

### Bug Fixes
1. `ArenaProtocolWidgetLiveActivity.swift` — removed inline `ArenaActivityAttributes` struct that diverged from the app's `ArenaLiveActivityAttributes`; widget was registered for the wrong type so ActivityKit couldn't match the running activity (black Dynamic Island)
2. `ArenaProtocolWidgetLiveActivity.swift` — all view structs changed from `ActivityViewContext<ArenaActivityAttributes>` to `ActivityViewContext<ArenaLiveActivityAttributes>`
3. `ArenaProtocolWidgetLiveActivity.swift` — `arenaLabel`, `arenaColor`, `arenaIcon`, `questNote` moved from `context.state.*` reads to `context.attributes.*` to match actual struct layout

### Polish
- Compact leading constrained to `.frame(width: 20, height: 20)` — prevents crowding system clock
- Compact trailing timer capped at `.frame(maxWidth: 60)`; paused dash uses `.fixedSize()`
- Expanded leading/trailing use `.frame(maxWidth: .infinity, alignment:)` instead of padding hacks; consistent `.padding(.horizontal, 12).padding(.vertical, 8)` on all expanded regions
- Expanded bottom: `lineLimit(1)`, `.foregroundColor(.secondary)`, `.padding(.horizontal, 16)`

---

## v2.0.3 — 2026-03-16

**Live Activity shipped. Debug code cleaned. Ten build/crash fixes.**

### Features
- Dynamic Island compact view: arena icon (left, arena color) + countdown timer (right, arena color)
- Dynamic Island expanded view (long-press): leading = icon + label, trailing = live countdown, bottom = quest note
- Dynamic Island minimal view: arena icon in arena color
- Lock screen / banner Live Activity: colored left strip + arena icon + label + quest note + countdown timer (or PAUSED label when paused)
- Tap on Dynamic Island or lock screen banner deep-links directly to active session via `arenaprotocol://active`
- Pause → Dynamic Island updates to show PAUSED state; resume → countdown resumes
- Done / abandon → Live Activity dismisses cleanly

### Bug Fixes
1. `ActiveSessionView.swift` — fresh-start gate added; on minimize/return, reattaches to existing `Activity` via `Activity.activities.first` instead of requesting a duplicate
2. `project.pbxproj` — widget extension `IPHONEOS_DEPLOYMENT_TARGET` corrected `26.2` → `18.6`
3. `project.pbxproj` — widget extension `GENERATE_INFOPLIST_FILE` corrected `YES` → `NO`
4. `project.pbxproj` — widget extension `SWIFT_VERSION` corrected `5.0` → `6.0`
5. `SharedStore.swift` — removed force unwrap: `UserDefaults(suiteName:)!` → `?? .standard`
6. `ArenaProtocolWidget.swift` — removed force unwrap: `Calendar.current.date(...)!` → `?? currentDate`
7. `ArenaProtocolWidgetLiveActivity.swift` — `activityBackgroundTint` changed to `Color.clear`
8. `ArenaProtocolWidgetLiveActivity.swift` — `widgetURL` added for tap deeplink (`arenaprotocol://active`)
9. `RootView.swift` — `.onOpenURL` handler added, routes `arenaprotocol://active` to active session screen
10. `ArenaProtocolWidget/Info.plist` — added `CFBundleName` and `CFBundleInfoDictionaryVersion` (required for widget extension bundle)

### Housekeeping
- `ArenaProtocolWidgetLiveActivity.swift` — all debug test code removed:
  - `compactLeading`: restored from `Text("X").foregroundColor(.red)` to arena icon in arena color
  - `compactTrailing`: restored from `Text("TEST").foregroundColor(.white)` to countdown timer (or PAUSED) in arena color
  - Lock screen banner body: restored from `Text("ALIVE").foregroundColor(.red).background(Color.yellow)` to full production layout

---

## v2.0.2 — 2026-03-16

**Minimize-to-pill UX. Session survives navigation.**

### Features
- `ActiveSessionState` struct added to `DataStore` (transient, not Codable): `arena`, `durationMins`, `note`, `endTime`, `isPaused`, `pausedRemaining`
- `DataStore` gains `var activeSession: ActiveSessionState?`, `startSession(arena:durationMins:note:)`, `endSession()`
- `ActiveSessionView.swift` — minimize button (`chevron.down`, top-trailing) navigates `.home` without ending session; session state persists in `store.activeSession`
- `ActiveSessionView.swift` — `.onAppear` resumes from stored `endTime`/`pausedRemaining` on re-entry
- `ActiveSessionView.swift` — `togglePause()` syncs pause state back to `store.activeSession`
- `HomeView.swift` — floating timer pill (280×56pt capsule, bottom-center) shows when `store.activeSession != nil`; shows arena color dot + label + live `Text(endTime, style: .timer)`; tap returns to session; ✕ shows confirmation dialog → `store.endSession()`; spring animation in/out

---

## v2.0.1 — 2026-03-16

**Xcode project created. Swift 6 fixes. On-device confirmed.**

### Fixes
- `ios/ArenaProtocol.xcodeproj` created — all 19 source files wired, shared schemes, `DEVELOPMENT_TEAM` placeholder
- `SelectView.swift` — fixed Swift 6 `if-let` ternary syntax error in `effectiveDuration`
- `Info.plist` — removed `UIApplicationSceneManifest` block (referenced non-existent `SceneDelegate`, caused launch crash)

### Verified
- Build and run confirmed on iPhone 17 Pro Max (physical device) and iOS Simulator

---

## v2.0.0 — 2026-03-13

**Full native SwiftUI rewrite. All React/Capacitor features preserved.**

### Summary
Complete rewrite from React 18 + Vite + Capacitor 6 to native Swift 6 + SwiftUI. 25 Swift source files. All features from v1.0.0 carried forward.

### Files Added
- `ArenaProtocolApp.swift` — `@main` entry point, pure SwiftUI `WindowGroup`
- `Models/DataStore.swift` — all models, persistence, gamification
- `Views/RootView.swift` — screen router, `Screen` enum, `GrainOverlay`, `Color` extensions
- `Views/HomeView.swift` — arena grid, shortcuts bar, ember particles
- `Views/SelectView.swift` — quest, sub-arenas, duration picker
- `Views/ActiveSessionView.swift` — countdown ring, pause/resume, complete flow
- `Views/ProtocolsView.swift` + `ActiveProtocolView` — multi-block protocol timer
- `Views/MorningCheckinView.swift` — 3-step morning ritual
- `Views/WindDownView.swift` — journal + habit check
- `Views/HabitManagerView.swift` — habit CRUD
- `Views/HistoryView.swift` — stats, chart, habit grid, journal, CSV/JSON export
- `Views/NotesView.swift` — idea capture
- `Views/SettingsView.swift` — wind-down time, nav to habits/arenas
- `Views/StuckView.swift` — emergency 3-phase flow
- `Views/ArenaEditorView.swift` — arena CRUD
- `Components/ArenaCardView.swift` — card + Canvas illustration + AddArenaCardView
- `Components/CircularTimerView.swift` — reusable circular progress ring
- `Components/AppShortcutsBar.swift` — 6 deep-link shortcuts
- `Components/EmberDropModal.swift` — achievement popup overlay
- `Resources/Info.plist` — bundle config, URL schemes, dark mode

---

## v1.0.0 — pre-2026

**React/Capacitor hybrid. Single-file monolith.**

- `src/App.jsx` — 1971-line React 18 + Vite + Capacitor 6 single-file app
- All core features present: arena timers, morning check-in, wind-down, habits, history, notes, settings, arena editor, stuck flow, gamification
- Build: GitHub Actions → unsigned IPA → Sideloadly (Windows)
- Status: archived. `src/` retained for reference only.
