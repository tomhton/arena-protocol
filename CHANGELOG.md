# Changelog — Arena Protocol
## v2.0.3 — 2026-03-16
### Added
- Edge-swipe-to-go-back gesture in `RootView.swift` — swipe right from the leading 44pt edge to navigate back; disabled on `.home`, `.active`, and `.complete` screens

## v2.0.2 — 2026-03-16
### Fixed
- Removed duplicate "IGNITE THE" HStack in `MorningCheckinView.swift` — title now renders correctly
## v2.0.1 — 2026-03-16
### Added
- `ios/ArenaProtocol.xcodeproj` created — all 19 source files wired, shared schemes, DEVELOPMENT_TEAM placeholder
### Fixed
- `SelectView.swift` — fixed Swift 6 if-let ternary syntax error in effectiveDuration
- `Info.plist` — removed UIApplicationSceneManifest block that referenced non-existent SceneDelegate, causing launch crash
### Confirmed
- Build and run verified on iPhone 17 Pro Max and iOS Simulator
## v2.0.0 — 2026-03-13
### Changed
- Full native SwiftUI rewrite — 25 Swift files, all features from React/Capacitor version preserved
## v1.0.0 — pre-2026
### Initial
- React 18 + Vite + Capacitor 6 hybrid app (src/App.jsx, 1971 lines)
