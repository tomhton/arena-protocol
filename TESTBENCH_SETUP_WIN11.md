# Arena Protocol — Windows 11 iOS Testbench Setup
## Complete Procedure: Dev Machine → iOS Device/Simulator

> **Goal:** Build and test the native SwiftUI Arena Protocol app on iOS from a Windows 11 PC.
> iOS apps require macOS/Xcode to compile. This guide covers the most efficient
> local-to-cloud pipeline for Windows developers.

---

## OVERVIEW

```
Windows 11 PC
  └─ Git push / code edits
        └─ GitHub repo
              └─ Cloud build (Codemagic / GitHub Actions macOS runner)
                    └─ .ipa artifact
                          └─ Install to device (AltStore / TestFlight / Diawi)
```

---

## PART 1 — LOCAL ENVIRONMENT SETUP (Windows 11)

### 1.1 Install Prerequisites

| Tool          | Purpose                      | Download                              |
|---------------|------------------------------|---------------------------------------|
| Git           | Version control              | https://git-scm.com                   |
| Node.js LTS   | Build tooling / npm scripts  | https://nodejs.org                    |
| VS Code       | Code editor with Swift ext.  | https://code.visualstudio.com         |
| PowerShell 7  | Modern shell                 | Via Microsoft Store                   |

**Verify installs — open PowerShell 7 and run:**
```powershell
git --version        # git version 2.x
node --version       # v20.x
npm --version        # 10.x
```

### 1.2 Install VS Code Extensions

In VS Code (`Ctrl+Shift+X`), install:
- `Swift` by Swift Server Work Group (syntax highlighting, snippets)
- `SwiftFormat` by Nick Lockwood (auto-format on save)
- `GitLens` — Git history in editor

### 1.3 Clone the Repository

```powershell
git clone https://github.com/YOUR_ORG/arena-protocol.git
cd arena-protocol
git checkout claude/swift-ios26-conversion-aROXy
```

### 1.4 Project Structure Reference

```
arena-protocol/
├── ios/
│   ├── Package.swift                    ← Swift package manifest
│   ├── ArenaProtocol/
│   │   ├── ArenaProtocolApp.swift       ← App entry point
│   │   ├── Models/
│   │   │   └── DataStore.swift          ← All models + persistence
│   │   ├── Views/                       ← All screens
│   │   │   ├── RootView.swift
│   │   │   ├── HomeView.swift
│   │   │   ├── SelectView.swift
│   │   │   ├── ActiveSessionView.swift
│   │   │   ├── ProtocolsView.swift
│   │   │   ├── MorningCheckinView.swift
│   │   │   ├── WindDownView.swift
│   │   │   ├── HabitManagerView.swift
│   │   │   ├── HistoryView.swift
│   │   │   ├── NotesView.swift
│   │   │   ├── SettingsView.swift
│   │   │   ├── StuckView.swift
│   │   │   └── ArenaEditorView.swift
│   │   ├── Components/                  ← Reusable UI
│   │   │   ├── ArenaCardView.swift
│   │   │   ├── CircularTimerView.swift
│   │   │   ├── AppShortcutsBar.swift
│   │   │   └── EmberDropModal.swift
│   │   └── Resources/
│   │       └── Info.plist
│   └── Tests/
│       └── ArenaProtocolTests/
│           └── ArenaProtocolTests.swift
├── src/                                 ← Legacy React source (archived)
└── TESTBENCH_SETUP_WIN11.md             ← This file
```

---

## PART 2 — CLOUD BUILD SETUP (No Mac Required)

### 2.1 Option A: Codemagic (Recommended — Free Tier)

**Step 1: Connect repository**
1. Sign up at https://codemagic.io (free with GitHub login)
2. Click **Add application** → Select your GitHub repo `arena-protocol`
3. Choose **iOS App** workflow type

**Step 2: Configure workflow**
Create / update `codemagic.yaml` in the repo root:

```yaml
workflows:
  ios-native-swift:
    name: Arena Protocol — iOS Native
    max_build_duration: 60
    instance_type: mac_mini_m2

    environment:
      xcode: latest
      cocoapods: default

    scripts:
      - name: Build Swift package
        script: |
          cd ios
          xcodebuild \
            -scheme ArenaProtocol \
            -destination "generic/platform=iOS Simulator" \
            -derivedDataPath build \
            clean build \
            CODE_SIGNING_ALLOWED=NO

      - name: Run unit tests
        script: |
          cd ios
          swift test

      - name: Archive (unsigned IPA)
        script: |
          cd ios
          xcodebuild \
            -scheme ArenaProtocol \
            -destination "generic/platform=iOS" \
            archive \
            -archivePath ArenaProtocol.xcarchive \
            CODE_SIGNING_ALLOWED=NO

          xcodebuild \
            -exportArchive \
            -archivePath ArenaProtocol.xcarchive \
            -exportPath export/ \
            -exportOptionsPlist ExportOptions.plist

    artifacts:
      - ios/export/*.ipa
      - ios/build/Logs/**/*.xcresult

    publishing:
      email:
        recipients:
          - your@email.com
        notify:
          success: true
          failure: true
```

