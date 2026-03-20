# CLAUDE.md — Arena Protocol
# Claude Code instructions. Read this file automatically at the start of every session.

---

## SESSION OPEN PROTOCOL (run automatically on every session start)

1. Read `CONTEXT.md` from repo root
2. Read `CHANGELOG.md` from repo root
3. State the following before any work begins:
   - Current version (from CONTEXT.md)
   - Active branch (`git branch --show-current`)
   - Git status (`git status --short`)
   - One-line summary of what "Up Next" says
4. If branch is not `main`, flag it and ask Tom to confirm before proceeding
5. If git status is not clean, list dirty files and ask Tom how to proceed

Do not begin any feature work until this checklist is complete and confirmed.

---

## FEATURE → FILE MAP
# Used to determine blast radius of any change and generate targeted device test scripts.

| Feature | Primary Files |
|---|---|
| Arena timer (active session) | `ActiveSessionView.swift`, `CircularTimerView.swift` |
| Session config (quest, duration, sub-arenas) | `SelectView.swift` |
| Home screen + arena grid | `HomeView.swift`, `ArenaCardView.swift` |
| Timer pill (minimize-to-background) | `HomeView.swift`, `DataStore.swift` (activeSession) |
| Stash & stack sessions | `DataStore.swift` (stackedSessions), `ActiveSessionView.swift`, `HomeView.swift` |
| Joint arenas | `ActiveSessionView.swift`, `DataStore.swift` (JointArenaEntry) |
| Live Activity / Dynamic Island | `ActiveSessionView.swift`, `ArenaProtocolWidgetLiveActivity.swift`, `ArenaLiveActivityAttributes.swift` |
| Lock screen banner | `ArenaProtocolWidgetLiveActivity.swift` |
| Home screen widgets (WidgetKit) | `ArenaProtocolWidget.swift`, `SharedStore.swift` |
| Navigation / routing | `RootView.swift` |
| Deep link handling | `RootView.swift` (onOpenURL) |
| Data models + persistence | `DataStore.swift` |
| Arena editor (CRUD) | `ArenaEditorView.swift` |
| Protocols + block timer | `ProtocolsView.swift` |
| Morning check-in | `MorningCheckinView.swift` |
| Wind-down ritual | `WindDownView.swift` |
| Habit manager | `HabitManagerView.swift` |
| History + stats | `HistoryView.swift` |
| Notes | `NotesView.swift` |
| Settings | `SettingsView.swift` |
| Stuck flow | `StuckView.swift` |
| Google Calendar integration | `CalendarManager.swift`, `SelectView.swift`, `ActiveSessionView.swift` |
| Interval timers | `IntervalTimerView.swift`, `DataStore.swift` (INTERVAL_PRESETS) |
| Gamification / Forge | `DataStore.swift` (seenDrops, Forge marks, titles) |
| App shortcuts bar | `AppShortcutsBar.swift` |
| Ember drop modal | `EmberDropModal.swift` |
| Grain overlay + color system | `RootView.swift` |
| Idle Live Activity | `DataStore.swift` (startIdleActivity), `HomeView.swift`, `ArenaProtocolWidgetLiveActivity.swift` |
| What's New screen | `WhatsNewView.swift` |

---

## REGRESSION RULES
# These rules apply to every session, regardless of what was changed.

- **Never remove a feature** that exists in CONTEXT.md's Screen Inventory without explicit instruction from Tom
- **Never rename a Screen enum case** without updating every reference in RootView.swift and all callers
- **Never change DataStore property names** without updating every view that reads them
- **Never modify SharedStore.swift** without checking both the main app target and widget extension target compile
- **Never change ArenaLiveActivityAttributes** without verifying both `ActiveSessionView.swift` and `ArenaProtocolWidgetLiveActivity.swift` are updated in sync
- **Never edit project.pbxproj directly** unless adding a new source file — flag this to Tom and list exactly what was changed
- If a file in the widget extension is touched, flag: "⚠️ Widget change — requires physical device test. Simulator does not support Live Activities."

---

## `/wrap` COMMAND
# Tom types `/wrap` when a session is complete. Run the full closing protocol below.

### Step 1 — Diff summary
Run `git diff --name-only HEAD` and list every file changed this session with a one-line description of what changed in each.

