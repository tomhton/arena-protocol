# CHANGELOG — Arena Protocol

All meaningful changes to Arena Protocol are documented here.
Format: version — date — summary. Most recent version first.

---

## v2.27.0 — 2026-03-24

**Arena rank progression system + one-page HomeView overhaul.**

### Features
- **Arena Rank Tiers** — 8 rank tiers per arena based on peak consecutive-day streak: Dormant (0), Sparked (1–2d), Kindling (3–6d), Burning (7–13d), Blazing (14–20d), Inferno (21–33d), Transcendent (34–49d), Eternal Flame (50+d). Ranks are permanent high-water marks — once earned, they persist even after the streak breaks.
- **`ArenaRankState`** — new persistent model (`arenaId`, `peakStreak`, `achievedRank`, `achievedAt`). Saved to `"arena_ranks"` in UserDefaults. Updated automatically in `addSession()`.
- **Rank-based border progression** on arena cards:
  - Dormant: thin, faint border (unchanged baseline)
  - Sparked/Kindling: brighter solid borders + glowing corner accent dots
  - Burning: angular gradient stroke border
  - Blazing: pulsing angular gradient + outer glow halo
  - Inferno: double border + strong diffuse glow + white accent highlights
  - Transcendent: rotating animated gradient border + inner accent ring
  - Eternal Flame: triple-layer ornate border with counter-rotating inner ring + intense glow
- **Today's session under-glow** — vibrant arena-colored glow radiates from beneath each card, intensity scaling with number of sessions completed today (0 = none, 1 = subtle, 2 = moderate, 3 = strong, 4+ = full). Gently pulses when active.
- **Rank label** shown bottom-right of arena cards (e.g. "BLAZING").
- **Reset Rank** button in Arena Editor — shows current rank + peak streak, resets to Dormant. Ready for prestige/rebirth integration.
- **App dock restored** below intervals (mindless periods) section on HomeView.

### Changed
- `DataStore.swift` — `ArenaRankTier` enum (8 cases with border width/opacity properties), `ArenaRankState` struct, `arenaRanks` persistence, `updateArenaRank()`, `resetArenaRank()`, `seedArenaRanksIfNeeded()`. `addSession()` now calls `updateArenaRank()`.
- `ArenaCardView.swift` — new `rankTier` parameter, `rankBorderOverlay` computed property (8-way switch with layered effects), `cornerGlows()` helper, today-intensity under-glow with pulse animation, animated border rotation for transcendent+ tiers.
- `HomeView.swift` — one-page overhaul: inline session display with swipe collapse/expand, expandable arena cards, completion overlay, removed TabView paging. Arena cards now pass `rankTier` from DataStore. App shortcuts dock placed below intervals.
- `ArenaEditorView.swift` — "RESET RANK" button added above delete, shown when rank ≥ Sparked.
- `ArenaProtocolApp.swift` — calls `seedArenaRanksIfNeeded()` on foreground to initialize ranks for existing users.
- `StuckView.swift` — ArenaCardView call updated with `rankTier: .dormant`.

---

## v2.26.0 — 2026-03-24

**Schedule & deadline system for arenas and protocols.**

### Features
- **`ScheduledBlock`** — schedule a future arena session or protocol at a specific date/time. Creates a `UNUserNotificationCenter` reminder at the scheduled time. Stores `itemId`, `itemLabel`, `itemGlyph`, `itemColor`, `scheduledAt`, `durationMins`, `note`. Persisted to `"arena_schedule"`.
- **`ArenaDeadline`** — set a session-count goal for an arena with a due date (`targetSessions` + `targetDate`). Auto-marks complete when `addSession()` pushes the arena count over the target. Shows progress bar + overdue indicator. Persisted to `"arena_deadlines"`.
- **`ScheduleView`** — new full screen (`case schedule` in `Screen` enum). Three sections: _Upcoming_ (scheduled blocks with time-until, START button, × delete), _Deadlines_ (progress bar, days left, red OVERDUE / amber ≤2d warning), _Completed_ (last 3, deletable). Two creation sheets:
  - `AddScheduledBlockSheet` — toggle Arena / Protocol, item picker, `DatePicker`, duration stepper (arena only), note.
  - `AddDeadlineSheet` — arena picker, session-count stepper, due date, note.
- **HomeView "UP NEXT" banner** — appears when a scheduled block starts within 4 hours. Same visual style as the Google Calendar `nextBlockBanner`. Tapping navigates to ScheduleView.
- **HomeView SCHEDULE button** — paired with PROTOCOLS in the bottom action row (teal ⏰ pill).
- **ProtocolsView ⏰ button** — on every user protocol card, opens `ScheduleProtocolSheet` (protocol pre-filled; pick date/time + optional note).

### Changed
- `DataStore.swift` — `addSession()` now calls `checkDeadlineCompletion()` after saving. New functions: `addScheduledBlock(_:)`, `removeScheduledBlock(id:)`, `addDeadline(_:)`, `removeDeadline(id:)`, `checkDeadlineCompletion()`.
- `HomeView.swift` — `bottomButtons` PROTOCOLS row split into HStack with SCHEDULE button. `scheduledBlockBanner` view added. `nextScheduledBlock` computed property filters blocks within 4h.
- `ProtocolsView.swift` — BEGIN button text shortened to "BEGIN →"; ⏰ button added alongside it. `schedulingProtocol: ArenaProtocolModel?` state drives `.sheet(item:)`.

### New Files
- `Views/ScheduleView.swift` — `ScheduleView`, `AddScheduledBlockSheet`, `AddDeadlineSheet`.
- `ProtocolsView.swift` (appended) — `ScheduleProtocolSheet`.

---

## v2.25.0 — 2026-03-20

**Arena card custom background images.**

### Features
- **`Arena.backgroundImageName: String?`** — new optional Codable field. When set, the card loads the image by name (asset catalog first, Documents directory fallback) and renders it as a full-bleed blurred background (`.blur(radius: 12)` + 60% black overlay) behind all existing card content. When nil, card renders exactly as before.
- **Default image names** — `DEFAULT_ARENAS` and `SOCIAL_ARENA` pre-populated: `bg_alignment`, `bg_labor`, `bg_recharge`, `bg_movement`, `bg_social`.
- **`Assets.xcassets`** — new asset catalog at `ArenaProtocol/Resources/Assets.xcassets` with five placeholder imagesets (`bg_alignment`, `bg_labor`, `bg_recharge`, `bg_movement`, `bg_social`). Drop PNG files into these slots in Xcode; they appear automatically on the cards.
- **Arena editor — BACKGROUND IMAGE section** — bundled preset picker (horizontal scroll, 5 slots with live thumbnail once images are dropped in) + "CHOOSE FROM PHOTOS" button (PHPickerViewController). Photo library images are saved to the app's Documents directory and referenced by filename.