**Step 3: Trigger build**
```powershell
git add -A
git commit -m "feat: trigger Codemagic build"
git push origin claude/swift-ios26-conversion-aROXy
```
Codemagic auto-triggers on push. Download `.ipa` from Codemagic dashboard artifacts.

---

### 2.2 Option B: GitHub Actions macOS Runner

Create `.github/workflows/build-native-ios.yml`:

```yaml
name: Build Native iOS (SwiftUI)

on:
  push:
    branches: [claude/swift-ios26-conversion-aROXy, main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-15          # Xcode 16, Swift 6, iOS 18 SDK
    timeout-minutes: 40

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Swift version
        run: swift --version

      - name: Run unit tests
        working-directory: ios
        run: swift test --verbose

      - name: Build for simulator
        working-directory: ios
        run: |
          xcodebuild \
            -scheme ArenaProtocol \
            -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
            -derivedDataPath build \
            clean build \
            CODE_SIGNING_ALLOWED=NO \
            | xcpretty

      - name: Archive (unsigned)
        working-directory: ios
        run: |
          xcodebuild \
            -scheme ArenaProtocol \
            -destination "generic/platform=iOS" \
            archive \
            -archivePath ArenaProtocol.xcarchive \
            CODE_SIGNING_ALLOWED=NO

      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: ArenaProtocol-${{ github.sha }}
          path: ios/ArenaProtocol.xcarchive
          retention-days: 14
```

---

## PART 3 — INSTALL IPA ON DEVICE (No Apple Developer Account Required)

### 3.1 AltStore (Free, Sideloading)

**On Windows 11:**
1. Download AltServer from https://altstore.io
2. Install iTunes (Microsoft Store version)
3. Install iCloud (Microsoft Store version)
4. Run AltServer → system tray icon appears
5. Connect iPhone/iPad via USB, trust computer

**Install AltStore on device:**
1. Right-click AltServer tray icon → Install AltStore → select your device
2. Open AltStore on device → Trust the developer cert in Settings > General > VPN & Device Management

**Sideload the IPA:**
1. Download `.ipa` from Codemagic/GitHub Actions artifacts to your PC
2. Open AltServer tray → Sideload .ipa → select the `.ipa` file
3. App installs on device (free tier allows 3 sideloaded apps; resigns every 7 days)

### 3.2 Diawi (Quick OTA Distribution)

1. Go to https://diawi.com
2. Upload `.ipa` file
3. Copy generated link
4. Open link on iOS device (Safari) → Install

> Note: Diawi requires basic code signing. Use Codemagic's "Ad Hoc" export option.

### 3.3 TestFlight (Apple Developer Account — $99/yr)

If you have an Apple Developer account:
1. Upload IPA to App Store Connect via Transporter (macOS) or Codemagic's built-in publishing
2. Distribute via TestFlight to testers
3. Supports up to 10,000 external testers

---

## PART 4 — iOS SIMULATOR ON WINDOWS (Advanced)

> Running an iOS simulator on Windows requires virtualization. This is advanced
> and not officially supported by Apple, but possible via these paths:

### 4.1 macOS on UTM (M1/M2 Mac VM)
- Install UTM on an Apple Silicon Mac (if you have one) → run macOS VM → run Xcode inside
- Not applicable on pure Windows but useful for cheap Mac alternatives

### 4.2 GitHub Codespaces + Xcode Cloud
1. Open repo in GitHub Codespaces (Linux container)
2. Edit Swift files in browser
3. Trigger Xcode Cloud build from Codespaces terminal:
   ```bash
   gh workflow run "build-native-ios.yml"
   gh run watch
   ```
4. Download artifacts when complete

### 4.3 Remote Mac via MacStadium
- Rent a Mac Mini from https://macstadium.com (~$40/month)
- SSH or VNC from Windows into the Mac
- Run Xcode, simulator, and all tooling natively

---

## PART 5 — RUNNING UNIT TESTS LOCALLY (Windows — Swift for Windows)

Swift has limited Windows support but unit tests can be run:

### 5.1 Install Swift for Windows

