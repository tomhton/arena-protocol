# CHANGELOG — Arena Protocol

All meaningful changes to Arena Protocol are documented here.
Format: version — date — summary. Most recent version first.

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
