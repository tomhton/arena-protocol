# Arena Protocol — Xcode Setup Guide

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or later (download from the Mac App Store or developer.apple.com)
- An Apple Developer account (free account works for Simulator; paid account required for physical device)

---

## 1. Open the Project

Open `ArenaProtocol.xcodeproj` (not `Package.swift`) in Xcode:

```
ios/ArenaProtocol.xcodeproj
```

Either double-click the file in Finder or run:

```sh
open ios/ArenaProtocol.xcodeproj
```

The project navigator on the left will show:
- `ArenaProtocol/` — all app source files
- `Tests/ArenaProtocolTests/` — unit tests

---

## 2. Set Your Apple Developer Team ID

Xcode needs a signing team to build for a real device (and sometimes even the Simulator on stricter setups).

1. In the Project Navigator, click **ArenaProtocol** (the blue project icon at the top).
2. Select the **ArenaProtocol** target in the Targets list.
3. Go to the **Signing & Capabilities** tab.
4. Under **Team**, click the dropdown and select your Apple Developer account.
   - If your account is not listed, choose **Add an Account…** and sign in with your Apple ID.
5. Repeat for the **ArenaProtocolTests** target.

> The `DEVELOPMENT_TEAM` build setting is pre-populated as `$(DEVELOPMENT_TEAM)` — Xcode resolves this automatically once you select a team in the UI. No manual edits to the project file are needed.

Bundle ID is already set to `com.arenaprotocol.app`. If you see a signing conflict (another developer registered that ID), append your initials, e.g. `com.arenaprotocol.app.jd`.

---

## 3. Select iPhone 17 Pro Max as the Run Destination

In the Xcode toolbar, click the **scheme / destination selector** (the area that shows something like `ArenaProtocol > iPhone 16 Pro`).

### Simulator

1. Click the destination dropdown.
2. Under **iOS Simulators**, find **iPhone 17 Pro Max** (requires Xcode 16+ with iOS 18 simulator runtime).
3. If not listed, go to **Xcode → Settings → Platforms** and download the iOS 18 Simulator Runtime.

### Physical Device

1. Connect your iPhone via USB (or use Wireless Device Pairing via **Window → Devices and Simulators**).
2. Trust the Mac on your iPhone if prompted.
3. Select your device from the destination dropdown — it appears under **iOS Device**.
4. Ensure your Apple Developer Team is set (step 2 above) and that your device is registered to your account.

---

## 4. Build and Run

Press **⌘R** (or click the ▶ Run button) to build and launch the app on the selected destination.

The first build may take a minute as Swift compiles all source files. Subsequent builds are incremental.

---

## 5. Run Tests

Press **⌘U** (or go to **Product → Test**) to run the full test suite.

Individual tests can be run by:
- Clicking the diamond icon next to a test in the source editor.
- Using the **Test Navigator** (⌘6) to run specific test suites.

---

## Project Structure

```
ios/
├── ArenaProtocol.xcodeproj/       ← open this in Xcode
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/
│       ├── ArenaProtocol.xcscheme
│       └── ArenaProtocolTests.xcscheme
├── ArenaProtocol/                 ← app source
│   ├── ArenaProtocolApp.swift     ← @main entry point
│   ├── Components/
│   ├── Models/
│   ├── Resources/Info.plist
│   └── Views/
├── Tests/
│   └── ArenaProtocolTests/
│       └── ArenaProtocolTests.swift
├── Package.swift                  ← SPM package (untouched)
└── README_XCODE_SETUP.md          ← this file
```

`Package.swift` remains intact so the project can also be used as a Swift Package (e.g. for CI builds with `swift build`). The `.xcodeproj` sits alongside it and references the same source files.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| "No account for team" | Add your Apple ID under Xcode → Settings → Accounts |
| "Provisioning profile not found" | Select your team in Signing & Capabilities |
| iPhone 17 Pro Max not in simulator list | Download iOS 18 runtime via Xcode → Settings → Platforms |
| Build fails on Swift 6 concurrency error | These are compile-time errors in source — see the issue tracker |
| "duplicate output file" | Clean build folder with ⇧⌘K then rebuild |
