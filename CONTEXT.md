# CONTEXT.md — Arena Protocol
Last updated: March 2026

## App Overview

Arena Protocol is a dark, minimal SwiftUI iOS productivity app.
The core mechanic is entering one of four life "arenas" (Body, Spirit,
Tribe, Craft) with an intention and a focus timer. Aesthetic: ember-glow,
military-sparse. Philosophy: ritualistic presence, not gamification.

## Repository

github.com/tomhton/arena-protocol

## Tech Stack

- Swift / SwiftUI (iOS 17+, Swift 6)
- @Observable macro for state (no ObservableObject)
- UserDefaults for persistence (JSON encoded via JSONEncoder/JSONDecoder)
- The live app lives entirely in ./ios/

## Bundle Identifier

com.arenaprotocol.app

## Build Pipeline

GitHub → Xcode Cloud → TestFlight (internal)
Apple Developer account active as of March 2026.

---

## Project Structure

```
ios/
  ArenaProtocol/
    ArenaProtocolApp.swift         # App entry point
    Models/
      DataStore.swift              # All models, persistence, defaults
    Views/
      RootView.swift               # Root navigation container
      HomeView.swift               # Arena grid, morning state, forge marks
      SelectView.swift             # Arena selected, sub-arena picker, quest input
      ActiveSessionView.swift      # Focus timer, circular progress, session running
      WindDownView.swift           # End-of-day journal + habit check-ins
      MorningCheckinView.swift     # Morning ritual screen
      HistoryView.swift            # Session log, contribution grid
      SettingsView.swift           # Wind-down time, shortcuts manager
      ArenaEditorView.swift        # Custom arena creation/edit
      HabitManagerView.swift       # Habit CRUD
      ProtocolsView.swift          # Multi-arena protocol sequences
      StuckView.swift              # Emergency focus prompt screen
      NotesView.swift              # Session notes
    Components/
      ArenaCardView.swift          # Arena card UI component
      CircularTimerView.swift      # Circular progress ring
      EmberDropModal.swift         # Reward/unlock modal
      AppShortcutsBar.swift        # Home screen shortcut strip
    Shared/                        # ← BEING ADDED NOW
      SharedStore.swift            # App Group read/write for WidgetKit
    Resources/
  Tests/
    ArenaProtocolTests.swift
  ArenaProtocolWidget/             # ← BEING ADDED NOW
    ArenaProtocolWidget.swift      # Widget entry point + timeline provider
    ArenaWidgetView.swift          # Lock screen + home screen widget UI
```

---

## Data Layer

All persistence via UserDefaults.standard with these keys:
- arena_custom_arenas    → [Arena]
- arena_sessions         → [Session]
- arena_habits           → [Habit]
- arena_habit_logs       → [HabitLog]
- arena_journals         → [JournalEntry]
- arena_ideas            → [IdeaNote]
- arena_settings         → AppSettings
- arena_protocols        → [ArenaProtocolModel]
- arena_seen_drops       → [String]
- arena_checkin          → MorningCheckin

App Group (group.com.arenaprotocol.app) used only for widget-facing state
via SharedStore. Keys: arena_widget_state → WidgetState

## Core Models (summary)

- Arena: id, label, letter, color (hex), subtitle, description, icon,
         examples, subArenas [String: [String]]
- Session: id, arenaId, duration (min), date (yyyy-MM-dd), note, ts (epoch ms)
- Habit / HabitLog: yes/no daily check-ins
- JournalEntry: date, text, ts
- AppSettings: windDownTime (HH:mm string)
- MorningCheckin: date, completed [String]
- WidgetState: activeArenaName, activeArenaColor (hex), timerEndsAt (Date?),
               todaySessionCount

## The Four Arenas

- BODY    (#C0392B) — move · fuel · rest
- SPIRIT  (#D4A017) — reflect · read · meditate
- TRIBE   (#B87333) — reach out · show up · plan
- CRAFT   (#708090) — deep work · admin · build

---

## Current Sprint: WidgetKit

### What's being built
- Lock screen widgets: .accessoryCircular, .accessoryRectangular
- Home screen widget: .systemSmall
- Shared data bridge via App Groups + SharedStore

### Files being added/modified
- NEW: ios/ArenaProtocol/Shared/SharedStore.swift
- NEW: ios/ArenaProtocolWidget/ArenaProtocolWidget.swift
- NEW: ios/ArenaProtocolWidget/ArenaWidgetView.swift
- MODIFY: ios/ArenaProtocol/Views/ActiveSessionView.swift
  (add SharedStore write on timer start/end — surgical only)

### Xcode manual steps still required after file creation
1. File → New Target → Widget Extension → name: ArenaProtocolWidget
2. Add App Groups capability to both ArenaProtocol and ArenaProtocolWidget targets
   — Group ID: group.com.arenaprotocol.app
3. Add SharedStore.swift to both target memberships
4. Add ArenaProtocolWidget files to widget target membership
5. Verify widget extension deployment target matches app (iOS 17+)

---

## Key Principles (do not violate)

- Surgical edits only — never regenerate whole view files
- @Observable only — no ObservableObject, no @StateObject/@ObservedObject
- Widget target must not import DataStore or reference @Observable classes
- UserDefaults.standard for app data, App Group suite for widget data only
- No custom fonts in widgets — system fonts only
- No images or asset catalog refs in widgets — glyphs and hex colors only
- Swift 6 strict concurrency — avoid @MainActor sprawl, prefer isolated calls

---

## Up Next (after WidgetKit)

- Live Activity / Dynamic Island timer (ActivityKit)
- Haptic feedback on arena entry/exit
- HealthKit workout write-back
- Xcode Cloud → TestFlight automation polish
