# Arena Protocol

A dark, minimal iOS life-management app built around timed focus sessions across four life arenas: Body, Spirit, Tribe, and Craft.

## Stack

- Swift 6 + SwiftUI
- iOS 18.0 minimum
- iPhone 17 Pro Max primary target
- UserDefaults + Codable persistence
- WidgetKit (in development)
- ActivityKit / Live Activities (planned)

## Structure

All active development is in `ios/`

See `CONTEXT.md` for full app state and session onboarding guide.

## Development Setup

- **Mac (Xcode):** open `ios/ArenaProtocol.xcodeproj`
- **Windows (Claude Code):** edit Swift files directly, push to GitHub
- **Device:** iPhone 17 Pro Max via USB or TestFlight

## Machines

| Machine | Role |
|---|---|
| Windows 11 desktop | Claude Code — feature development |
| MacBook Air | Xcode — build, sign, device testing |
| iPhone 17 Pro Max | Primary test device |