### Step 2 — Blast radius analysis
Cross-reference changed files against the FEATURE → FILE MAP above.
List every feature that was touched, directly or indirectly.

### Step 3 — Regression check
For each feature in the blast radius, state:
- ✅ Unaffected (change was additive only)
- ⚠️ Potentially affected (logic or state touched) — flag for device test
- ❌ Broken (compile error or clear logic fault detected)

### Step 4 — Device test script
Generate a minimal, specific test script for Tom to run on iPhone 17 Pro Max.
Only include flows that are in the blast radius. Format:

```
DEVICE TEST — vX.X.X
Before testing: uninstall app → clear DerivedData → build via Xcode → install

[ ] <specific thing to tap and what to verify>
[ ] <specific thing to tap and what to verify>
...

⚠️ WIDGET/LIVE ACTIVITY CHECKS (device only):
[ ] <specific Live Activity or Dynamic Island state to verify>
```

### Step 5 — Compile check
Run:
```bash
cd ios && xcodebuild -project ArenaProtocol.xcodeproj \
  -scheme ArenaProtocol \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  -derivedDataPath /tmp/arena-build \
  CODE_SIGNING_ALLOWED=NO clean build 2>&1 | grep -E "error:|warning:|BUILD"
```
Report: errors (must fix before push), warnings (flag but don't block).

### Step 6 — Update CHANGELOG.md
Prepend a new version entry at the top of the `## Unreleased` section (or create it).
Format exactly:
```
## vX.X.X — YYYY-MM-DD
**One-line summary of what this session built.**

### Features (if any)
- ...

### Bug Fixes (if any)
- ...

### Internal (if any)
- file.swift — what changed
```
Version bump rule: patch (x.x.+1) for bug fixes, minor (x.+1.0) for new features, major (+1.0.0) only on instruction.

### Step 7 — Update CONTEXT.md
Update exactly these sections:
- `> Last updated:` timestamp at the top
- Version History table — add new row
- Up Next — remove completed items, reorder if needed
- Known Issues — add any new issues discovered, remove resolved ones
- Screen Inventory — update any screen that changed behavior

Do not rewrite sections that didn't change.

### Step 8 — Commit
```bash
git add CONTEXT.md CHANGELOG.md
git add -p   # stage only the intentional source file changes
```
Propose a commit message in this format:
`vX.X.X: <what was built in one line>`

Wait for Tom to confirm before running `git commit` and `git push`.

### Step 9 — Final state report
Print:
```
SESSION CLOSED
Version: vX.X.X
Branch: main
Files changed: N
Features in blast radius: [list]
Device tests required: Y/N
CONTEXT.md: updated
CHANGELOG.md: updated
Git: ready to push / pushed
```

---

## HARD RULES (never violate)

1. Never run `git push` without Tom's explicit confirmation
2. Never use `git add .` — always stage file by file
3. Never auto-increment the version without showing Tom the proposed number first
4. Never rewrite CONTEXT.md from scratch — surgical edits only
5. If a `/wrap` step fails (compile error, merge conflict, dirty state), stop and report before continuing
6. Always flag widget/Live Activity changes for physical device verification — simulator is not sufficient
7. If unsure whether a change is in scope, ask before writing code
8. **Before editing any file, always declare:**
   - 📄 File: `filename.swift`
   - ✏️ Changing: exact description of what is being added/modified/removed
   - 🚫 Not touching: what is explicitly being left alone in that file
   
   Wait for Tom to confirm ("yes", "go", "ok", or similar) before writing any code.
   If multiple files need changing, declare all of them upfront as a grouped plan before touching any.

---

## MACHINE CONTEXT

| Machine | Role |
|---|---|
| Windows 11 desktop | Claude Code — feature development, file edits, git operations |
| MacBook Air | Xcode — building, signing, device deployment |
| iPhone 17 Pro Max | Primary test device |

**Three-way rule:** Claude Code pushes → `git pull` on MacBook before Xcode. Xcode config changes → `git push` immediately after.

**DerivedData clear command (run on MacBook when build behaves unexpectedly):**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/ArenaProtocol-*
```

**Phone install procedure:**
1. Uninstall app from iPhone
2. Clear DerivedData (above)
3. Build and run via Xcode → direct install to device
