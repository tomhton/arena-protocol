# Arena Protocol

A dark-themed native iOS focus app built around timed sessions across four life arenas. Timer rings, Live Activities on the lock screen, joint multi-arena sessions, habit tracking, calendar sync, and daily protocols.

**Current version:** v2.9.0 — [CHANGELOG](CHANGELOG.md)

---

## Stack

| Layer | Detail |
|---|---|
| Language | Swift 6 |
| UI | SwiftUI — no UIKit, no AppDelegate |
| State | `@Observable` (iOS 17+ Observation framework) |
| Persistence | UserDefaults + Codable JSON |
| Live Activities | ActivityKit — Dynamic Island + lock screen |
| Widgets | WidgetKit — small + medium home screen widgets |
| Calendar | EventKit — writes focus blocks to "Arena Protocol" calendar |
| Notifications | UNUserNotificationCenter — wind-down reminder |
| Min target | iOS 18.0 |
| Xcode project | `ios/ArenaProtocol.xcodeproj` |

---

## Features

- **Arena grid** — four customizable life pillars with color, icon, subtitle, examples, and sub-arena categories
- **Focus sessions** — circular timer ring with pause/resume, joint arenas (stack multiple arenas mid-session), end time display
- **Live Activity** — lock screen + Dynamic Island shows active session (block, color, countdown). Idle state shows time-aware prompt when no session is running. Protocols also drive Live Activities.
- **Protocols** — multi-block timed sequences. Each block runs a Live Activity on the lock screen.
- **Interval periods** — mindless timer presets (FLOW, DRIFT, WALK, BREATHE, REST, RESET)
- **Habit tracking** — daily check-ins with streak counters
- **Calendar sync** — focus blocks logged to iOS Calendar (syncs to Google Calendar). Read feed shows upcoming events on home and in session picker.
- **Forge system** — streak-based progression: forge marks, ember drops, egg incubation
- **Wind-down ritual** — daily notification + guided close-of-day flow
- **Edit mode** — long-press any arena to enter edit mode. Drag handles reorder arenas. Tap EDIT to open the arena editor (name, icon, color, sub-arenas).

---

## Project Structure

```
ios/
  ArenaProtocol.xcodeproj       — Xcode project
  ArenaProtocol/
    Models/
      DataStore.swift           — @Observable state, all models, defaults
      CalendarManager.swift     — EventKit read/write, timezone helpers
    Views/
      RootView.swift            — NavigationStack router (Screen enum)
      HomeView.swift            — Arena grid, shortcuts, session tray
      SelectView.swift          — Arena session config + calendar feed
      ActiveSessionView.swift   — Live timer, joint arenas, Live Activity
      ProtocolsView.swift       — Protocol list, editor, active runner + Live Activity
      ArenaEditorView.swift     — Arena create/edit/delete
      SettingsView.swift        — Wind-down, timezone, calendar, What's New
      WhatsNewView.swift        — In-app changelog
      StuckView.swift           — I AM STUCK prompt
      HistoryView.swift         — Session history
      HabitManagerView.swift    — Habit editor
      WindDownView.swift        — Wind-down ritual
    Components/
      ArenaCardView.swift
      AppShortcutsBar.swift
      EmberDropModal.swift
    Resources/
      Info.plist
  ArenaProtocolWidget/          — WidgetKit + ActivityKit extension
    ArenaProtocolWidget.swift
    ArenaProtocolWidgetLiveActivity.swift
    ArenaLiveActivityAttributes.swift
    SharedStore.swift
```

---

## Development Setup

- **Build:** open `ios/ArenaProtocol.xcodeproj` in Xcode 16+
- **Install to device:** `xcrun devicectl device install app --device <UDID> path/to/ArenaProtocol.app`
- **Context doc:** see `CONTEXT.md` for full app state and session onboarding

## Machines

| Machine | Role |
|---|---|
| Windows 11 desktop | Claude Code — feature development |
| MacBook Air | Xcode — build, sign, device testing |
| iPhone (Tom's Windows Phone) | Primary test device |
