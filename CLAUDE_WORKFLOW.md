# CLAUDE_WORKFLOW.md — Developer Iteration Procedure
> How to work with Claude on Arena Protocol efficiently.
> Read once. Reference the Quick Cards at the bottom daily.

---

## THE CORE PRINCIPLE

Claude has no memory between sessions. Every session starts blank.
Your job is to give Claude a precise snapshot of reality before asking for anything.
The better the snapshot → the better the output → the fewer correction rounds.

**The 3-part formula for every request:**
```
CONTEXT + INTENT + CONSTRAINT
```
- **Context** — what exists right now (paste CONTEXT.md, quote the relevant file)
- **Intent** — what you want done, precisely
- **Constraint** — what must not change, which files to touch, style rules

---

## PART 1 — SESSION STARTUP (Always Do This)

### Step 1: Paste CONTEXT.md
Open a new Claude session. First message:

```
[paste full contents of CONTEXT.md]

---

Ready. Here's what I need today:
[your request]
```

This costs ~2000 tokens and saves you 10+ rounds of "what file is the timer in?"

### Step 2: Add the relevant file if needed
If your task touches a specific file, paste it too:

```
[CONTEXT.md contents]

Here is the current HomeView.swift:
[paste file contents]

Task: [your request]
```

For a bug fix or edit, always paste the exact file. Claude should not guess at existing code.

### Step 3: State the task with the 3-part formula

**Bad prompt:**
> "Fix the habit streak bug"

**Good prompt:**
> **Context:** HomeView.swift line 47 calls `store.streak(for:)` and displays it on the arena card.
> **Intent:** The streak number shows 1 when it should show 0 on days with no session. Fix `getStreakForArena()` in DataStore.swift so it returns 0 when the most recent session is not from today or yesterday.
> **Constraint:** Do not touch any other function. Do not change the return type. Keep the existing loop structure.

---

## PART 2 — TASK TYPES AND HOW TO PROMPT EACH

### 2A — Adding a New Feature

**Template:**
```
[CONTEXT.md]

TASK TYPE: New feature

FEATURE: [name]

WHAT IT DOES:
[2-3 sentences describing user-visible behavior]

WHERE IT LIVES:
- New file: ios/ArenaProtocol/Views/[Name]View.swift
- New case in Screen enum (RootView.swift): case [name]
- Add navigate(.[name]) button in [HomeView / SettingsView / etc.]
- DataStore changes needed: [yes/no — describe if yes]

DESIGN RULES (always apply):
- Dark background #080810
- Monospaced font (system, .monospaced design)
- Uppercase labels with letter-spacing
- Colors from CONTEXT.md palette only
- Back button: Text("← BACK") top-left, padding top 52

DO NOT TOUCH: [list files to leave alone]
```

**Example — adding a Streak Calendar screen:**
```
FEATURE: Streak Calendar

WHAT IT DOES:
Shows a month-grid calendar where each day is colored by the arena(s)
completed that day. Tapping a day shows a list of sessions from that date.

WHERE IT LIVES:
- New file: ios/ArenaProtocol/Views/StreakCalendarView.swift
- New Screen case: case streakCalendar
- Add button in HistoryView.swift tabBar alongside existing tabs

DataStore changes: none — read from store.sessions

DO NOT TOUCH: DataStore.swift, HomeView.swift
```

---

### 2B — Fixing a Bug

**Template:**
```
[CONTEXT.md]
[paste the full file containing the bug]

TASK TYPE: Bug fix

BUG:
[What the user sees] vs [what should happen]

LOCATION:
File: [filename], approx line [N]
Function: [functionName]

REPRODUCTION:
1. [step]
2. [step]
3. [result]

ROOT CAUSE (if known):
[your theory, or "unknown — investigate"]

CONSTRAINT:
Fix only this function. Do not refactor surrounding code.
```

**Example:**
```
BUG:
The wind-down progress bar jumps to 100% on step 1 instead of filling
gradually as steps complete.

LOCATION:
File: WindDownView.swift, approx line 30
Variable: progress (Double)

ROOT CAUSE:
`progress` is computed as `step / max(totalSteps - 1, 1)`.
When `totalSteps` is 1 (no habits), denominator is 1 and step 0/1 = 0, step 1/1 = 1 — jumps to full.

CONSTRAINT: Fix the computed property only.
```

---

### 2C — Revising / Iterating on Claude's Output

When Claude gives you code that's 80% right, **do not start over**.
Use a targeted correction prompt:

**Template:**
```
Good, but [specific problem].

Current code (your output):
[paste the specific function or block that's wrong]

Problem:
[exactly what's wrong — one issue at a time]

Fix only this part. Keep everything else identical.
```

