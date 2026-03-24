# ARENA PROTOCOL — VISION BOARD

> Developer Vision Board — Living Document
> github.com/tomhton/arena-protocol
> Last updated: 2026-03-24

---

## WHERE WE CAME FROM

Started March 2026 as a React/JSX Capacitor hybrid. Full native SwiftUI rewrite completed in 10 days. Every item from the original visionboard has been shipped:

- [x] Full Swift/SwiftUI rewrite (27 screens)
- [x] Dynamic Island + Live Activity (session + protocol + idle states)
- [x] Lock screen + home screen widgets (WidgetKit)
- [x] GitHub Actions → TestFlight auto-deploy pipeline
- [x] NavigationStack with native swipe-back
- [x] Haptic feedback on arena entry/exit
- [x] CONTEXT.md, CHANGELOG.md, AI_BRAIN_MAP.md context system
- [x] Session intelligence engine (25+ behavioral metrics)
- [x] Forge narrative engine (17 narrative branches)
- [x] Schedule & deadline system
- [x] Protocol system (multi-block timed sequences)
- [x] Morning check-in + wind-down rituals
- [x] App shortcuts dock
- [x] Habit tracking
- [x] Calendar sync (EventKit read/write)
- [x] Stacking/joint arena sessions

---

## CURRENT STATUS (v2.26.0)

| | |
|---|---|
| **Platform** | Swift 6 / SwiftUI — fully native, iOS 18.0+ |
| **Build Pipeline** | GitHub Actions → Xcode archive → TestFlight (automatic on push to main) |
| **Device** | iPhone 17 Pro Max (physical) + Simulator |
| **Screens** | 27 (Screen enum in RootView.swift) |
| **Intelligence** | SessionIntelligence (25+ fields) + ForgeEngine (17 narratives) — all on-device |
| **Distribution** | TestFlight (internal) → App Store (target) |

---

## THE VISION (UPDATED)

Arena Protocol is a dark, ritualistic life-operating system. You don't open it to scroll — you open it to enter an arena and do the work. The phone becomes a tool, not a distraction. The lock screen and Dynamic Island always reflect where you are in your day, not what notification is pinging you.

### Core Philosophy (unchanged)
- Enter arenas with intention, not distraction
- Timers visible everywhere (lock screen, Dynamic Island, banner)
- No social feeds, no anxiety loops — just presence
- Feels like picking up a tool, not opening social media
- SwiftUI-native: gestures, haptics, live activities, deep system integration

### New Philosophy Layer
- **The app should know you.** Time of day, usage patterns, mood, energy — the experience adapts.
- **Your first 60 seconds define whether you stay.** Onboarding is not a tutorial — it's an identity moment.
- **Every screen should feel like yours.** Theme isn't cosmetic — it's the operating language of the entire UI.

---

## SYSTEM 0 — ONBOARDING STORYLINE (NEW)

New users don't see a tutorial. They see a choice that defines their experience.

### Flow

**Step 1 — "YOUR LIFE'S MAIN MENU. CHOOSE A DESIGN."**
Four full-screen cards. Each is a world. Tap to select, swipe to browse. The choice sets the global theme (colors, typography weight, spacing, animation speed, verbiage tone).

**Step 2 — Personalized welcome**
Adapts to: chosen theme + time of day + usage history (first launch vs returning).
The message lands differently for each archetype. The goal is to get "CHOOSE YOUR CURRENT ARENA / TIME BLOCK / PROTOCOL" across in a way that feels native to the user's chosen identity.

**Step 3 — First arena entry**
Zero friction. They're in a session within 60 seconds of install.

### The Four Themes

