# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests (Swift Testing, not XCTest)
cd ios && swift test --verbose

# Run a single test suite
cd ios && swift test --filter "StreakTests"

# Build (type-checks without a connected device)
cd ios && swift build

# Watch CI after pushing
gh run watch
```

For Xcode builds: open `ios/ArenaProtocol.xcodeproj`, select the **ArenaProtocol** scheme, press `⌘R`. Tests: `⌘U`.

TestFlight deployment is automatic — any push to `main` triggers `.github/workflows/build-native-ios.yml` which tests → archives → uploads.

## Architecture

### Stack
- **Swift 6**, **SwiftUI** (no UIKit, no AppDelegate), **iOS 18.0** minimum
- **`@Observable`** (Observation framework) for state — no `@StateObject`/`@ObservedObject`
- **UserDefaults + Codable JSON** for all persistence (no database)
- **ActivityKit** for Live Activities (Dynamic Island + lock screen)
- **WidgetKit** for home screen widgets
- **EventKit** for calendar read/write

### State Management
`DataStore` (`ios/ArenaProtocol/Models/DataStore.swift`) is the single source of truth — an `@Observable` class injected as `@Environment(DataStore.self)` throughout the app. All domain models live here: `Arena`, `Session`, `ActiveSessionState`, `Habit`, `AppSettings`, etc. Persistence uses `saveToDefaults()` / `loadFromDefaults()` (JSON encode/decode to UserDefaults).

### Navigation
`RootView.swift` owns a `NavigationStack` + `@State var path: NavigationPath`. All screens are cases of the `Screen` enum (27 cases). Call `navigate(.someScreen)` to push; `navigate(.home)` pops to root. Deep links from the lock screen (`arenaprotocol://active`) use `onOpenURL`.

### Session Intelligence + Forge Engine
When a session completes, `SessionIntelligence.buildSessionProfile(from:arenas:)` computes 25+ behavioral metrics from session history. `ForgeEngine.evaluate(profile:...)` matches against 17 narrative branches (comeback, momentum, mastery, etc.) and returns a `ForgeNarrative` which becomes an `EmberDrop` shown in `EmberDropModal`. Falls back to legacy milestone drops if no narrative matches.

### Widget ↔ App Sync
The widget extension cannot import `DataStore`. Instead, the main app writes to `SharedStore` (App Group `group.arena.protocol`) via `SharedStore.writeActiveSession(...)` and calls `WidgetCenter.shared.reloadAllTimelines()`. The widget reads this shared UserDefaults suite.

### Live Activities
`ArenaLiveActivityAttributes` defines static attributes and dynamic `ContentState`. The main app requests/updates an `Activity<ArenaLiveActivityAttributes>` during sessions. The widget extension renders compact (Dynamic Island), expanded, and lock screen slots in `ArenaProtocolWidgetLiveActivity.swift`.

### High-Risk Files
Changes to these files affect everything — use "explain first, then code" for any edits:
- `DataStore.swift` — all models and persistence
- `RootView.swift` — navigation router
- `Package.swift` — platform targets / test target definition
- `Info.plist` — URL schemes, entitlements

## UI Style Rules

All views enforce a consistent dark aesthetic. Match this exactly when writing new UI:

```swift
// Background (always)
Color(hex: "#080810").ignoresSafeArea()

// Fonts — always monospaced
.font(.system(size: N, weight: .bold, design: .monospaced))

// Colors — always hex, never named (.red, .blue, etc.)
Color(hex: "#E8C547")
Color.white.opacity(0.35)

// Borders — strokeBorder, not stroke
RoundedRectangle(cornerRadius: 14)
    .strokeBorder(Color(hex: "#...").opacity(0.3), lineWidth: 1)

// Buttons — always plain style
Button { action() } label: { ... }
    .buttonStyle(.plain)

// Text
.foregroundStyle(...)   // NOT .foregroundColor()
.kerning(N)             // uppercase labels use letter spacing
```

Back button convention: `Text("← BACK")` top-left, `.padding(.top, 52)`.

## Tests

Tests use **Swift Testing** (`@Suite`, `@Test`, `#expect`) — not XCTest. All test files are in `ios/Tests/ArenaProtocolTests/`. When adding logic to `DataStore.swift` or `ForgeEngine.swift`, write `@Test` cases first.

## CONTEXT.md

`CONTEXT.md` in the repo root is a comprehensive session snapshot (36 KB). It contains all domain model definitions, the full screen inventory, version history, and color palette. It is the authoritative reference for current app state — check it before making assumptions about models or screen structure.