**Rules for correction rounds:**
- One issue per message. Don't bundle "also fix X and Y and Z" — you'll get regression.
- Quote the exact lines you want changed. Don't say "the timer part" — paste the timer code.
- If Claude misunderstood the intent, restate the intent before asking for a fix.
- Max 3 correction rounds before restarting the task with a cleaner prompt.

---

### 2D — Refactoring / Cleanup

Keep these prompts small in scope. Refactors are high-regression-risk.

**Template:**
```
[CONTEXT.md]
[paste the file]

TASK TYPE: Refactor

SCOPE: [function name / section only — never "the whole file"]

WHAT TO CHANGE:
[specific technical change — e.g. "extract the duration picker into a DurationPickerView component"]

WHAT MUST NOT CHANGE:
- External API / function signatures
- Behavior visible to the user
- Other files (do not create new files unless explicitly listed)

OUTPUT: Show only the changed function/section, not the entire file.
```

---

### 2E — Debugging a Build / Test Failure

**Template:**
```
[CONTEXT.md]

TASK TYPE: Build error

ERROR OUTPUT (exact):
[paste the full error from Xcode / swift build / CI log]

FILE: [which file the error points to]
LINE: [line number if shown]

CURRENT CODE AT THAT LINE:
[paste 10 lines around the error]

Fix the error. Explain in one sentence what caused it.
```

**Pro tips for build errors:**
- Always paste the full error, not a summary. "it says something about optionals" is useless.
- For Swift type errors, paste the function signature AND the call site.
- For CI failures, paste the raw log section, not the GitHub Actions summary.

---

## PART 3 — THE DAILY ITERATION LOOP

```
┌─────────────────────────────────────────────────┐
│  1. WRITE                                        │
│     Edit in VS Code / paste into Claude          │
│     One feature or one fix per session           │
├─────────────────────────────────────────────────┤
│  2. VALIDATE LOCALLY (if Swift for Windows)      │
│     swift test --filter [SuiteName]              │
│     swift build (catches type errors, no UI)     │
├─────────────────────────────────────────────────┤
│  3. PUSH                                         │
│     git add ios/ && git commit -m "feat/fix: …" │
│     git push origin claude/swift-ios26-…         │
├─────────────────────────────────────────────────┤
│  4. WATCH CI                                     │
│     gh run watch                                 │
│     OR check Codemagic dashboard                 │
├─────────────────────────────────────────────────┤
│  5. IF CI FAILS → paste error into Claude        │
│     Use 2E template above                        │
├─────────────────────────────────────────────────┤
│  6. IF CI PASSES → install on device             │
│     Download artifact → AltStore or Diawi        │
├─────────────────────────────────────────────────┤
│  7. UPDATE CONTEXT.md                            │
│     Add the new screen/feature, update Known     │
│     Issues, move completed item off Up Next      │
└─────────────────────────────────────────────────┘
```

**Target cadence:** One complete loop per feature. Commit early, fix in CI, not locally.

---

## PART 4 — CONTEXT.md MAINTENANCE PROTOCOL

CONTEXT.md is only useful if it's current. Update it every time you ship something.

### When to update CONTEXT.md

| Event | What to update |
|---|---|
| New screen added | Screen Inventory table + File Map |
| New data field on a model | Key Data Structures section |
| Bug fixed | Remove from Known Issues |
| Feature shipped | Move from Up Next to Version History |
| New UserDefaults key | UserDefaults Keys table |
| Color added to palette | Color Palette Reference |

### How to update it with Claude

```
Here is the current CONTEXT.md:
[paste]

I just shipped: [feature name]
- New file: [path]
- New screen: [name] — [what it does]
- Changed model: [what changed]
- Fixed bug: [which one from Known Issues]
- Next up: [new item for Up Next]

Update CONTEXT.md to reflect this. Return the full updated file.
```

Commit the update immediately after:
```bash
git add CONTEXT.md && git commit -m "docs: update CONTEXT.md — [feature]"
```

---

## PART 5 — PROMPT PATTERNS THAT WORK WELL FOR THIS CODEBASE

### Pattern: "Show me only the changed part"
Prevents Claude from rewriting untouched code and introducing drift.

```
Return only the modified function/section.
Do not return the full file.
I will paste it into place manually.
```

### Pattern: "Explain before you code"
Catches misunderstandings before wasted code is written.

```
Before writing any code, explain in 2-3 sentences:
1. What you're going to change
2. Which files you'll touch
3. Any tradeoff or assumption

Wait for my confirmation before writing code.
```
Use this for anything touching DataStore.swift or RootView.swift (high blast radius).

### Pattern: "Write the test first"
Useful when adding logic to DataStore.swift.

```
Write the unit test for [function] first, in ArenaProtocolTests.swift.
Use the @Test and @Suite format already in the file.
Then write the implementation that makes it pass.
```