### Changed
- `DataStore.swift` — `Arena` struct gains `var backgroundImageName: String? = nil`; `DEFAULT_ARENAS` + `SOCIAL_ARENA` updated with default names.
- `ArenaCardView.swift` — `ArenaBackgroundImage` view added; rendered in card ZStack when `arena.backgroundImageName` is non-nil.
- `ArenaEditorView.swift` — `import PhotosUI` added; `BUNDLED_BG_IMAGES` constant, `loadPreviewImage`, `saveImageToDocuments` helpers, `PHImagePicker` UIViewControllerRepresentable; `populate()`/`persist()` wired.

---

## v2.22.0 — 2026-03-20

**Session intelligence backbone + Forge narrative framework. On-device, zero-API personalization.**

### New Files
- **`SessionIntelligence.swift`** — `enum UserArchetype` (10 cases: newcomer, returning, recovering, sprinter, deepWorker, streakChaser, specialist, balancer, veteran, surging); `struct SessionProfile` (25+ computed fields covering volume, momentum, time-of-day, arena affinity, streaks, sequences, social ratio, archetype); `func buildSessionProfile(from:arenas:)` — pure function, zero side effects.
- **`ForgeEngine.swift`** — `struct ForgeNarrative` (id, glyph, headline, flavor, category, urgency) + `toEmberDrop()` for existing modal pipeline; `enum ForgeEngine` with 17 narrative branches across 7 priority tiers; `extension ForgeEngine { enum Queries }` — 25 testable pure boolean classifiers including `suggestedArena(forHour:profile:)` and `suggestedDuration(arenaId:profile:)`.
- **`AI_BRAIN_MAP.md`** — developer reference: data flow diagram, SessionProfile field guide with use cases, ForgeEngine narrative catalogue with trigger conditions, full Queries API, UI integration points, extension roadmap.

### Changed
- **`DataStore.swift`** — `var sessionProfile: SessionProfile { buildSessionProfile(from:arenas:) }` computed var added. `checkAndClaimEmberDrop()` now runs `ForgeEngine.evaluate()` first (personalized narratives), falls back to legacy `checkEmberDrop()` (EMBER_DROPS) if no forge narrative qualifies.

### Forge narrative catalogue (17 total)
| Tier | Drop IDs |
|---|---|
| First contact | `forge_debut`, `forge_first_{arenaId}` |
| Volume milestones | `forge_global_{5,10,25,50,100,200,365}`, `forge_arena_{id}_{3,7,13,21,33,50,77,111}` |
| Streak milestones | `forge_streak_{3,7,14,21,30,60,100}` |
| Momentum | `forge_comeback`, `forge_surge` |
| Balance | `forge_all_arenas`, `forge_balancer`, `forge_multistreak` |
| Behavioral patterns | `forge_deep_worker`, `forge_sprinter`, `forge_specialist_{id}`, `forge_social` |
| Ambient nudges | `forge_reflective`, `forge_neglect_{arenaId}` |

---

## v2.21.0 — 2026-03-20

**Home UX rework: unified layout with session info inline, iOS-style jiggle edit mode for arena grid.**

### Features
- **Unified home layout** — IDEAS, STATS, SETTINGS, and session total are now inline in each tab's own content header (not a fixed overlay). No empty space left of the nav buttons.
- **CURRENTLY IN tab: full timeline** — shows the live countdown with "ENDS [HH:MM]" beneath the timer, then a TIMELINE section listing every future arena slot with `start → end` clock times in the user's configured timezone.
- **CURRENTLY IN tab: stacked sessions** — each stacked session shown with its own countdown + "ENDS [HH:MM]" clock time.
- **iOS-style jiggle edit mode** — arena grid stays in 2-column layout in edit mode. Cards shake with a shared `editShakeAngle` animation. Tapping a card in edit mode navigates to the arena editor. An ADD card appears inline below the grid. No more jarring switch to a list of 4.

### Internal
- `HomeView.swift` — `editReorderList` removed entirely; `twoColumnGrid` handles both normal and edit states; `navButtonsRow` computed var shared between tabs; `formattedStartTime()` uses `store.settings.clockTimezone`; `@State editShakeAngle: Double` drives `repeatForever` shake via `.onChange(of: editMode)`

---

## v2.20.0 — 2026-03-20

**App shortcuts dock with curated app catalog and edit mode.**

### Features
- **Scrollable app dock** — replaces the static 6-button shortcuts bar with a horizontal scroll row of rounded-square icons (56 pt, iOS app icon style) each showing an SF Symbol in the app's brand color plus name label below.
- **Long-press edit mode** — long-pressing the dock enters edit mode: icons shake, × delete buttons appear on each icon, and a + add button appears at the end of the row. A DONE button exits edit mode.
- **Curated catalog of 20 apps** — Spotify, Apple Music, Audible, YouTube, Health, Google Calendar, Notion, Headspace, Nike Run Club, Strava, WhatsApp, Messages, Phone, Safari, Instagram, X, LinkedIn, Notes, Reminders, Calm. All use SF Symbols + brand colors (no App Store icons bundled).
- **Add flow** — picker sheet lists curated apps not yet in the dock. "Custom…" row opens a form for name, URL scheme, and SF Symbol to add any app.
- **Persistent dock** — `store.dockApps: [DockApp]` saved to `arena_dock_apps` in UserDefaults. Default dock: Spotify, Audible, Health, YouTube, Notes, Calendar.

### Internal
- `DataStore.swift` — `DockApp: Identifiable, Codable` struct; `DEFAULT_DOCK_APPS` (6-app constant); `var dockApps`, `func saveDockApps()`
- `AppShortcutsBar.swift` — full replacement: `CURATED_DOCK_APPS` (20-app catalog), `AppShortcutsBar` (scroll + long-press + DONE), `DockIconView` (56 pt icon + shake + × delete), `AddDockButton`, `DockAppPickerSheet` (curated list + custom form)
- `Info.plist` — `LSApplicationQueriesSchemes` expanded to cover all 20 curated app URL scheme prefixes

---

## v2.19.0 — 2026-03-20

**Live Activity arena transitions work from anywhere — no longer require the session screen to be open.**

### Bug Fixes
- **Live Activity frozen on arena transition** — the lock screen banner, Dynamic Island, and HomeView session banner would all freeze at the previous arena's timer (counting into positive) whenever the user navigated away from the active session screen. They would only correct when the user tapped the banner and re-opened the session view. Root cause: `tick()` in `ActiveSessionView` was the sole arena-transition detector and only ran while that view was in the navigation stack.
- **HomeView banner slow to switch arenas** — the session banner's `sessionNow` clock ticked every 5 seconds, meaning up to 5 seconds of stale display after an arena transition.

