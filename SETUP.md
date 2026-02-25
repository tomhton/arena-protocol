# Arena Protocol — Capacitor App Setup (Windows)

## OVERVIEW
This guide gets your app running on Android immediately, and iOS via cloud build.
No Mac required.

---

## STEP 1 — Install Prerequisites

Download and install:
1. Node.js LTS → https://nodejs.org
2. Git → https://git-scm.com
3. Android Studio → https://developer.android.com/studio
   - During setup, install: Android SDK, Android SDK Platform-Tools, Android Virtual Device

Verify installs by opening PowerShell and running:
  node --version
  npm --version

---

## STEP 2 — Create the Project

Open PowerShell and run these commands one at a time:

  npm create vite@latest arena-protocol -- --template react
  cd arena-protocol
  npm install
  npm install @capacitor/core @capacitor/cli @capacitor/android
  npm install -D @vitejs/plugin-react

---

## STEP 3 — Configure Vite

Replace the contents of vite.config.js with:

  import { defineConfig } from 'vite'
  import react from '@vitejs/plugin-react'

  export default defineConfig({
    plugins: [react()],
    base: './',
    build: {
      outDir: 'dist'
    }
  })

---

## STEP 4 — Initialize Capacitor

In PowerShell (still in arena-protocol folder):

  npx cap init "Arena Protocol" "com.arenaprotocol.app" --web-dir dist

---

## STEP 5 — Add Your App Code

1. Delete everything in src/App.jsx
2. Replace with the contents of arena-focus-app.jsx (the file you downloaded)
3. Delete everything in src/App.css (leave the file empty)
4. Replace src/index.css with just:
     * { box-sizing: border-box; margin: 0; padding: 0; }
     body { background: #080810; }

---

## STEP 6 — Build and Add Android

  npm run build
  npx cap add android
  npx cap sync

---

## STEP 7 — Run on Android

Option A — Android Emulator (no physical phone needed):
  1. Open Android Studio
  2. Go to Tools > Device Manager > Create Device
  3. Pick Pixel 7, API 34
  4. Then run: npx cap open android
  5. Click the green Run button in Android Studio

Option B — Physical Android phone:
  1. Enable Developer Options on your phone:
     Settings > About Phone > tap "Build Number" 7 times
  2. Enable USB Debugging in Developer Options
  3. Connect phone via USB
  4. Run: npx cap open android
  5. Select your device and click Run

---

## STEP 8 — iOS Build (Cloud, No Mac Required)

Use EAS Build (free tier available):

  npm install -g eas-cli
  npx cap add ios  ← generates the ios folder (structure only, can't compile on Windows)

Then use one of these cloud services to compile:

  OPTION A: Ionic Appflow (easiest Capacitor integration)
  → https://ionic.io/appflow
  → Connect your GitHub repo, trigger iOS build in dashboard

  OPTION B: Codemagic (generous free tier)
  → https://codemagic.io
  → Supports Capacitor natively, builds .ipa files

  OPTION C: GitHub Actions + macOS runner
  → Use the workflow file provided below (github-actions-ios.yml)

---

## STEP 9 — Making Updates

Every time you edit your React code:

  npm run build
  npx cap sync

Then re-run on your device/emulator.

---

## TROUBLESHOOTING

"npx cap sync fails" → Make sure you ran npm run build first
"Android device not found" → Check USB Debugging is enabled
"Gradle build fails" → Open Android Studio, let it finish downloading SDK components
White screen on device → Check vite.config.js has base: './'