#### 1. EXECUTIONER — The Operator
| | |
|---|---|
| **Style** | Tactical Minimalist |
| **Colors** | Black, steel gray, electric blue (#0A0A12, #6B7280, #3B82F6) |
| **Environment** | Dim lighting, multiple screens, zero clutter |
| **Energy** | Fast, aggressive, decisive |
| **Verbiage** | "DEPLOY SESSION" / "TARGET ACQUIRED" / "MISSION COMPLETE" |
| **Animation** | Snappy, minimal transition duration, hard cuts |
| **Font weight** | Heavy, condensed |

#### 2. SYSTEMS — The Architect
| | |
|---|---|
| **Style** | Clean Intellectual |
| **Colors** | White, beige, soft gray, muted tones (#F5F0EB, #D4C5B2, #9CA3AF) |
| **Environment** | Organized desk, notebooks, whiteboards |
| **Energy** | Slow, precise, intentional |
| **Verbiage** | "INITIALIZE BLOCK" / "SEQUENCE ACTIVE" / "BLOCK LOGGED" |
| **Animation** | Smooth, deliberate easing, longer transitions |
| **Font weight** | Light, wide tracking |

#### 3. HARMONY — The Guardian
| | |
|---|---|
| **Style** | Soft Grounded Minimalism |
| **Colors** | Earth tones, sage green, warm beige (#2D3B2D, #8FAE8B, #D4C4A8) |
| **Environment** | Natural light, plants, calm spaces |
| **Energy** | Slow, restorative, reflective |
| **Verbiage** | "BEGIN PRACTICE" / "PRESENT" / "SESSION HONORED" |
| **Animation** | Gentle fades, breathing rhythm, organic curves |
| **Font weight** | Regular, generous spacing |

#### 4. CONNECTION — The Catalyst
| | |
|---|---|
| **Style** | Expressive Social |
| **Colors** | Warm tones, gold, vibrant accents (#1A1A2E, #E8C547, #E07A5F) |
| **Environment** | People, movement, conversation |
| **Energy** | High, magnetic, engaging |
| **Verbiage** | "LET'S GO" / "IN THE ZONE" / "CRUSHED IT" |
| **Animation** | Bouncy springs, playful overshoots, particle bursts |
| **Font weight** | Bold, expressive sizing |

### Theme Architecture (technical)
- `AppTheme` enum with 4 cases, stored in `AppSettings`
- `ThemeProvider` protocol: colors, fonts, verbiage, animation curves, spacing
- Every view reads theme from environment — zero hardcoded colors
- Theme is changeable anytime from Settings (not locked to onboarding)
- Current dark aesthetic (#080810 + monospaced) becomes the default/"classic" until theme system ships

---

## WHAT'S BUILT (the map)

```
SHIPPED ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ YOU ARE HERE
                                                        ↓
[SwiftUI rewrite] → [Live Activities] → [Forge Engine] → [Schedules] → ???
[Navigation]        [Widgets]           [Intelligence]   [Deadlines]
[Rituals]           [Calendar sync]     [Narratives]     [v2.26.0]
[Habits]            [Joint sessions]    [Archetypes]
[Protocols]         [Stacking]
[Shortcuts dock]
```

---

## IDENTITY

**One sentence:** Arena Protocol is the in-game UI for your real life — a background operating system that tracks your current and upcoming tasks, events, and time blocks through your lock screen, Dynamic Island, and widgets, keeping you motivated and accountable the moment you unlock your phone.

**Who it's for:** Built for the builder. Started as a personal tool to get out of bed without dread and stick to a regimen. Friends noticed. Infrastructure is already there. Going public.

**First impression target:** Curiosity → amazement → relief. The seamlessness of live calendar integration, prominent live activities, and stylish widgets that put you right back on track to what you intended to do. The app earns its place by being the thing you wake up to.

**What this will NOT become:** A switch-bait paywall subscription service. No paywalls on core functionality. If there's payment, it's cosmetic upgrades that don't meaningfully differ from the base experience. The productivity apps that charge $12/month for a timer and a to-do list are the anti-pattern.

**Revenue model:** Craft project → shippable product. Cosmetic-only monetization (theme packs, forge glyphs, arena card auras). Core app is free forever.

---

## BUILD PRIORITIES (ranked)

1. **Forge progression** — eggs, inventory, rebirth, prestige. The backbone of long-term retention. Everything has to work for the story to develop.
2. **Onboarding storyline** — the 60-second identity moment that hooks new users.
3. **Theme system** — 4 archetypes that make the entire app feel like yours.
4. **Live Activity + Widget polish** — the lock screen IS the app for most of the day. Make it the best lock screen experience on iOS.
5. **App Store polish + submission** — screenshots, description, review compliance.
6. **Multiplayer layer** — async/ambient presence, profiles, leaderboard (CloudKit).
7. **Focus mode / system integration** — auto Do Not Disturb, Siri Shortcuts.
8. **HealthKit integration** — log sessions as workouts.
9. **Watch app** — session control from wrist.
10. **iPad layout** — if demand warrants it.

---

## WHAT'S NEXT

### Phase 1 — Forge Progression (the game loop)
Ship the full forge system from FORGE_SYSTEM_ROADMAP.md:
- DataStore models (eggs, inventory, rebirth states, player profile)
- Drop engine (streak tiers → egg drops → incubation → hatch → rewards)
- Inventory screen (incubating eggs, hatched items, "WHAT IS POSSIBLE" locked preview)
- Rebirth flow (Island 1–10 prestige system per arena)
- Profile screen (equipped titles, glyphs, forge marks)

### Phase 2 — Onboarding + Themes
- Onboarding storyline (System 0 — choose your identity in 3 steps)
- Theme architecture (AppTheme enum, ThemeProvider protocol, environment injection)
- 4 launch themes: Executioner, Systems, Harmony, Connection
- Theme-aware verbiage throughout (session start/end language adapts)
- Settings toggle to switch themes anytime

### Phase 3 — Lock Screen Dominance
- Schedule-aware Live Activity (show next upcoming block, not just active session)
- Widget refresh optimization (timeline entries for scheduled blocks)
- Streak/forge mark display on idle Live Activity
- Lock screen as daily dashboard, not just timer

### Phase 4 — App Store Launch
- Screenshots + App Store description
- App Review compliance pass
- Cosmetic store foundation (theme packs, glyph skins)
- Privacy policy + terms
- TestFlight beta → public release

### Phase 5 — Social Layer
- Player profiles (local first)
- CloudKit leaderboard (opt-in, privacy-first, no usernames)
- Guild/Tribe system (max 7, shared weekly goals)
- Echo Egg world map (Rebirth Island 10 — the rarest thing in the game)

---

*This document is your living visionboard. The old one got you from JSX to a 27-screen native app in 10 days. This one maps what's next.*
