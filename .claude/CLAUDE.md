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

## Post-Change Protocol

**Every code change — no matter how small — must end with these steps:**

1. **CONTEXT.md** — update the following sections:
   - Version number (top line: `Last updated: YYYY-MM-DD (vX.Y.Z)`)
   - File map (add new files, remove deleted files, update descriptions of changed files)
   - Model definitions (if any struct/enum/class was added, renamed, or had fields changed)
   - UserDefaults keys table (if any new persistence key was added)
   - Screen enum inventory (if any navigation case was added/removed)
   - App Group keys table (if SharedStore keys changed)

2. **CHANGELOG.md** — add a new version entry above existing history:
   - Format: `## vX.Y.Z — YYYY-MM-DD HH:MM`
   - Include: summary line, feature bullets, files changed list

3. **Build verification** — ensure `swift build` passes (ignore pre-existing ActivityKit/macOS errors which only affect `swift build` on macOS, not Xcode iOS builds)

4. **No partial implementations** — every prompt must end in a buildable, functional state. If a feature spans multiple files, all files must be updated in the same prompt. Never leave dangling references to deleted code or unimplemented method stubs.

5. **pbxproj** — when adding or removing `.swift` files, update `project.pbxproj`:
   - PBXFileReference section (file entry)
   - PBXBuildFile section (build entry)
   - PBXGroup section (folder membership)
   - PBXSourcesBuildPhase section (compile list)

## Schema Versioning

All app data is stored as Codable JSON in UserDefaults. When changing Codable model structs:

- **Adding fields:** Always provide a default value (`var newField: Type = defaultValue`) so existing JSON decodes without error.
- **Removing fields:** Remove the property. Old JSON keys are silently ignored by Codable.
- **Renaming fields:** Add a `CodingKeys` enum mapping old key → new property, or add migration logic in `DataStore.init()`.
- **Type changes:** Add migration in `DataStore.init()` that reads old format, converts, and re-saves.

Never ship a change that causes `loadFromDefaults()` to return the fallback value because the existing JSON can't decode into the new struct. That silently wipes user data.