1. Download Swift toolchain from https://www.swift.org/install/windows/
2. Install Visual Studio with "Desktop Development with C++" workload (required by Swift)
3. Add Swift to PATH:
   ```powershell
   $env:Path += ";C:\Library\Developer\Toolchains\unknown-Asserts-development.xctoolchain\usr\bin"
   ```

### 5.2 Run Tests (Windows — subset only)

Swift on Windows does not support UIKit/SwiftUI, so UI-dependent tests won't run.
Pure logic tests (DataStore, streaks, forge marks, persistence) will run:

```powershell
cd arena-protocol\ios

# Filter out UI-dependent test suites (they import UIKit)
swift test --filter ArenaProtocolTests.DateHelperTests
swift test --filter ArenaProtocolTests.StreakTests
swift test --filter ArenaProtocolTests.ForgeMarkTests
swift test --filter ArenaProtocolTests.EmberDropTests
swift test --filter ArenaProtocolTests.HabitGridTests
swift test --filter ArenaProtocolTests.ProtocolModelTests
```

Expected output:
```
Test Suite 'ArenaProtocolTests' started
✔ testTodayStringFormat
✔ testFormatTimeZeroPads
✔ testStreakCountsConsecutiveDays
✔ testFirstMarkAtThreshold3
... (all 30+ tests pass)
Test Suite 'ArenaProtocolTests' passed
```

---

## PART 6 — DEVELOPMENT WORKFLOW (Day-to-Day)

### Edit → Test → Push → Build → Install

```powershell
# 1. Edit Swift files in VS Code
code arena-protocol\ios\ArenaProtocol\Views\HomeView.swift

# 2. Validate Swift syntax locally (if Swift for Windows installed)
swift build 2>&1 | Select-String -Pattern "error:"

# 3. Run logic tests
swift test --filter ArenaProtocolTests

# 4. Commit and push
git add ios/
git commit -m "fix: update home view layout"
git push origin claude/swift-ios26-conversion-aROXy

# 5. Monitor cloud build (GitHub Actions)
gh run list --workflow="build-native-ios.yml" --limit 5
gh run watch <run-id>

# 6. Download artifact
gh run download <run-id> --name "ArenaProtocol-<sha>"

# 7. Install via AltStore or Diawi (see Part 3)
```

---

## PART 7 — ENVIRONMENT VALIDATION CHECKLIST

Run this checklist before starting any build session:

```powershell
# Checklist script — paste into PowerShell 7
$checks = @{
    "Git installed"        = { git --version }
    "Node.js installed"    = { node --version }
    "gh CLI installed"     = { gh --version }
    "On correct branch"    = { git branch --show-current }
    "Repo is clean"        = { git status --short }
    "Remote accessible"    = { git ls-remote --heads origin 2>&1 | Select-String "claude/" }
}

foreach ($check in $checks.GetEnumerator()) {
    try {
        $result = & $check.Value 2>&1
        Write-Host "✓ $($check.Key): $result" -ForegroundColor Green
    } catch {
        Write-Host "✗ $($check.Key): FAILED" -ForegroundColor Red
    }
}
```

---

## PART 8 — TROUBLESHOOTING

| Issue | Cause | Fix |
|-------|-------|-----|
| `swift test` fails with "cannot find module 'UIKit'` | UIKit not available on Windows | Run UI tests in cloud only; filter to logic tests |
| GitHub Actions build fails: `xcode-select` error | Wrong Xcode version specified | Change `macos-15` to `macos-14` or check available runners |
| IPA won't install via AltStore | AltServer not running | Ensure iTunes + iCloud are installed from Microsoft Store (not Apple website) |
| Codemagic build stuck "queued" | Free tier limit reached | Wait or upgrade; alternatively use GitHub Actions |
| `git push` returns 403 | Wrong branch name | Confirm branch starts with `claude/` |
| `swift build` on Windows shows `linking` errors | Missing MSVC linker | Install VS with "Desktop Development with C++" |
| "Untrusted developer" on iPhone | Code not trusted | Settings → General → VPN & Device Management → Trust |

---

## QUICK REFERENCE CARD

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ARENA PROTOCOL — WINDOWS 11 TESTBENCH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Dev branch:   claude/swift-ios26-conversion-aROXy
iOS min:      iOS 18.0
Swift:        6.0
Xcode:        16+

BUILD:
  Push to branch → Codemagic/GH Actions auto-builds

TEST (logic only, Windows):
  swift test --filter ArenaProtocolTests

INSTALL IPA:
  AltStore   → sideload, 7-day resign
  Diawi      → OTA link
  TestFlight → requires $99 Apple Dev account

KEY FILES:
  ios/Package.swift                  Package config
  ios/ArenaProtocol/Models/DataStore.swift  All models
  ios/Tests/ArenaProtocolTests/      Unit tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
