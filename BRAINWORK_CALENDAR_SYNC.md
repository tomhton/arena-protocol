# Brainwork: Calendar ↔ App Full Sync
> Arena Protocol — created 2026-03-19

---

## Problem Statement

Calendar events are created when a session starts, but are never updated afterwards. This means:

1. **Early finish** — event shows the original planned duration, not actual
2. **Abandon** — event stays on calendar as if the session happened in full
3. **Joint arena removed** — its calendar block stays orphaned
4. **Interval timers** (FLOW, DRIFT, WALK, etc.) — no calendar integration at all

---

## What Needs to Change

### 1. Track the EKEvent identifier

When `addEvent` creates an event, the `EKEvent.eventIdentifier` (a `String`) must be returned and stored so we can find it later to edit or delete.

**Changes:**
- `CalendarManager.addEvent(...)` → returns `String?` (the event identifier)
- `ActiveSessionState` gains `calEventId: String?` (primary arena event ID)
- `JointArenaEntry` gains `calEventId: String?` (per-joint event ID)

`ActiveSessionState` is not `Codable`, so `calEventId` is an in-memory field only — that's fine since it only needs to survive the session, not app restarts.

---

### 2. Update or delete events on session end

Three exit paths in `ActiveSessionView`:

| Exit | Calendar action |
|---|---|
| **Timer completes naturally** | No change needed — event end time is already correct |
| **`finishEarly()`** | Update primary event end to `Date()` (actual end). Update each joint event end to actual. If a joint was never reached (session ended before its block), delete it. |
| **`abandonSession()`** | If session lasted < 1 min: delete the event. Otherwise: update end to `Date()`. Delete all joint events (they hadn't started). |

**New `CalendarManager` methods:**
```swift
func updateEventEnd(id: String, newEnd: Date)
func deleteEvent(id: String)
```

---

### 3. Joint arena removed mid-session

`removeJoint(_:)` in `ActiveSessionView` — when a joint is removed, delete its calendar event using `entry.calEventId`.

---

### 4. Interval timers → calendar

`IntervalTimerView` runs a mindless countdown (FLOW, DRIFT, etc.). On start, create a calendar event. On finish or abandon, update/delete accordingly.

`IntervalTimerView` currently has no `CalendarManager` calls.

**Changes:**
- On appear: `addEvent` with title `[INTERVAL] \(presetLabel)`, store returned ID in `@State private var calEventId: String?`
- On natural complete: update event end to `Date()`
- On DONE (early): update event end to `Date()`
- `IntervalTimerView` is navigated to via `.interval(label, minutes)` from HomeView

---

### 5. CalendarManager additions

```swift
// Returns the event identifier so callers can update/delete later
@discardableResult
func addEvent(title: String, start: Date, end: Date, notes: String = "") -> String?

// Trim or extend an existing event's end time
func updateEventEnd(id: String, newEnd: Date)

// Remove an event entirely
func deleteEvent(id: String)
```

---

## Data Flow Diagram

```
Session starts
  └─ addEvent(...) → calEventId stored in ActiveSessionState

  ┌─ Joint added
  │    └─ addEvent(...) → calEventId stored in JointArenaEntry
  │
  ├─ Joint removed
  │    └─ deleteEvent(joint.calEventId)
  │
  ├─ finishEarly()
  │    ├─ updateEventEnd(calEventId, Date())       ← primary
  │    ├─ updateEventEnd(joint.calEventId, Date())  ← joints that started
  │    └─ deleteEvent(joint.calEventId)             ← joints not yet started
  │
  ├─ abandonSession()
  │    ├─ if elapsed < 60s → deleteEvent(calEventId)
  │    │  else             → updateEventEnd(calEventId, Date())
  │    └─ deleteEvent(joint.calEventId) for all joints
  │
  └─ Natural complete
       └─ nothing (event end time already matches)

Interval timer starts
  └─ addEvent("[INTERVAL] FLOW", ...) → calEventId

  ├─ DONE (early)
  │    └─ updateEventEnd(calEventId, Date())
  │
  └─ Natural complete
       └─ updateEventEnd(calEventId, Date())
```

---

## Implementation Order

1. **`CalendarManager.swift`** — add return value to `addEvent`, add `updateEventEnd`, `deleteEvent`
2. **`DataStore.swift`** — add `calEventId: String?` to `ActiveSessionState`; add `calEventId: String?` to `JointArenaEntry`
3. **`ActiveSessionView.swift`**
   - `setup()` fresh start: store returned ID into `store.activeSession?.calEventId`
   - `addJoint`: store returned ID into the new `JointArenaEntry`
   - `removeJoint`: call `deleteEvent`
   - `finishEarly()`: call `updateEventEnd` / `deleteEvent` as needed
   - `abandonSession()`: call `updateEventEnd` or `deleteEvent`
4. **`IntervalTimerView.swift`** — add calendar event on start, update/delete on end

---

## Edge Cases

- **Session restored from minimize** — `calEventId` is in-memory on `ActiveSessionState`, so it survives minimize (the active session stays in memory). It does NOT survive app kill/relaunch, but that's acceptable — we never know the actual end time after a cold relaunch anyway.
- **No calendar permission** — all calendar calls are already gated on `isReadAuthorized`; update/delete will no-op silently if the ID is nil or permission is missing.
- **Stacked sessions** — each `ActiveSessionState` in `stackedSessions` has its own `calEventId`. No extra handling needed; when unstashed and ended normally, the same paths apply.

---

## Files Touched

| File | Change |
|---|---|
| `CalendarManager.swift` | `addEvent` returns `String?`; add `updateEventEnd`, `deleteEvent` |
| `DataStore.swift` | `ActiveSessionState.calEventId: String?`; `JointArenaEntry.calEventId: String?` |
| `ActiveSessionView.swift` | Store IDs, call update/delete on all exit paths and joint remove |
| `IntervalTimerView.swift` | Calendar event on start/end |
