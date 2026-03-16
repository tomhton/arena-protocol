# Xcode Setup — Arena Protocol

This guide explains how to open the project in Xcode, configure signing, select the iPhone 17 Pro Max as a run destination, and deploy to a physical device.

---

## 1. Open the project

Open **`ios/ArenaProtocol.xcodeproj`** — not the `Package.swift`.

```bash
# From the repo root
open ios/ArenaProtocol.xcodeproj
```

Or drag `ios/ArenaProtocol.xcodeproj` onto the Xcode icon in the Dock.

> **Note:** `Package.swift` still exists alongside the `.xcodeproj` for CI / command-line builds. Do not remove it. Xcode will detect it automatically and may offer to use it — always choose the `.xcodeproj` for device/Simulator work.

---

## 2. Set your Apple Developer Team ID

1. In Xcode, select the **ArenaProtocol** project in the Project Navigator (left sidebar).
2. Select the **ArenaProtocol** target (not the project row — the target row below it).
3. Open the **Signing & Capabilities** tab.
4. Under **Team**, click the drop-down and choose your Apple Developer account.
   - If your account is not listed, go to **Xcode → Settings → Accounts** and add your Apple ID.
5. Repeat for the **ArenaProtocolTests** target.

Xcode will automatically provision a development certificate and provisioning profile for `com.arenaprotocol.app`.

> **Tip:** If you see "Failed to register bundle identifier" it means the Bundle ID is already registered to a different team. Change `PRODUCT_BUNDLE_IDENTIFIER` in the target's Build Settings to a unique reverse-DNS string (e.g. `com.yourname.arenaprotocol`).

---

## 3. Select the iPhone 17 Pro Max as the run destination

1. Click the **run destination selector** in the Xcode toolbar (the device/simulator name next to the scheme selector).
2. To run on **Simulator**: choose **iPhone 17 Pro Max** under the iOS Simulators section.
   - If iPhone 17 Pro Max is not listed, go to **Xcode → Settings → Platforms**, download the latest iOS 18 simulator runtime, then add the device via **Window → Devices and Simulators → Simulators → +**.
3. To run on a **physical iPhone 17 Pro Max**: connect the device via USB or Wi-Fi, trust the Mac on the device, and select it from the run destination list.

---

## 4. Run on device

1. With your physical iPhone 17 Pro Max selected as the run destination, press **⌘R** (or click the ▶ Run button).
2. Xcode will build, sign, and install the app.
3. On first install you may need to trust the developer certificate on the device:
   - Go to **Settings → General → VPN & Device Management** on the iPhone.
   - Tap your developer certificate and tap **Trust**.

---

## 5. Run tests

- Press **⌘U** to run all tests, or click the diamond icon next to any `@Test` function in the editor gutter.
- The test target (`ArenaProtocolTests`) uses **Swift Testing** (`@Suite`, `@Test`). All 30+ tests run on-device or in the Simulator — no macOS runner needed.

---

## 6. Build settings reference

| Setting | Value |
|---|---|
| Bundle ID | `com.arenaprotocol.app` |
| Deployment target | iOS 18.0 |
| Swift version | 6.0 |
| Signing style | Automatic — set `DEVELOPMENT_TEAM` in Signing & Capabilities |
| Info.plist | `ArenaProtocol/Resources/Info.plist` |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "No such module 'SwiftUI'" | Make sure the SDK is set to `iphoneos` or an iOS Simulator, not macOS. |
| "Signing requires a development team" | Follow Step 2 above to set your Team ID. |
| Simulator shows wrong device shape | Delete the run from Simulator → File → Erase All Content, then re-run. |
| Swift 6 concurrency errors | These are pre-existing warnings in the source. They do not block the build; fix them as you go. |
| Package.swift conflicts | If Xcode resolves the SPM package automatically, you can close that editor — the `.xcodeproj` manages all compilation. |