### How it works now
- `DataStore.syncLiveActivity(now:)` is a new method that reads `activeSession ?? stackedSessions.first`, calls `currentSlot(now:)`, and pushes an updated ContentState to all live activities only when the active arena has changed. Guarded by `liveArenaId` to prevent no-op pushes.
- HomeView's session timer reduced from 5 s → 1 s. Every tick calls `store.syncLiveActivity(now:)`. Since HomeView is the root of the `NavigationStack` and is never removed from the hierarchy, this timer runs continuously — whether the user is on the session screen, the home screen, or any other screen.
- `ActiveSessionView` seeds `store.liveArenaId` on session start and on each `tick()` transition so the DataStore tracker stays in sync and doesn't double-push when the session view is active.

### Internal
- `DataStore.swift` — `var liveArenaId: String`, `func syncLiveActivity(now:)` (inside `#if canImport(ActivityKit)`)
- `HomeView.swift` — `Timer.publish(every: 1)` replaces 5 s; `store.syncLiveActivity(now: t)` called each tick
- `ActiveSessionView.swift` — `store.liveArenaId = arena.id` seeded on setup and on `tick()` transition

---

## v2.18.0 — 2026-03-20

**Xcode build fix + Live Activity arena identity on transition.**

### Bug Fixes
- **"Multiple commands produce .app" build error resolved** — the main app target's `Debug` and `Release` build configurations were missing `PRODUCT_NAME = ArenaProtocol`. Xcode was producing an unnamed `.app` bundle, triggering a duplicate-output conflict at link time. Added `PRODUCT_NAME = ArenaProtocol` to both configs in `project.pbxproj`.
- **Live Activity arena name/color now updates on arena transition** — `arenaLabel`, `arenaColor`, `arenaIcon` were in the static `ActivityAttributes` struct; ActivityKit does not allow updating static attributes after `Activity.request`. Moved all three to `ContentState` so `Activity.update()` can push new arena identity. `tick()` in `ActiveSessionView` detects transitions via `liveArenaId` comparison and fires an update exactly when the active slot changes.

### Internal
- `project.pbxproj` — `PRODUCT_NAME = ArenaProtocol` added to Debug and Release build configuration blocks for the main app target
- `ArenaLiveActivityAttributes.swift` — `arenaLabel`, `arenaColor`, `arenaIcon` moved from static `ActivityAttributes` to `ContentState` (with defaults)
- `ActiveSessionView.swift` — `updateLiveActivity()` always includes arena identity; `currentLiveArena()` resolves active joint or falls back to primary; `@State liveArenaId` tracks last-pushed arena for transition detection
- `ArenaProtocolWidgetLiveActivity.swift` — all `context.attributes.arenaLabel/Color/Icon` → `context.state.arenaLabel/Color/Icon`
- `StuckView.swift` / `ProtocolsView.swift` — updated activity start/pause to put arena identity fields in `ContentState`

---

## v2.17.0 — 2026-03-20

**Timeline-based session banner — CURRENTLY IN + UP NEXT.**

### Features
- **Session timeline backend** — `ActiveSessionState` gains three new computed helpers: `timeline` (ordered `[(arena, start, end)]` slots for primary + all joints), `currentSlot(now:)` (slot where `start ≤ now < end`), `nextSlot(now:)` (slot immediately after current, or first upcoming). Works for any arena combination: primary-only, primary + N joints, stacked sessions with their own joints.
- **"CURRENTLY IN" label** — replaces "IN SESSION". Always shows whichever arena is running right now regardless of whether it is the primary or a joint that has taken over.
- **Big current-arena row is timeline-driven** — icon, label, subtitle, countdown, and color all pull from `currentSlot`. When Work ends and Recovery begins, the entire big row switches automatically: new icon, new label, new color, new live countdown.
- **UP NEXT row** — single focused row below the current arena showing the next slot's icon, label, duration, and a live `in X:XX` countdown to when it starts. `+N MORE QUEUED` indicator appears if additional slots exist beyond the next one.
- **Stacked sessions also timeline-aware** — the STACKED sub-rows use `currentSlot(now:)` so a stacked session with its own joints surfaces the correct currently-running arena.
- **All controls follow the live arena** — accent bar, background tint, PAUSE button color all track `liveColor` from `currentSlot`, not the primary arena's static color.

### Internal
- `DataStore.swift` — `extension ActiveSessionState` with `timeline`, `currentSlot(now:)`, `nextSlot(now:)`
- `HomeView.swift` — `sessionBanner` fully rewritten around `currentSlot`/`nextSlot`; `currentlyRunningArena` simplified to delegate to `currentSlot`; legacy `primaryIsDone`, `primaryOwnEnd`, `runningColor` intermediate vars removed

---

## v2.16.0 — 2026-03-19

**Live session banner — per-arena timers, running-arena color tracking.**