### Pattern: "Match the existing style exactly"
Critical for SwiftUI views — style inconsistency is the #1 source of visual bugs.

```
Match the exact style of the existing cards in HomeView.swift:
- .font(.system(size: X, design: .monospaced))
- .foregroundStyle() not .foregroundColor()
- .buttonStyle(.plain) on all buttons
- RoundedRectangle(cornerRadius: N).strokeBorder() for borders
- Color(hex: "#XXXXXX") for all colors — no .red, .blue, etc.
```

### Pattern: "Scope creep guard"
Stops Claude from "improving" things you didn't ask about.

```
Important: Do not add error handling, comments, or docstrings to code
you did not change. Do not rename variables. Do not reformat existing lines.
Minimal diff only.
```

### Pattern: "Multi-file change with explicit contract"
When a feature spans multiple files, be explicit about what each file does.

```
This change touches 3 files:
1. DataStore.swift — add [field/function]. Do not change anything else.
2. HomeView.swift — add [UI element] that calls [function]. Touch only [section].
3. RootView.swift — add case [name] to Screen enum and route it to [View].

Write each file section separately, labeled clearly.
```

---

## PART 6 — THINGS TO NEVER DO

| Don't | Why |
|---|---|
| Ask Claude to "improve" a file without specifying what | You'll get random refactors you didn't want |
| Start a session without CONTEXT.md | Claude will make wrong assumptions about the stack |
| Bundle multiple unrelated fixes in one prompt | Regressions become impossible to trace |
| Say "it's broken" without pasting the error | Claude will guess and guess wrong |
| Ask for a full file rewrite to fix a 3-line bug | Massive blast radius, hard to review |
| Skip updating CONTEXT.md after shipping | Next session will be stale from the start |
| Let correction rounds exceed 3 | Restart with a cleaner prompt instead |
| Ask Claude to "make it look better" | Subjective with no spec = random output |

---

## PART 7 — COMMIT MESSAGE CONVENTIONS

Keep commits atomic. One change = one commit.

```
feat: add streak calendar screen
fix: wind-down progress bar jumps to 100% on step 1
refactor: extract DurationPickerView from SelectView
test: add habit streak edge case tests
docs: update CONTEXT.md — streak calendar shipped
chore: update codemagic.yaml build timeout
```

Commit message must describe what changed, not what you did.
- Bad: `"worked on the timer"`
- Good: `"fix: timer shows negative seconds when phone sleeps mid-session"`

---

## QUICK REFERENCE CARDS

Cut these out. Pin them near your monitor.

---

### CARD 1 — Session Startup Checklist
```
□ Open CONTEXT.md → copy all
□ Paste as first message in new Claude session
□ Paste the relevant file if touching specific code
□ State task using: CONTEXT + INTENT + CONSTRAINT
□ Ask Claude to explain plan before writing code (for big changes)
```

---

### CARD 2 — Prompt Formula

```
CONTEXT:  [CONTEXT.md] + [paste the file]
INTENT:   [exactly what to change, with file + line if known]
CONSTRAINT: [what not to touch] + [style rules] + [return only changed section]
```

---

### CARD 3 — Correction Round Formula

```
Good, but [one specific problem].

Current code:
[paste the exact section that's wrong]

Fix: [one sentence describing the fix]
Keep everything else identical.
```

---

### CARD 4 — Daily Loop

```
1. Claude writes code
2. swift test (Windows) OR push + watch CI (always)
3. CI fails → paste error → Claude fixes
4. CI passes → install on device
5. Update CONTEXT.md
6. Commit CONTEXT.md
```

---

### CARD 5 — High-Risk Files (Always Use "Explain First" Pattern)

```
DataStore.swift     — all models + persistence, everything depends on it
RootView.swift      — navigation router, breaking it breaks the whole app
ArenaProtocolApp.swift — entry point, rarely needs touching
Info.plist          — URL schemes and permissions, touch with care
Package.swift       — platform targets, don't change unless upgrading iOS min
```

---

### CARD 6 — Style Rules (Paste Into Every UI Prompt)

```swift
// Fonts
.font(.system(size: N, weight: .bold, design: .monospaced))

// Colors — ALWAYS use hex, never named colors
Color(hex: "#E8C547")
Color.white.opacity(0.35)

// Borders — always strokeBorder, not stroke
RoundedRectangle(cornerRadius: 14)
    .strokeBorder(Color(hex: "#...").opacity(0.3), lineWidth: 1)

// Buttons — always plain style
Button { action() } label: { ... }
    .buttonStyle(.plain)

// Text style
.foregroundStyle()   // NOT .foregroundColor()
.kerning(N)          // spacing between letters

// Background (app)
Color(hex: "#080810")
```