### Features
- **Live joint timers on main menu** — each arena in the JOINT QUEUE now has a fully live timer. Pending joints show `in X:XX` counting down to their start (using SwiftUI's live `.timer` text style). When a joint becomes active it switches to its own countdown in its arena color, rendered bold at a larger size with a subtle background highlight. When elapsed, shows "done" muted.
- **Primary row "DONE" state** — once the primary arena's time is up and a joint has taken over, the primary row dims to 35% opacity and swaps its timer for a muted "DONE" label. No more expired/backwards counter.
- **Banner tracks the currently-running arena** — the top accent bar and section background now animate to the color of whichever arena is running right now (primary or an active joint). Transitions smoothly via `easeInOut(duration: 0.5)`.
- **5-second clock in HomeView** — `sessionNow` state ticks every 5 s when any session is active, driving branch switches (pending → active → done) for all joint rows and the `primaryIsDone` flag without full-view polling.

### Internal
- `HomeView` — added `@State private var sessionNow: Date`, `onReceive(Timer.publish(every: 5))`, `primaryIsDone`, `runningColor` computed from `sessionNow`; joint ForEach uses `sessionNow` for `isRunning`/`isDone` states

---

## v2.15.0 — 2026-03-19

**Event type distinction across HomeView, Active Session, and Live Activity.**

### Bug Fixes
- **Joint arena individual timers** — each joint arena in the JOINT QUEUE section now shows its own individual countdown: if not yet started shows "in Xm", if active shows a live `.timer` countdown in the arena's color, if elapsed shows "done". Previously all joints showed a static `+Xm` duration label.
- **Primary timer shows primary-only end time** — the large countdown on the primary row now counts down to when the primary arena ends (handoff point to first joint), not to the combined session end. When joints are queued, a small `TOTAL Xm` label appears below the subtitle.
- **Color flood tracks currently-running arena** — the background color tint now switches to whichever arena is actually running at the current moment based on `scheduledStart`/`scheduledEnd`. When Recovery takes over from Work, the flood color updates to Recovery's color.

### Features
- **PRIMARY / JOINT / STACKED labels** — three types of running arenas are now visually distinct everywhere:
  - **PRIMARY** — the active foreground session
  - **JOINT** — arenas queued after the primary via + ADD ARENA
  - **STACKED** — sessions minimized via swipe-down running independently
- **HomeView session banner** — "JOINT QUEUE" section header with icon + label + `+Xm` queued duration; "STACKED" section header above independent sessions; arena count includes joint arenas
- **ActiveSessionView breakdown** — `PRIMARY` pill tag on the first row, `JOINT` pill tag on each joint row, shown inline next to the arena label
- **Live Activity lock screen** — `+N JOINT` badge next to the arena label when joint arenas are queued
- **Dynamic Island expanded bottom** — `PRIMARY + N JOINT` indicator when joints are active

### Internal
- `ArenaLiveActivityAttributes.ContentState` — added `jointCount: Int = 0` (default, backwards-compatible)
- `ActiveSessionView.updateLiveActivityEndTime()` — passes `jointEntries.count` as `jointCount` on every update
- `ArenaProtocolWidgetLiveActivity.swift` — lock screen banner and expanded bottom consume `jointCount`

---

## v2.14.0 — 2026-03-19

**Multi-arena session banner. Stacked sessions in header. Bug fixes.**

### Features
- **Multi-arena banner** — when sessions are stacked (swipe-down stash), all running arenas are shown in the top banner instead of bottom pills. Active session displays large (icon + name + live countdown + subtitle + PAUSE/RESUME). Each stacked session appears as a sub-row with its own countdown; tap any to bring it to foreground.
- **Stacked-only state** — if the active session was stashed and no new one started, the first stacked arena is shown as the muted primary row with "STACKED — TAP TO RESUME". Tapping unstashes it and navigates to the timer.
- **Arena count label** — banner shows "IN SESSION · N ARENAS" when multiple arenas are running.

### Bug Fixes
- **Banner reverts to idle on stash** — `headerSection` previously only triggered when `store.activeSession != nil`. Swipe-down stash moves the session to `stackedSessions` (setting `activeSession = nil`), which caused the idle "ENTER THE ARENA" header to appear. Now triggers `sessionBanner` whenever `activeSession != nil || !stackedSessions.isEmpty`.
- **Color flood now covers stacked-only state** — background tint tracks the primary or first-stacked arena color.
- **Bottom session tray removed** — pills, egg bonus badge, and abandon confirmation dialog removed from HomeView; banner is the single source of truth for all running arenas.

### Internal
- `HomeView.swift` — `sessionBanner` replaces `activeBanner` + bottom tray; `timerPill`, `stackedPill`, `showAbandonConfirm` removed; color flood generalized to `activeSession?.arena ?? stackedSessions.first?.arena`

---

## v2.13.0 — 2026-03-19

**Arena renames. Arena icon on home screen cards.**

### Features
- **Arena renames** — default arenas renamed for clarity:
  - Preparation → **Alignment** (id: `alignment`)
  - Labor → **Work** (id: `work`)
  - Mental Recovery → **Recovery** (id: `recovery`)
  - Physical Activity → **Movement** (id: `movement`)
  - All default protocols updated with new arena IDs and labels.
- **Arena icon on cards** — `arena.icon` (◎ ◆ ◑ ◉) now displays on each arena card at the top-left at 18pt in the arena's color, alongside the letter. Was stored in the model but never rendered.

### Internal
- `DataStore.swift` — `DEFAULT_ARENAS` and `DEFAULT_PROTOCOLS` updated with new IDs/labels
- `ArenaCardView.swift` — icon + letter shown as `HStack` in card content

---

## v2.12.0 — 2026-03-19

**Active session banner on HomeView.**

### Features
- **Active session banner** — when a session is running, the header section is replaced by a full-width dominant banner showing: arena name (34pt bold), live countdown timer (38pt, arena color), arena subtitle, and a PAUSE / RESUME button. Tapping anywhere on the banner opens the active session screen.
- **Arena color flood** — the entire HomeView background tints with the active arena's color at 22% opacity while a session is running; fades out when no session is active.
- **Vivid top accent bar** — 4pt full-width rectangle at full arena color at the top of the banner.
- **Pause/resume from home** — PAUSE / RESUME button in the banner calls `store.togglePause()` without leaving HomeView.
- **Floating pill removed** — the bottom foreground session pill is replaced entirely by the banner. Stacked (minimized) session pills remain at the bottom.

### Internal
- `DataStore.swift` — added `togglePause()`: flips `isPaused`, recalculates `endTime` from `pausedRemaining` on resume
- `HomeView.swift` — `headerSection` now `@ViewBuilder` switching between `activeBanner(_:)` and `idleHeader`; ZStack gains arena color flood layer; session tray removes foreground `timerPill`

---

## v2.11.0 — 2026-03-19

**New arenas. Social modifier. Customisable protocols.**

### Features
- **New default arenas** — replaced the 4 default arenas with: A. Preparation (◎ #60A5FA), B. Labor (◆ #E8C547), C. Mental Recovery (◑ #A78BFA), D. Physical Activity (◉ #34D399). Default protocols updated to reference the new arena IDs.
- **Social modifier** — a `◇ SOCIAL` toggle lives on HomeView between the arena grid and shortcuts bar. Toggle it on to tag any upcoming session as social. Works as:
  - A modifier on any arena (sessions logged with `social: true`, Live Activity shows `◎` prefix, calendar events tagged `◎`)
  - A standalone session via "SOCIAL ONLY SESSION →" button (uses `SOCIAL_ARENA` synthetic arena, not shown in grid/editor)
  - Flows through `Screen.select(Arena, Bool)` → `SelectView` (read-only purple badge) → `Screen.active` → `ActiveSessionView` → `Session.social` + `calEventId`
- **Customisable protocols** — Protocols tab fully rewritten. Users can create, edit, and delete their own arena combinations (name, icon, color, list of arena+duration blocks). Each block uses a `Menu` arena picker. 8-colour palette + free-text glyph field. Running a saved protocol unchanged.

### Bug Fixes
- **Social toggle in wrong screen** — previously the social toggle was embedded per-arena in SelectView. Now it lives globally on HomeView; SelectView shows a read-only badge confirming the social state.

### Internal
- `DataStore.swift` — `SOCIAL_ARENA` constant (id: `"social"`, NOT in `DEFAULT_ARENAS`); `Session.social: Bool`; `ActiveSessionState.social: Bool`; `DEFAULT_ARENAS` and `DEFAULT_PROTOCOLS` replaced
- `RootView.swift` — `Screen.select(Arena, Bool)`, `Screen.active(Arena, Int, String, Bool)`, `Screen.complete(Arena, Int, String, Bool)` — social Bool threaded through all nav destinations
- `HomeView.swift` — `socialActive: Bool` state; `socialSection` computed view; all arena navigate calls pass `socialActive`
- `SelectView.swift` — `let social: Bool` replaces `@State isSocial`; removed interactive toggle, replaced with `socialBadge` (read-only purple pill)
- `ActiveSessionView.swift` — `let social: Bool`; `addToGCal` prefixes title with `◎` when social; joint sessions carry `social`
- `ProtocolsView.swift` — full rewrite: `ProtocolEditorView` struct with `EditableBlock`, `ForEach($blocks)`, arena `Menu` picker, colour palette, name/icon/colour fields, save/delete

---

## v2.10.0 — 2026-03-19

**Calendar ↔ app full sync. Calendar resume. Live Activity fixes.**

### Features
- **Calendar ↔ app sync** — sessions now track their `EKEvent` identifier so events can be updated or deleted when sessions change:
  - `finishEarly()` trims the primary event end to actual finish; trims joint events that started, deletes joints that hadn't begun
  - `abandonSession()` deletes the primary event if elapsed < 60s, otherwise trims to now; deletes all joint events
  - Joint removed mid-session → calendar event deleted immediately
  - Interval timers (`[INTERVAL] FLOW` etc.) create a calendar event on start, trimmed to actual end on DONE or natural complete
- **Calendar resume** — SelectView detects currently-ongoing calendar events matching the current arena (by keyword or `[ArenaName]` prefix). Shows a green "IN PROGRESS / RESUME" banner with remaining time. Tapping RESUME launches directly into the active session timer — no duration picker needed.

### Bug Fixes
- **Live Activity reverts to idle when adding joint arenas** — `addJoint` and `removeJoint` now call `updateLiveActivityEndTime()` to push the new `endTime` + `staleDate` to the running activity. Previously the activity kept the original end time and went stale when that expired.
- **Live Activity killed on swipe-down stash** — `HomeView.onAppear` was calling `startIdleActivity()` whenever `activeSession == nil`, which includes after stashing. Guard now requires `activeSession == nil && stackedSessions.isEmpty` so stacked session Live Activities survive.

### Internal
- `CalendarManager.swift` — `addEvent` returns `@discardableResult String?` (event identifier); new `updateEventEnd(id:newEnd:)` and `deleteEvent(id:)` methods; new `activeEvents()` fetches currently-ongoing events
- `DataStore.swift` — `ActiveSessionState` gains `calEventId: String?`; `JointArenaEntry` gains `calEventId: String?`, `scheduledStart: Date`, `scheduledEnd: Date`
- `ActiveSessionView.swift` — `addToGCal` stores returned ID; `addJoint` stores per-joint ID + scheduled times; `removeJoint` calls `deleteEvent`; `finishEarly` / `abandonSession` call `updateEventEnd` / `deleteEvent`; `updateLiveActivityEndTime()` helper
- `IntervalTimerView.swift` — creates calendar event on appear; `finishInterval()` updates end then navigates
- `SelectView.swift` — `ongoingMatch: EKEvent?` detected on appear; `resumeFromCalBanner` + `resumeSession()` for direct timer launch

---

## v2.9.2 — 2026-03-19

**Bug fix: calendar events now write to Google Calendar.**

### Bug Fixes
- **Calendar writes to default calendar** — Google Calendar's CalDAV account blocks programmatic calendar creation (`EKErrorDomain Code=17 "That account does not allow calendars to be added or removed."`). Dropped the custom "Arena Protocol" calendar creation entirely. Events now write directly to `store.defaultCalendarForNewEvents` — wherever the user's default is set (Google Calendar, iCloud, etc.).

### Internal
- `CalendarManager.swift` — `arenaCalendar()` simplified to one line: `return store.defaultCalendarForNewEvents`

---

## v2.9.1 — 2026-03-19

**Bug fixes: Live Activities for protocols + stuck. Calendar writes fixed.**

### Bug Fixes
- **I AM STUCK → mandatory Live Activity** — when the stuck grace period expires (or user taps "I'M READY NOW"), the lock screen activity transitions in-place to a pink ⚡ "MANDATORY / CHOOSE AN ARENA NOW" banner. No dismiss/restart gap. `isMandatory: Bool` added to `ContentState`; handled across all Dynamic Island slots and lock screen.
- **I AM STUCK grace period Live Activity** — starting the stuck timer now starts a Live Activity showing a pink countdown; idle activity is replaced.
- **Protocol Live Activity** — running a protocol now starts a block-accurate Live Activity (color + label per block, pause sync, ends on complete/abandon).
- **Calendar event titles** — replaced "[\(arena)] Focus Block" with "[\(arena)] \<task\>" so the actual quest note appears in Google Calendar. Falls back to just "[\(arena)]" when no note is set.
- **Calendar writes using default source** — `arenaCalendar()` now uses `store.defaultCalendarForNewEvents?.source` so events land in whichever calendar the user has set as default (Google Calendar, iCloud, etc.) rather than guessing by source type. `try?` replaced with `do/catch` so failures are logged instead of silently swallowed.
- **Calendar permission auto-request** — `addToGCal` now requests write access if not yet granted (handles permission reset after reinstall).

### Internal
- `ArenaLiveActivityAttributes.ContentState` — added `isMandatory: Bool = false`
- `ArenaProtocolWidgetLiveActivity.swift` — mandatory branch in lock screen banner, compact leading/trailing, expanded trailing
- `StuckView.swift` — `startStuckActivity()` on countdown start; `transitionToMandatory()` updates state in-place on timeout/ready; `endStuckActivity()` kept for abandon path
- `ProtocolsView.swift` — `startActivityForBlock()` / `endActivity()` / pause update; uses `Activity<...>.activities` static collection
- `CalendarManager.swift` — robust source selection, error logging
- `ActiveSessionView.swift` — `addToGCal` runs in Task, auto-requests permission, unified for primary + joint arenas

---

## v2.9.0 — 2026-03-19

**Protocol Live Activity. In-app changelog synced. README rewritten.**

### Features
- **Protocol Live Activity** — running a protocol now starts a Live Activity on the lock screen and Dynamic Island for each block. Block advances end the old activity and start a new one with the new block's color and label. Pause/resume syncs. Activity ends cleanly on complete, finish early, or abandon.
- **In-app changelog synced** — `WhatsNewView` updated with v2.7.0–v2.9.0 entries.

### Internal
- `ProtocolsView.swift` — `startActivityForBlock()` / `endActivity()` / pause update in `togglePause()` / end on abandon; uses `Activity<...>.activities` static collection (avoids Swift 6 sendability issues with stored references)
- `WhatsNewView.swift` — added v2.7.0, v2.8.0, v2.9.0 entries
- `README.md` — full rewrite with current stack, features, project structure, and device info

---

## v2.8.1 — 2026-03-18

**Bug fix: deleted arena reappears.**

### Bug Fixes
- **Arena delete reappear** — deleting an arena from the editor caused it to immediately reappear. `handleDelete()` called `dismiss()`, which triggered `onDisappear { persist() }`, and `persist()` re-inserted the arena because `label` was still populated. Fixed by clearing `label` before `dismiss()` so `persist()` hits its empty-label guard and exits without writing.

### Internal
- `ArenaEditorView.swift` — `handleDelete()` sets `label = ""` before calling `dismiss()`

---

## v2.8.0 — 2026-03-18

**Bug fixes: idle Live Activity countdown · long-press edit mode · drag-to-reorder.**

### Bug Fixes
- **Idle Live Activity no countdown** — idle activity `endTime` was set to `Date() + 86400`, causing a 24-hour countdown to appear on the lock screen even during active sessions. Fixed by setting `endTime` to `Date()` (no countdown rendered in idle state). Also removed redundant `endIdleActivity()` call — the session-start Task already ends all stale activities before requesting a new one.
- **Long-press edit mode** — `.onLongPressGesture` was being swallowed by the `.draggable()` system recognizer. Fixed by switching to `.simultaneousGesture(LongPressGesture(...))` so both fire correctly.
- **Drag-to-reorder arenas** — `.draggable()` + `.dropDestination()` (system drag-and-drop API) is unreliable for same-view reordering. Replaced with `List` + `.onMove` in edit mode. In edit mode the grid switches to a compact list with native iOS drag handles; the two-column grid returns when edit mode is exited. Each list row shows the arena icon, color dot, name, and an EDIT shortcut button.

### Internal
- `HomeView.swift` — `arenaGrid` splits into `editReorderList` (List + .onMove) and `twoColumnGrid`; removed `dragTarget` state, `moveArena()` function, and all `.draggable`/`.dropDestination` modifiers
- `DataStore.swift` — idle `endTime` changed from `Date() + 86400` to `Date()`
- `ActiveSessionView.swift` — removed redundant `store.endIdleActivity()` call from fresh-start path

---

## v2.7.0 — 2026-03-18

**Idle Live Activity · In-app changelog · Long-press edit mode.**

### Features
- **Idle Live Activity** — lock screen and Dynamic Island show "START THE DAY", "ENTER THE ARENA", "LOCK IN", or "CLOSE THE DAY" (time-aware) when no session is running. Activity starts automatically when HomeView appears, ends when a session starts, restarts when done.
- **What's New screen** — in-app changelog accessible from Settings → WHAT'S NEW. Shows recent version entries with headline and bullet points. Built from a hardcoded struct array (no file read required).
- **Long-press → edit mode** — long-pressing any arena card on HomeView enters edit mode with haptic feedback (replaces the need to find the EDIT ARENAS toggle). Drag-to-reorder now works directly on HomeView (previously only in ArenaListEditorView). Cards scale slightly when in edit mode for visual feedback.

### Internal
- `ArenaLiveActivityAttributes.ContentState` — added `isIdle: Bool` field
- `DataStore.swift` — `startIdleActivity()` / `endIdleActivity()` using ActivityKit
- `ArenaProtocolWidgetLiveActivity.swift` — idle branch in LockScreenBannerView, CompactLeadingView, CompactTrailingView
- `HomeView.swift` — `moveArena()` + drag-to-reorder on both grid columns; idle activity on appear
- `RootView.swift` — `Screen.whatsNew` case
- `WhatsNewView.swift` — new file

---

## v2.4.0 — 2026-03-17

**New default arenas. Expanded arena editor.**

### Features
- **New default arenas** — Alignment & Planning (blue `#60A5FA`, ◎), Execution & Mastery (gold `#E8C547`, ◆), Health & Recovery (green `#34D399`, ◉), Connection & Community (purple `#B794F4`, ◇). Each has curated subtitles, descriptions, examples, and sub-arena categories.
- **Free-text icon input** — arena editor now has a text field above the icon grid; type any emoji or Unicode character as the arena icon. CLEAR button reverts to grid selection.
- **Expanded icon grid** — `ARENA_ICONS` extended with emoji rows for focus/work, health, connection, and misc (32 → 50 icons).
- **Sub-arenas editor** — add/remove/rename sub-arena categories inline in the arena editor. Each category row expands to reveal an examples text field. Changes persist to `subArenas: [String: [String]]` on save.

---

## v2.3.1 — 2026-03-17

**State persistence across navigation.**

### Bug Fixes
- `ActiveSessionView` — joint arenas survive swipe-out and back: `addJoint`/`removeJoint` sync `jointEntries` + `endTime` to `store.activeSession`; `setup()` restores them on re-entry
- `ArenaEditorView` — swipe-back now auto-saves: `persist()` split from `handleSave()`; `onDisappear` calls `persist()`; new arenas use a stable `persistedId` to prevent duplicates

---

## v2.3.0 — 2026-03-17

**Multi-timer brainwork redesign. Mindless/interval periods.**

### Features
- **Arena breakdown card** — once a session starts, the area between the header and timer ring shows a breakdown card: one row per arena (primary + joints), each with a colored left strip, arena label, proportional time bar, `+Xm` duration label, and a × remove button. A total row appears at the bottom when joints are present. The "ADD ARENA" button lives inside this card.
- **Joint arena picker redesign** — redesigned from icon-only to a full labeled picker: horizontal arena chip scroll + horizontal duration presets (5 / 10 / 15 / 25 / 30 / 45 / 60 / other min) + CONFIRM button. Adding a joint extends `endTime` and `totalTime` live. Removing a joint contracts them.
- **Mindless/interval periods row** — horizontal scroll row on HomeView between `AppShortcutsBar` and the protocol button. Six presets: FLOW (5m), DRIFT (10m), WALK (20m), BREATHE (4m), REST (15m), RESET (30m). Teal `#4ECDC4` accent.
- **`IntervalTimerView`** — new screen. No-arena countdown timer: circular progress ring + big minute:second number + PAUSE / RESUME / DONE controls. Auto-navigates home on completion. Does not log to DataStore.

### Internal
- `DataStore.swift` — `JointArenaEntry: Identifiable` struct (`arena: Arena`, `minutes: Int`); `IntervalPreset` struct; `INTERVAL_PRESETS` constant.
- `ActiveSessionView.swift` — `jointEntries: [JointArenaEntry]` replaces `jointArenas: [Arena]`; `@State var totalTime: Int` (mutable); `addJoint(arena:minutes:)` / `removeJoint(_:)` extend/contract `endTime` and `totalTime`.
- `RootView.swift` — `case interval(String, Int)` added to `Screen` enum; routes to `IntervalTimerView`.
- `project.pbxproj` — `IntervalTimerView.swift` registered as source file.

---

## v2.2.0 — 2026-03-17

**Joint arenas. Drag-to-reorder. Color wheel.**

### Features
- **Joint arenas** — while a session is active, tap the `+` button next to the arena name to add a second (or third) arena to the session. Joint arena icons appear inline. The circular progress ring renders a full `AngularGradient` sweeping through all joined arena colors. On session end, sessions are logged for every arena in the joint.
- **Drag-to-reorder arenas** — in the arena list editor, long-press any card and drag it to a new position. Order is persisted immediately. The `letter` (A/B/C/D) auto-reassigns based on new position. Drop target dims to 60% opacity for visual feedback.
- **Color wheel** — arena editor COLOR section now has a native `ColorPicker` (full HSB wheel + sliders) above the preset swatches. Selecting a custom color via the wheel updates the live preview instantly. Preset swatches still sync back to the wheel when tapped.

### Internal
- `CircularTimerView` — signature changed from `color: Color` to `colors: [Color]`. Single-color case renders identically. Multi-color case uses `AngularGradient`. All callers updated (`ActiveSessionView`, `ProtocolsView`).
- `ActiveSessionState` — added `jointArenas: [Arena] = []` field.
- `Color.toHex()` extension added to `RootView.swift` for `ColorPicker` → hex conversion.

---

## v2.1.1 — 2026-03-17

**Swipe-back restored. Dynamic Island now shows countdown number inside ring.**

### Bug Fixes
- `RootView.swift` — `UINavigationController` extension resets `interactivePopGestureRecognizer?.delegate` to re-enable native left-edge swipe-back after hiding the toolbar (UIKit disables it when toolbar is hidden)
- `ArenaProtocolWidgetLiveActivity.swift` — compact leading `currentValueLabel` now shows live `Text(endTime, style: .timer)` countdown inside the progress ring instead of the static arena icon; paused state shows `II`; compact trailing timer bumped to 14pt bold; paused label changed to `PAUSED` text

---

## v2.1.0 — 2026-03-17

**Full SwiftUI navigation reform. Native iOS transitions. Scroll works everywhere.**

### Architecture
- `RootView.swift` — replaced `ZStack + switch screen` pattern with `NavigationStack(path:)`. Root is always `HomeView`; all other screens pushed via `path.append(Screen)`. `navigate(.home)` = `path = NavigationPath()` (pop to root). Natural iOS push/pop slide transitions. Built-in edge-swipe-back on all screens. No more root-level `highPriorityGesture` that was blocking scroll gestures app-wide.
- `Screen` enum — `.home` retained as a sentinel value (handled in `navigate()`, never pushed as a destination); all other cases unchanged
- `ArenaEditorView` — removed `navigate` parameter, now uses `@Environment(\.dismiss)` for back/save/delete. `ArenaListEditorView` keeps `navigate` closure for forward navigation.
- Active session and complete screens get `.navigationBarBackButtonHidden(true)` — no accidental pop during a timer
- Checkin: initial `NavigationPath` pre-populated with `.checkin` if not dismissed today — appears instantly, no animation jank
- `GrainOverlay` hoisted outside `NavigationStack` in outer `ZStack` — stays full-screen across all transitions

### Bug Fixes (all caused by root gesture conflict)
- Scrolling now works on every page: ArenaEditor, ArenaListEditor, WindDown, StuckView, HabitManager, History, Notes, Settings
- TextEditor fields in ArenaEditor/WindDown/StuckView no longer block outer scroll (`.scrollDisabled(true)` retained)
- Swipe-back from left edge works natively; no custom gesture code needed

### Up Next
- App redirects (Shortcuts / deep-link URLs for each screen)
- Google Calendar feed integration (read blocks → suggest sessions in SelectView)
- Forge System DataStore models + drop engine

---

## v2.0.5 — 2026-03-17

**Forge system foundation. Widget overhaul. Stash & stack sessions. Dynamic Island circle clock.**

### Features
- **Stash & Stack** — swipe down on active session to stash timer to background; supports multiple concurrent arenas running simultaneously; EGG BONUS ACTIVE badge appears on home screen when ≥2 arenas are stacked (hooks into Forge System egg drop multiplier)
- **Dynamic Island circle clock** — compact leading slot now shows a live `ProgressView(timerInterval:)` circular arc depleting in real time with arena icon inside; minimal slot shows the ring alone; replaces the plain static icon
- **Lock screen banner redesigned** — 40pt circular progress ring with arena icon replaces plain text icon; 4pt colored left strip retained; layout: ring → label+quest → countdown timer
- **Home screen widgets rebuilt** — `systemSmall` shows arena name + live countdown or session count; `systemMedium` two-column layout with arena info + timer; smart refresh (1 min when active, 15 min idle); both deep-link to active session or home
- **WidgetKit integration** — `ActiveSessionView` now calls `SharedStore.writeActiveSession` + `WidgetCenter.reloadAllTimelines()` on session start and end; widgets stay in sync with app state
- **"ENTER THE ARENA" header enlarged** — 28pt (was 22pt), removed broken `navigate(.home)` button wrapper

### Forge System (foundation)
- `FORGE_SYSTEM_ROADMAP.md` added — full spec for streak stages, egg incubation, Rebirth Island 1–10, inventory screen, 4-phase multiplayer architecture, and data model definitions
- `DataStore` — `stackedSessions: [ActiveSessionState]` added; `stashSession()`, `unstashSession(arenaId:)`, `abandonStackedSession(arenaId:)` added
- `ActiveSessionState` — `startTime: Date` added (used for progress ring math and future Forge drop timing)
- `ArenaLiveActivityAttributes` — `startTime: Date` added as static attribute

### Bug Fixes
- `SelectView.swift` — custom duration `numberPad` keyboard trap fixed: `@FocusState` + keyboard toolbar DONE button + `scrollDismissesKeyboard(.interactively)`; "other" button auto-focuses the field

---

## v2.0.4 — 2026-03-17

**Live Activity regression fixed. Compact Island sizing. Expanded layout polish.**

### Bug Fixes
1. `ArenaProtocolWidgetLiveActivity.swift` — removed inline `ArenaActivityAttributes` struct that diverged from the app's `ArenaLiveActivityAttributes`; widget was registered for the wrong type so ActivityKit couldn't match the running activity (black Dynamic Island)
2. `ArenaProtocolWidgetLiveActivity.swift` — all view structs changed from `ActivityViewContext<ArenaActivityAttributes>` to `ActivityViewContext<ArenaLiveActivityAttributes>`
3. `ArenaProtocolWidgetLiveActivity.swift` — `arenaLabel`, `arenaColor`, `arenaIcon`, `questNote` moved from `context.state.*` reads to `context.attributes.*` to match actual struct layout

### Polish
- Compact leading constrained to `.frame(width: 20, height: 20)` — prevents crowding system clock
- Compact trailing timer capped at `.frame(maxWidth: 60)`; paused dash uses `.fixedSize()`
- Expanded leading/trailing use `.frame(maxWidth: .infinity, alignment:)` instead of padding hacks; consistent `.padding(.horizontal, 12).padding(.vertical, 8)` on all expanded regions
- Expanded bottom: `lineLimit(1)`, `.foregroundColor(.secondary)`, `.padding(.horizontal, 16)`

---

## v2.0.3 — 2026-03-16

**Live Activity shipped. Debug code cleaned. Ten build/crash fixes.**

### Features
- Dynamic Island compact view: arena icon (left, arena color) + countdown timer (right, arena color)
- Dynamic Island expanded view (long-press): leading = icon + label, trailing = live countdown, bottom = quest note
- Dynamic Island minimal view: arena icon in arena color
- Lock screen / banner Live Activity: colored left strip + arena icon + label + quest note + countdown timer (or PAUSED label when paused)
- Tap on Dynamic Island or lock screen banner deep-links directly to active session via `arenaprotocol://active`
- Pause → Dynamic Island updates to show PAUSED state; resume → countdown resumes
- Done / abandon → Live Activity dismisses cleanly

### Bug Fixes
1. `ActiveSessionView.swift` — fresh-start gate added; on minimize/return, reattaches to existing `Activity` via `Activity.activities.first` instead of requesting a duplicate
2. `project.pbxproj` — widget extension `IPHONEOS_DEPLOYMENT_TARGET` corrected `26.2` → `18.6`
3. `project.pbxproj` — widget extension `GENERATE_INFOPLIST_FILE` corrected `YES` → `NO`
4. `project.pbxproj` — widget extension `SWIFT_VERSION` corrected `5.0` → `6.0`
5. `SharedStore.swift` — removed force unwrap: `UserDefaults(suiteName:)!` → `?? .standard`
6. `ArenaProtocolWidget.swift` — removed force unwrap: `Calendar.current.date(...)!` → `?? currentDate`
7. `ArenaProtocolWidgetLiveActivity.swift` — `activityBackgroundTint` changed to `Color.clear`
8. `ArenaProtocolWidgetLiveActivity.swift` — `widgetURL` added for tap deeplink (`arenaprotocol://active`)
9. `RootView.swift` — `.onOpenURL` handler added, routes `arenaprotocol://active` to active session screen
10. `ArenaProtocolWidget/Info.plist` — added `CFBundleName` and `CFBundleInfoDictionaryVersion` (required for widget extension bundle)

### Housekeeping
- `ArenaProtocolWidgetLiveActivity.swift` — all debug test code removed:
  - `compactLeading`: restored from `Text("X").foregroundColor(.red)` to arena icon in arena color
  - `compactTrailing`: restored from `Text("TEST").foregroundColor(.white)` to countdown timer (or PAUSED) in arena color
  - Lock screen banner body: restored from `Text("ALIVE").foregroundColor(.red).background(Color.yellow)` to full production layout

---

## v2.0.2 — 2026-03-16

**Minimize-to-pill UX. Session survives navigation.**

### Features
- `ActiveSessionState` struct added to `DataStore` (transient, not Codable): `arena`, `durationMins`, `note`, `endTime`, `isPaused`, `pausedRemaining`
- `DataStore` gains `var activeSession: ActiveSessionState?`, `startSession(arena:durationMins:note:)`, `endSession()`
- `ActiveSessionView.swift` — minimize button (`chevron.down`, top-trailing) navigates `.home` without ending session; session state persists in `store.activeSession`
- `ActiveSessionView.swift` — `.onAppear` resumes from stored `endTime`/`pausedRemaining` on re-entry
- `ActiveSessionView.swift` — `togglePause()` syncs pause state back to `store.activeSession`
- `HomeView.swift` — floating timer pill (280×56pt capsule, bottom-center) shows when `store.activeSession != nil`; shows arena color dot + label + live `Text(endTime, style: .timer)`; tap returns to session; ✕ shows confirmation dialog → `store.endSession()`; spring animation in/out

---

## v2.0.1 — 2026-03-16

**Xcode project created. Swift 6 fixes. On-device confirmed.**

### Fixes
- `ios/ArenaProtocol.xcodeproj` created — all 19 source files wired, shared schemes, `DEVELOPMENT_TEAM` placeholder
- `SelectView.swift` — fixed Swift 6 `if-let` ternary syntax error in `effectiveDuration`
- `Info.plist` — removed `UIApplicationSceneManifest` block (referenced non-existent `SceneDelegate`, caused launch crash)

### Verified
- Build and run confirmed on iPhone 17 Pro Max (physical device) and iOS Simulator

---

## v2.0.0 — 2026-03-13

**Full native SwiftUI rewrite. All React/Capacitor features preserved.**

### Summary
Complete rewrite from React 18 + Vite + Capacitor 6 to native Swift 6 + SwiftUI. 25 Swift source files. All features from v1.0.0 carried forward.

### Files Added
- `ArenaProtocolApp.swift` — `@main` entry point, pure SwiftUI `WindowGroup`
- `Models/DataStore.swift` — all models, persistence, gamification
- `Views/RootView.swift` — screen router, `Screen` enum, `GrainOverlay`, `Color` extensions
- `Views/HomeView.swift` — arena grid, shortcuts bar, ember particles
- `Views/SelectView.swift` — quest, sub-arenas, duration picker
- `Views/ActiveSessionView.swift` — countdown ring, pause/resume, complete flow
- `Views/ProtocolsView.swift` + `ActiveProtocolView` — multi-block protocol timer
- `Views/MorningCheckinView.swift` — 3-step morning ritual
- `Views/WindDownView.swift` — journal + habit check
- `Views/HabitManagerView.swift` — habit CRUD
- `Views/HistoryView.swift` — stats, chart, habit grid, journal, CSV/JSON export
- `Views/NotesView.swift` — idea capture
- `Views/SettingsView.swift` — wind-down time, nav to habits/arenas
- `Views/StuckView.swift` — emergency 3-phase flow
- `Views/ArenaEditorView.swift` — arena CRUD
- `Components/ArenaCardView.swift` — card + Canvas illustration + AddArenaCardView
- `Components/CircularTimerView.swift` — reusable circular progress ring
- `Components/AppShortcutsBar.swift` — 6 deep-link shortcuts
- `Components/EmberDropModal.swift` — achievement popup overlay
- `Resources/Info.plist` — bundle config, URL schemes, dark mode

---

## v1.0.0 — pre-2026

**React/Capacitor hybrid. Single-file monolith.**

- `src/App.jsx` — 1971-line React 18 + Vite + Capacitor 6 single-file app
- All core features present: arena timers, morning check-in, wind-down, habits, history, notes, settings, arena editor, stuck flow, gamification
- Build: GitHub Actions → unsigned IPA → Sideloadly (Windows)
- Status: archived. `src/` retained for reference only.
