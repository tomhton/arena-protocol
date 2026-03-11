import { useState, useEffect, useRef } from "react";

// ── NOTIFICATIONS (mock for browser, real on iOS) ──────────────────────────────
const LocalNotifications = {
  requestPermissions: async () => {},
  cancel: async () => {},
  schedule: async () => {},
};

// ── DEFAULT ARENAS ─────────────────────────────────────────────────────────────
const DEFAULT_ARENAS = [
  { id: "work", label: "WORK", letter: "A", color: "#E8C547", description: "Anything that moves your professional life forward or protects your income.", examples: ["Reply to one email", "Update one metric", "Research one lead", "Outline webinar ideas", "Prep for a meeting", "Send a follow-up"], icon: "◈" },
  { id: "body", label: "BODY", letter: "B", color: "#4ECDC4", description: "Anything that improves your physical or mental state.", examples: ["10 pushups", "5-minute walk", "Refill water bottle", "Quick mobility stretch", "Breathwork for 5 min", "Prep a real meal"], icon: "◎" },
  { id: "environment", label: "ENV", letter: "C", color: "#A8E6A3", description: "Anything that improves your physical space or reduces chaos.", examples: ["Clear desk surface", "10 min laundry", "Take trash out", "Make bed", "Prep clothes for tomorrow", "Wipe down kitchen"], icon: "⬡" },
  { id: "relationships", label: "CONNECT", letter: "D", color: "#FF8FA3", description: "Anything that strengthens connection with others.", examples: ["Send one thoughtful text", "Reply to one match", "Schedule coffee", "Check in with sibling", "Write a voice note", "Plan something with a friend"], icon: "◇" },
  { id: "build", label: "BUILD", letter: "E", color: "#B794F4", description: "Anything that builds your future beyond your current job.", examples: ["Outline a business idea", "Write 200 words", "Design one draft", "Review investment strategy", "Record a voice memo idea", "Research a new skill"], icon: "△" },
  { id: "recover", label: "RECOVER", letter: "F", color: "#F4A261", description: "Intentional rest that restores energy without spiraling.", examples: ["Read 10 pages", "Journal one page", "15-min show timer", "Lie down and breathe", "Listen to one album", "Meditate for 10 min"], icon: "○" },
];

const ARENA_ICONS = ["◈", "◎", "⬡", "◇", "△", "○", "◉", "◆", "▲", "★", "⬟", "⬠", "⊕", "⊗", "⊘", "❋", "✦", "⟡"];
const ARENA_COLORS = ["#E8C547", "#4ECDC4", "#A8E6A3", "#FF8FA3", "#B794F4", "#F4A261", "#60A5FA", "#F87171", "#34D399", "#A78BFA", "#FB923C", "#38BDF8", "#E879F9", "#4ADE80"];

const DURATIONS = [
  { label: "5m", value: 5 }, { label: "10m", value: 10 }, { label: "30m", value: 30 },
  { label: "60m", value: 60 }, { label: "90m", value: 90 },
];

const MORNING_HABITS = [
  { id: "reading", label: "READING", duration: "5 MIN", description: "Something positive. Feed your mind before the world does.", color: "#E8C547" },
  { id: "goals", label: "GOAL PLANNING", duration: "5 MIN", description: "Set your intentions. What are the three arenas you're entering today?", color: "#4ECDC4" },
  { id: "movement", label: "MOVEMENT", duration: "5 MIN", description: "Get moving. Signal to your body that today has already begun.", color: "#A8E6A3" },
];

const STUCK_PROMPTS = [
  "You've been circling. Pick one arena. Enter it.",
  "Momentum is a choice. What's the smallest move?",
  "Stuck means your brain needs a container. Give it one.",
  "The resistance you feel? That's the arena calling.",
  "Don't optimize. Don't plan. Just start.",
  "One minute of action beats an hour of intention.",
  "Your future self already made the decision. Catch up.",
  "The timer ends. You move. No negotiation.",
];

// ── STORAGE ────────────────────────────────────────────────────────────────────
const todayStr = () => new Date().toISOString().split("T")[0];

const load = (key, fallback) => { try { const v = localStorage.getItem(key); return v ? JSON.parse(v) : fallback; } catch { return fallback; } };
const save = (key, val) => localStorage.setItem(key, JSON.stringify(val));

const loadArenas = () => load('arena_custom_arenas', DEFAULT_ARENAS);
const loadSessions = () => load('arena_sessions', []);
const loadHabits = () => load('arena_habits', []);
const loadHabitLogs = () => load('arena_habit_logs', []);
const loadCheckin = () => { const r = load('arena_checkin', {}); return r.date === todayStr() ? r : { date: todayStr(), completed: [] }; };
const loadSettings = () => load('arena_settings', { windDownTime: "21:30" });

function getStreakForArena(arenaId, sessions) {
  const dates = [...new Set(sessions.filter(s => s.arenaId === arenaId).map(s => s.date))].sort((a, b) => b.localeCompare(a));
  if (!dates.length) return 0;
  let streak = 0, check = todayStr();
  for (const d of dates) {
    if (d === check) { streak++; const dt = new Date(check); dt.setDate(dt.getDate() - 1); check = dt.toISOString().split("T")[0]; }
    else break;
  }
  return streak;
}

function getWeeklyData(sessions) {
  const days = [];
  for (let i = 6; i >= 0; i--) { const d = new Date(); d.setDate(d.getDate() - i); days.push(d.toISOString().split("T")[0]); }
  return days.map(date => ({
    date, label: new Date(date + 'T12:00:00').toLocaleDateString('en-US', { weekday: 'short' }),
    sessions: sessions.filter(s => s.date === date),
    arenas: [...new Set(sessions.filter(s => s.date === date).map(s => s.arenaId))],
  }));
}

function getHabitGrid(habitId, logs) {
  const cells = [];
  for (let i = 69; i >= 0; i--) {
    const d = new Date(); d.setDate(d.getDate() - i);
    const date = d.toISOString().split("T")[0];
    const log = logs.find(l => l.habitId === habitId && l.date === date);
    cells.push({ date, value: log ? log.value : null });
  }
  return cells;
}

function getHabitStreak(habitId, logs) {
  let streak = 0, check = todayStr();
  for (let i = 0; i < 365; i++) {
    const log = logs.find(l => l.habitId === habitId && l.date === check);
    if (log && log.value === true) { streak++; const d = new Date(check); d.setDate(d.getDate() - 1); check = d.toISOString().split("T")[0]; }
    else break;
  }
  return streak;
}

// ── UTILITIES ──────────────────────────────────────────────────────────────────
const formatTime = (s) => `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
const glowFor = (color) => color + "33";
const uid = () => Math.random().toString(36).slice(2, 9);

async function scheduleNotification(id, title, body, secondsFromNow) {
  try {
    await LocalNotifications.requestPermissions();
    await LocalNotifications.cancel({ notifications: [{ id }] });
    if (secondsFromNow > 0) await LocalNotifications.schedule({ notifications: [{ id, title, body, schedule: { at: new Date(Date.now() + secondsFromNow * 1000) }, sound: 'default' }] });
  } catch (e) {}
}
async function cancelNotification(id) { try { await LocalNotifications.cancel({ notifications: [{ id }] }); } catch (e) {} }

// ── ARENA CARD ─────────────────────────────────────────────────────────────────
function ArenaCard({ arena, sessCount, streak, i, onClick, editMode, onEdit }) {
  return (
    <div style={{ position: "relative", animation: `fadeUp 0.5s ease ${i * 0.07}s both`, width: "100%" }}>
      <button onClick={editMode ? onEdit : onClick} style={{
        background: "rgba(255,255,255,0.03)", border: `1px solid ${editMode ? arena.color + '40' : 'rgba(255,255,255,0.07)'}`,
        borderRadius: 14, padding: "16px 12px", cursor: "pointer", textAlign: "left",
        position: "relative", overflow: "hidden", transition: "all 0.25s ease", width: "100%",
      }}
        onPointerEnter={e => { if (!editMode) { e.currentTarget.style.border = `1px solid ${arena.color}50`; e.currentTarget.style.background = "rgba(255,255,255,0.06)"; e.currentTarget.style.transform = "translateY(-2px)"; e.currentTarget.style.boxShadow = `0 6px 20px ${glowFor(arena.color)}`; } }}
        onPointerLeave={e => { if (!editMode) { e.currentTarget.style.border = "1px solid rgba(255,255,255,0.07)"; e.currentTarget.style.background = "rgba(255,255,255,0.03)"; e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "none"; } }}
      >
        <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 2, background: arena.color, borderRadius: "14px 14px 0 0" }} />
        <div style={{ fontSize: 9, color: "rgba(255,255,255,0.25)", letterSpacing: 3, marginBottom: 8 }}>{arena.letter}</div>
        <div style={{ fontSize: 18, color: arena.color, marginBottom: 5 }}>{arena.icon}</div>
        <div style={{ fontSize: 11, fontWeight: "bold", letterSpacing: 2, color: "#E8E8E8" }}>{arena.label}</div>
        {!editMode && streak > 1 && <div style={{ position: "absolute", bottom: 8, right: 8, fontSize: 8, color: arena.color }}>🔥{streak}</div>}
        {!editMode && sessCount > 0 && streak <= 1 && <div style={{ position: "absolute", top: 10, right: 10, fontSize: 8, color: arena.color }}>●{sessCount}</div>}
        {editMode && <div style={{ position: "absolute", top: 8, right: 8, fontSize: 12, color: arena.color, opacity: 0.7 }}>✎</div>}
      </button>
    </div>
  );
}

function AddArenaCard({ i, onClick }) {
  return (
    <button onClick={onClick} style={{
      background: "rgba(255,255,255,0.02)", border: "1px dashed rgba(255,255,255,0.15)",
      borderRadius: 14, padding: "16px 12px", cursor: "pointer", width: "100%",
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      gap: 6, minHeight: 100, animation: `fadeUp 0.5s ease ${i * 0.07}s both`,
    }}>
      <div style={{ fontSize: 22, color: "rgba(255,255,255,0.2)" }}>+</div>
      <div style={{ fontSize: 9, letterSpacing: 3, color: "rgba(255,255,255,0.2)" }}>NEW</div>
    </button>
  );
}

// ── ARENA EDITOR ───────────────────────────────────────────────────────────────
function ArenaEditor({ arena, onSave, onDelete, onClose }) {
  const isNew = !arena.id;
  const [label, setLabel] = useState(arena.label || "");
  const [icon, setIcon] = useState(arena.icon || "◈");
  const [color, setColor] = useState(arena.color || "#E8C547");
  const [description, setDescription] = useState(arena.description || "");
  const [examples, setExamples] = useState((arena.examples || [""]).join("\n"));

  const handleSave = () => {
    if (!label.trim()) return;
    onSave({
      id: arena.id || uid(),
      label: label.trim().toUpperCase(),
      letter: arena.letter || "?",
      color, icon,
      description: description.trim(),
      examples: examples.split("\n").map(e => e.trim()).filter(Boolean),
    });
  };

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 22px 32px", overflowY: "auto" }}>
      <button onClick={onClose} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 28, textAlign: "left", padding: 0 }}>← BACK</button>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>{isNew ? "NEW ARENA" : "EDIT ARENA"}</div>
      <div style={{ fontSize: 24, fontWeight: "bold", letterSpacing: 2, color, marginBottom: 28 }}>{label || "UNTITLED"}</div>

      {/* Name */}
      <div style={{ marginBottom: 20 }}>
        <div style={labelStyle}>NAME</div>
        <input value={label} onChange={e => setLabel(e.target.value)} placeholder="ARENA NAME" maxLength={12} style={{ ...inputStyle, color, borderColor: color + '50', background: color + '08', textTransform: "uppercase", letterSpacing: 3 }} />
      </div>

      {/* Icon */}
      <div style={{ marginBottom: 20 }}>
        <div style={labelStyle}>ICON</div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {ARENA_ICONS.map(ic => (
            <button key={ic} onClick={() => setIcon(ic)} style={{ width: 40, height: 40, borderRadius: 10, border: icon === ic ? `2px solid ${color}` : "1px solid rgba(255,255,255,0.1)", background: icon === ic ? color + '20' : "transparent", color: icon === ic ? color : "rgba(255,255,255,0.4)", fontSize: 18, cursor: "pointer" }}>{ic}</button>
          ))}
        </div>
      </div>

      {/* Color */}
      <div style={{ marginBottom: 20 }}>
        <div style={labelStyle}>COLOR</div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {ARENA_COLORS.map(c => (
            <button key={c} onClick={() => setColor(c)} style={{ width: 32, height: 32, borderRadius: "50%", background: c, border: color === c ? `3px solid white` : "2px solid transparent", cursor: "pointer", boxShadow: color === c ? `0 0 10px ${c}` : "none" }} />
          ))}
        </div>
      </div>

      {/* Description */}
      <div style={{ marginBottom: 20 }}>
        <div style={labelStyle}>DESCRIPTION <span style={{ color: "rgba(255,255,255,0.2)" }}>— OPTIONAL</span></div>
        <textarea value={description} onChange={e => setDescription(e.target.value)} placeholder="What does this arena represent?" rows={2} style={{ ...inputStyle, resize: "none", lineHeight: 1.5 }} />
      </div>

      {/* Examples */}
      <div style={{ marginBottom: 28 }}>
        <div style={labelStyle}>EXAMPLES <span style={{ color: "rgba(255,255,255,0.2)" }}>— ONE PER LINE</span></div>
        <textarea value={examples} onChange={e => setExamples(e.target.value)} placeholder={"Example task 1\nExample task 2"} rows={4} style={{ ...inputStyle, resize: "none", lineHeight: 1.6 }} />
      </div>

      <button onClick={handleSave} style={{ width: "100%", padding: "16px", background: color, border: "none", borderRadius: 14, color: "#080810", fontSize: 13, fontWeight: "bold", letterSpacing: 5, cursor: "pointer", fontFamily: "'Courier New', monospace", marginBottom: 12 }}>
        {isNew ? "CREATE ARENA" : "SAVE CHANGES"}
      </button>
      {!isNew && (
        <button onClick={onDelete} style={{ width: "100%", padding: "14px", background: "transparent", border: "1px solid rgba(255,100,100,0.3)", borderRadius: 14, color: "rgba(255,100,100,0.6)", fontSize: 11, letterSpacing: 4, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>
          DELETE ARENA
        </button>
      )}
    </div>
  );
}

// ── DAILY CHECK-IN ─────────────────────────────────────────────────────────────
function CheckinScreen({ onComplete, onSkip }) {
  const [checkin, setCheckin] = useState(loadCheckin);
  const allDone = checkin.completed.length === MORNING_HABITS.length;

  const toggle = (id) => {
    const updated = checkin.completed.includes(id) ? { ...checkin, completed: checkin.completed.filter(x => x !== id) } : { ...checkin, completed: [...checkin.completed, id] };
    setCheckin(updated); save('arena_checkin', updated);
  };

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 22px 32px" }}>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>MORNING PROTOCOL</div>
      <div style={{ fontSize: 26, fontWeight: "bold", letterSpacing: 2, lineHeight: 1.2, marginBottom: 4 }}>IGNITE THE<br /><span style={{ color: "#E8C547" }}>DAY</span></div>
      <div style={{ fontSize: 11, color: "rgba(255,255,255,0.3)", marginBottom: 32, letterSpacing: 1 }}>15 minutes. 3 habits. Non-negotiable.</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 14, marginBottom: 32 }}>
        {MORNING_HABITS.map((habit, i) => {
          const done = checkin.completed.includes(habit.id);
          return (
            <button key={habit.id} onClick={() => toggle(habit.id)} style={{ background: done ? `${habit.color}10` : "rgba(255,255,255,0.02)", border: done ? `1px solid ${habit.color}50` : "1px solid rgba(255,255,255,0.08)", borderRadius: 16, padding: "18px 16px", cursor: "pointer", textAlign: "left", display: "flex", alignItems: "center", gap: 16, transition: "all 0.3s ease", animation: `fadeUp 0.5s ease ${i * 0.1}s both` }}>
              <div style={{ width: 28, height: 28, borderRadius: "50%", flexShrink: 0, border: done ? `2px solid ${habit.color}` : "2px solid rgba(255,255,255,0.15)", background: done ? habit.color : "transparent", display: "flex", alignItems: "center", justifyContent: "center", transition: "all 0.3s ease" }}>
                {done && <span style={{ fontSize: 14, color: "#080810", fontWeight: "bold" }}>✓</span>}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
                  <span style={{ fontSize: 12, fontWeight: "bold", letterSpacing: 3, color: done ? habit.color : "#E8E8E8" }}>{habit.label}</span>
                  <span style={{ fontSize: 9, color: done ? `${habit.color}80` : "rgba(255,255,255,0.2)", letterSpacing: 2, border: `1px solid ${done ? habit.color + '40' : 'rgba(255,255,255,0.1)'}`, borderRadius: 4, padding: "2px 6px" }}>{habit.duration}</span>
                </div>
                <div style={{ fontSize: 11, color: done ? `${habit.color}70` : "rgba(255,255,255,0.35)", lineHeight: 1.4 }}>{habit.description}</div>
              </div>
            </button>
          );
        })}
      </div>
      <div style={{ marginBottom: 28 }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
          <span style={{ fontSize: 9, letterSpacing: 4, color: "rgba(255,255,255,0.25)" }}>MORNING PROGRESS</span>
          <span style={{ fontSize: 9, letterSpacing: 2, color: "#E8C547" }}>{checkin.completed.length}/{MORNING_HABITS.length}</span>
        </div>
        <div style={{ height: 3, background: "rgba(255,255,255,0.06)", borderRadius: 2 }}>
          <div style={{ height: "100%", width: `${(checkin.completed.length / MORNING_HABITS.length) * 100}%`, background: "#E8C547", borderRadius: 2, transition: "width 0.4s ease", boxShadow: "0 0 8px rgba(232,197,71,0.5)" }} />
        </div>
      </div>
      <button onClick={() => onComplete(checkin.completed.length)} style={{ width: "100%", padding: "17px", background: allDone ? "#E8C547" : "rgba(255,255,255,0.04)", border: allDone ? "none" : "1px solid rgba(255,255,255,0.1)", borderRadius: 14, color: allDone ? "#080810" : "rgba(255,255,255,0.4)", fontSize: 13, fontWeight: allDone ? "bold" : "normal", letterSpacing: 5, cursor: "pointer", fontFamily: "'Courier New', monospace", transition: "all 0.3s ease", boxShadow: allDone ? "0 0 24px rgba(232,197,71,0.3)" : "none", marginBottom: 12 }}>
        {allDone ? "ENTER THE ARENA →" : "CONTINUE →"}
      </button>
      <button onClick={onSkip} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.18)", cursor: "pointer", fontSize: 9, letterSpacing: 3, fontFamily: "'Courier New', monospace" }}>SKIP MORNING PROTOCOL</button>
    </div>
  );
}

// ── WIND-DOWN SCREEN ───────────────────────────────────────────────────────────
function WindDownScreen({ onBack, onComplete }) {
  const habits = loadHabits();
  const [step, setStep] = useState(0); // 0 = journal, 1..n = habits
  const [journal, setJournal] = useState("");
  const [habitAnswers, setHabitAnswers] = useState({});
  const totalSteps = 1 + habits.length;
  const isJournal = step === 0;
  const currentHabit = !isJournal ? habits[step - 1] : null;

  const next = () => {
    if (step < totalSteps - 1) setStep(s => s + 1);
    else finish();
  };

  const finish = () => {
    // Save journal
    const journals = load('arena_journals', []);
    if (journal.trim()) { journals.push({ date: todayStr(), text: journal.trim(), ts: Date.now() }); save('arena_journals', journals); }
    // Save habit logs
    const logs = loadHabitLogs();
    Object.entries(habitAnswers).forEach(([habitId, value]) => {
      const existing = logs.findIndex(l => l.habitId === habitId && l.date === todayStr());
      if (existing >= 0) logs[existing].value = value;
      else logs.push({ habitId, date: todayStr(), value, ts: Date.now() });
    });
    save('arena_habit_logs', logs);
    onComplete();
  };

  const answerHabit = (val) => {
    setHabitAnswers(prev => ({ ...prev, [currentHabit.id]: val }));
    setTimeout(next, 300);
  };

  const progress = (step / Math.max(totalSteps - 1, 1)) * 100;

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 22px 32px" }}>
      <button onClick={onBack} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 28, textAlign: "left", padding: 0 }}>← BACK</button>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>WIND DOWN</div>
      <div style={{ fontSize: 26, fontWeight: "bold", letterSpacing: 2, lineHeight: 1.2, marginBottom: 24 }}>CLOSE<br /><span style={{ color: "#B794F4" }}>THE DAY</span></div>

      {/* Progress */}
      <div style={{ marginBottom: 32 }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
          <span style={{ fontSize: 9, letterSpacing: 4, color: "rgba(255,255,255,0.25)" }}>{step + 1} OF {totalSteps}</span>
          <span style={{ fontSize: 9, color: "#B794F4" }}>{Math.round(progress)}%</span>
        </div>
        <div style={{ height: 3, background: "rgba(255,255,255,0.06)", borderRadius: 2 }}>
          <div style={{ height: "100%", width: `${progress}%`, background: "#B794F4", borderRadius: 2, transition: "width 0.4s ease" }} />
        </div>
      </div>

      {isJournal && (
        <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
          <div style={{ fontSize: 14, color: "rgba(255,255,255,0.7)", lineHeight: 1.6, marginBottom: 8 }}>How did today go?</div>
          <div style={{ fontSize: 11, color: "rgba(255,255,255,0.3)", marginBottom: 20 }}>One sentence is enough. More is welcome.</div>
          <textarea value={journal} onChange={e => setJournal(e.target.value)} placeholder="Today I..." rows={4}
            style={{ ...inputStyle, resize: "none", lineHeight: 1.6, fontSize: 14, flex: 1, marginBottom: 20 }} />
          <button onClick={next} style={primaryBtn("#B794F4")}>
            {journal.trim() ? "NEXT →" : "SKIP →"}
          </button>
        </div>
      )}

      {currentHabit && (
        <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
          <div style={{ padding: "24px", background: `${currentHabit.color}10`, border: `1px solid ${currentHabit.color}30`, borderRadius: 16, marginBottom: 28, textAlign: "center" }}>
            <div style={{ fontSize: 11, color: `${currentHabit.color}80`, letterSpacing: 3, marginBottom: 8 }}>HABIT CHECK</div>
            <div style={{ fontSize: 18, fontWeight: "bold", color: currentHabit.color, letterSpacing: 2, marginBottom: 8 }}>{currentHabit.name}</div>
            {currentHabit.goal && <div style={{ fontSize: 12, color: "rgba(255,255,255,0.4)", fontStyle: "italic" }}>Goal: {currentHabit.goal}</div>}
          </div>
          <div style={{ fontSize: 16, color: "rgba(255,255,255,0.7)", textAlign: "center", marginBottom: 32 }}>
            Did you complete this today?
          </div>
          <div style={{ display: "flex", gap: 12 }}>
            <button onClick={() => answerHabit(true)} style={{ flex: 1, padding: "20px", background: `${currentHabit.color}18`, border: `2px solid ${currentHabit.color}`, borderRadius: 14, color: currentHabit.color, fontSize: 20, cursor: "pointer", transition: "all 0.2s", ...(habitAnswers[currentHabit.id] === true ? { background: currentHabit.color, color: "#080810" } : {}) }}>✓</button>
            <button onClick={() => answerHabit(false)} style={{ flex: 1, padding: "20px", background: "rgba(255,100,100,0.08)", border: "2px solid rgba(255,100,100,0.3)", borderRadius: 14, color: "rgba(255,100,100,0.6)", fontSize: 20, cursor: "pointer", transition: "all 0.2s", ...(habitAnswers[currentHabit.id] === false ? { background: "rgba(255,100,100,0.3)", color: "#fff" } : {}) }}>✗</button>
          </div>
          <button onClick={next} style={{ marginTop: 16, background: "none", border: "none", color: "rgba(255,255,255,0.2)", cursor: "pointer", fontSize: 9, letterSpacing: 3, fontFamily: "'Courier New', monospace" }}>SKIP</button>
        </div>
      )}
    </div>
  );
}

// ── HABIT MANAGER ──────────────────────────────────────────────────────────────
function HabitManager({ onBack }) {
  const [habits, setHabits] = useState(loadHabits);
  const [editing, setEditing] = useState(null); // null | {} | habit
  const [name, setName] = useState("");
  const [goal, setGoal] = useState("");
  const [color, setColor] = useState("#E8C547");

  const openNew = () => { setName(""); setGoal(""); setColor("#E8C547"); setEditing({}); };
  const openEdit = (h) => { setName(h.name); setGoal(h.goal || ""); setColor(h.color); setEditing(h); };

  const saveHabit = () => {
    if (!name.trim()) return;
    let updated;
    if (editing.id) { updated = habits.map(h => h.id === editing.id ? { ...h, name: name.trim(), goal: goal.trim(), color } : h); }
    else { updated = [...habits, { id: uid(), name: name.trim(), goal: goal.trim(), color, createdAt: todayStr() }]; }
    setHabits(updated); save('arena_habits', updated); setEditing(null);
  };

  const deleteHabit = (id) => { const updated = habits.filter(h => h.id !== id); setHabits(updated); save('arena_habits', updated); setEditing(null); };

  if (editing !== null) return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 22px 32px" }}>
      <button onClick={() => setEditing(null)} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 28, textAlign: "left", padding: 0 }}>← BACK</button>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>{editing.id ? "EDIT HABIT" : "NEW HABIT"}</div>
      <div style={{ fontSize: 24, fontWeight: "bold", letterSpacing: 2, color, marginBottom: 28 }}>{name || "UNTITLED"}</div>

      <div style={{ marginBottom: 20 }}>
        <div style={labelStyle}>HABIT NAME</div>
        <input value={name} onChange={e => setName(e.target.value)} placeholder="Wake before 8am" style={{ ...inputStyle }} />
      </div>
      <div style={{ marginBottom: 20 }}>
        <div style={labelStyle}>GOAL DESCRIPTION <span style={{ color: "rgba(255,255,255,0.2)" }}>— OPTIONAL</span></div>
        <input value={goal} onChange={e => setGoal(e.target.value)} placeholder="Consistent sleep schedule" style={{ ...inputStyle }} />
      </div>
      <div style={{ marginBottom: 28 }}>
        <div style={labelStyle}>COLOR</div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {ARENA_COLORS.map(c => <button key={c} onClick={() => setColor(c)} style={{ width: 32, height: 32, borderRadius: "50%", background: c, border: color === c ? "3px solid white" : "2px solid transparent", cursor: "pointer", boxShadow: color === c ? `0 0 10px ${c}` : "none" }} />)}
        </div>
      </div>
      <button onClick={saveHabit} style={primaryBtn(color)}>{editing.id ? "SAVE CHANGES" : "CREATE HABIT"}</button>
      {editing.id && <button onClick={() => deleteHabit(editing.id)} style={{ marginTop: 10, width: "100%", padding: "14px", background: "transparent", border: "1px solid rgba(255,100,100,0.3)", borderRadius: 14, color: "rgba(255,100,100,0.6)", fontSize: 11, letterSpacing: 4, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>DELETE HABIT</button>}
    </div>
  );

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 22px 32px" }}>
      <button onClick={onBack} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 28, textAlign: "left", padding: 0 }}>← BACK</button>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>TRACKING</div>
      <div style={{ fontSize: 26, fontWeight: "bold", letterSpacing: 2, marginBottom: 24 }}>HABITS</div>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 10, overflowY: "auto" }}>
        {habits.length === 0 && <div style={{ textAlign: "center", color: "rgba(255,255,255,0.18)", fontSize: 11, letterSpacing: 3, marginTop: 40 }}>NO HABITS YET</div>}
        {habits.map(h => (
          <button key={h.id} onClick={() => openEdit(h)} style={{ background: "rgba(255,255,255,0.02)", border: `1px solid ${h.color}30`, borderRadius: 14, padding: "16px", cursor: "pointer", textAlign: "left", display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 10, height: 10, borderRadius: "50%", background: h.color, flexShrink: 0 }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, color: "#E8E8E8", marginBottom: 2 }}>{h.name}</div>
              {h.goal && <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)", fontStyle: "italic" }}>{h.goal}</div>}
            </div>
            <div style={{ fontSize: 12, color: "rgba(255,255,255,0.2)" }}>›</div>
          </button>
        ))}
      </div>
      <button onClick={openNew} style={{ marginTop: 16, ...primaryBtn("#B794F4") }}>+ ADD HABIT</button>
    </div>
  );
}

// ── HISTORY SCREEN ─────────────────────────────────────────────────────────────
function HistoryScreen({ onBack, sessions, arenas }) {
  const [tab, setTab] = useState("chart");
  const habits = loadHabits();
  const habitLogs = loadHabitLogs();
  const journals = load('arena_journals', []);
  const weekData = getWeeklyData(sessions);
  const maxSessions = Math.max(...weekData.map(d => d.sessions.length), 1);

  const arenaStats = arenas.map(arena => ({
    ...arena,
    total: sessions.filter(s => s.arenaId === arena.id).length,
    streak: getStreakForArena(arena.id, sessions),
    minutes: sessions.filter(s => s.arenaId === arena.id).reduce((sum, s) => sum + (s.duration || 0), 0),
  })).sort((a, b) => b.total - a.total);

  const totalSessions = sessions.length;
  const totalMinutes = sessions.reduce((sum, s) => sum + (s.duration || 0), 0);
  const activeDays = new Set(sessions.map(s => s.date)).size;

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 20px 32px", overflowY: "auto" }}>
      <button onClick={onBack} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, padding: 0, marginBottom: 24, textAlign: "left" }}>← BACK</button>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>YOUR RECORD</div>
      <div style={{ fontSize: 26, fontWeight: "bold", letterSpacing: 2, marginBottom: 20 }}>ARENA <span style={{ color: "#B794F4" }}>HISTORY</span></div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10, marginBottom: 24 }}>
        {[{ label: "SESSIONS", value: totalSessions }, { label: "MINUTES", value: totalMinutes }, { label: "DAYS", value: activeDays }].map(stat => (
          <div key={stat.label} style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 12, padding: "14px 10px", textAlign: "center" }}>
            <div style={{ fontSize: 22, fontWeight: "bold", color: "#E8E8E8", marginBottom: 4 }}>{stat.value}</div>
            <div style={{ fontSize: 8, letterSpacing: 3, color: "rgba(255,255,255,0.25)" }}>{stat.label}</div>
          </div>
        ))}
      </div>

      <div style={{ display: "flex", gap: 8, marginBottom: 20, overflowX: "auto" }}>
        {["chart", "habits", "log", "journal"].map(t => (
          <button key={t} onClick={() => setTab(t)} style={{ flexShrink: 0, padding: "10px 14px", borderRadius: 10, border: tab === t ? "1px solid #B794F4" : "1px solid rgba(255,255,255,0.08)", background: tab === t ? "rgba(183,148,244,0.12)" : "transparent", color: tab === t ? "#B794F4" : "rgba(255,255,255,0.35)", fontSize: 10, letterSpacing: 3, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>{t.toUpperCase()}</button>
        ))}
      </div>

      {tab === "chart" && (
        <>
          <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 16, padding: "20px 16px", marginBottom: 20 }}>
            <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 16 }}>7-DAY ACTIVITY</div>
            <div style={{ display: "flex", gap: 6, alignItems: "flex-end", height: 80 }}>
              {weekData.map(day => {
                const isToday = day.date === todayStr();
                const heightPct = day.sessions.length / maxSessions;
                const topArena = arenas.find(a => a.id === day.arenas[0]);
                return (
                  <div key={day.date} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
                    <div style={{ width: "100%", height: 64, display: "flex", flexDirection: "column", justifyContent: "flex-end" }}>
                      {day.sessions.length > 0
                        ? <div style={{ width: "100%", height: `${Math.max(heightPct * 100, 12)}%`, background: topArena ? topArena.color : "#E8C547", borderRadius: 4, opacity: isToday ? 1 : 0.6, transition: "height 0.4s ease", display: "flex", alignItems: "center", justifyContent: "center" }}>
                          {day.sessions.length > 1 && <span style={{ fontSize: 8, color: "#080810", fontWeight: "bold" }}>{day.sessions.length}</span>}
                        </div>
                        : <div style={{ width: "100%", height: 4, background: "rgba(255,255,255,0.06)", borderRadius: 2 }} />}
                    </div>
                    <div style={{ fontSize: 9, color: isToday ? "#E8C547" : "rgba(255,255,255,0.25)", letterSpacing: 1 }}>{day.label}</div>
                  </div>
                );
              })}
            </div>
          </div>
          <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 12 }}>ARENA BREAKDOWN</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {arenaStats.map(arena => {
              const pct = totalSessions ? arena.total / totalSessions : 0;
              const neglected = pct < 0.1 && totalSessions > 5;
              return (
                <div key={arena.id} style={{ background: "rgba(255,255,255,0.02)", border: `1px solid ${neglected ? 'rgba(255,100,100,0.2)' : 'rgba(255,255,255,0.06)'}`, borderRadius: 12, padding: "14px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <span style={{ color: arena.color, fontSize: 14 }}>{arena.icon}</span>
                      <span style={{ fontSize: 11, letterSpacing: 2, color: "#E8E8E8" }}>{arena.label}</span>
                      {arena.streak > 1 && <span style={{ fontSize: 9, color: arena.color }}>🔥{arena.streak}d</span>}
                      {neglected && <span style={{ fontSize: 8, color: "rgba(255,100,100,0.7)", letterSpacing: 1, border: "1px solid rgba(255,100,100,0.3)", borderRadius: 4, padding: "1px 5px" }}>NEGLECTED</span>}
                    </div>
                    <div style={{ textAlign: "right" }}>
                      <div style={{ fontSize: 13, fontWeight: "bold", color: arena.color }}>{arena.total}</div>
                      <div style={{ fontSize: 8, color: "rgba(255,255,255,0.2)" }}>{arena.minutes}m</div>
                    </div>
                  </div>
                  <div style={{ height: 3, background: "rgba(255,255,255,0.06)", borderRadius: 2 }}>
                    <div style={{ height: "100%", width: `${pct * 100}%`, background: arena.color, borderRadius: 2, transition: "width 0.5s ease" }} />
                  </div>
                </div>
              );
            })}
          </div>
        </>
      )}

      {tab === "habits" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          {habits.length === 0 && <div style={{ textAlign: "center", color: "rgba(255,255,255,0.18)", fontSize: 11, letterSpacing: 3, marginTop: 40 }}>NO HABITS TRACKED YET<br /><span style={{ fontSize: 9, marginTop: 8, display: "block" }}>ADD HABITS IN SETTINGS</span></div>}
          {habits.map(habit => {
            const grid = getHabitGrid(habit.id, habitLogs);
            const streak = getHabitStreak(habit.id, habitLogs);
            const total = habitLogs.filter(l => l.habitId === habit.id && l.value === true).length;
            const rate = habitLogs.filter(l => l.habitId === habit.id).length
              ? Math.round((total / habitLogs.filter(l => l.habitId === habit.id).length) * 100) : 0;
            const weeks = [];
            for (let w = 0; w < 10; w++) weeks.push(grid.slice(w * 7, w * 7 + 7));
            return (
              <div key={habit.id} style={{ background: "rgba(255,255,255,0.02)", border: `1px solid ${habit.color}25`, borderRadius: 16, padding: "16px" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                  <div>
                    <div style={{ fontSize: 12, fontWeight: "bold", color: habit.color, letterSpacing: 2 }}>{habit.name}</div>
                    {habit.goal && <div style={{ fontSize: 9, color: "rgba(255,255,255,0.3)", marginTop: 2 }}>{habit.goal}</div>}
                  </div>
                  <div style={{ display: "flex", gap: 12, textAlign: "right" }}>
                    <div><div style={{ fontSize: 14, fontWeight: "bold", color: habit.color }}>{streak}</div><div style={{ fontSize: 8, color: "rgba(255,255,255,0.25)" }}>STREAK</div></div>
                    <div><div style={{ fontSize: 14, fontWeight: "bold", color: "#E8E8E8" }}>{rate}%</div><div style={{ fontSize: 8, color: "rgba(255,255,255,0.25)" }}>RATE</div></div>
                  </div>
                </div>
                {/* Contribution grid */}
                <div style={{ display: "flex", gap: 3 }}>
                  {weeks.map((week, wi) => (
                    <div key={wi} style={{ display: "flex", flexDirection: "column", gap: 3 }}>
                      {week.map((cell, di) => (
                        <div key={di} title={cell.date} style={{ width: 10, height: 10, borderRadius: 2, background: cell.value === true ? habit.color : cell.value === false ? "rgba(255,100,100,0.3)" : "rgba(255,255,255,0.06)", opacity: cell.value === true ? 1 : cell.value === false ? 0.8 : 0.4 }} />
                      ))}
                    </div>
                  ))}
                </div>
                <div style={{ display: "flex", gap: 12, marginTop: 10, fontSize: 8, color: "rgba(255,255,255,0.25)", letterSpacing: 2 }}>
                  <span>■ <span style={{ color: habit.color }}>YES</span></span>
                  <span>■ <span style={{ color: "rgba(255,100,100,0.6)" }}>NO</span></span>
                  <span>■ UNLOGGED</span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {tab === "log" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {sessions.length === 0 && <div style={{ textAlign: "center", color: "rgba(255,255,255,0.18)", fontSize: 11, letterSpacing: 3, marginTop: 40 }}>NO SESSIONS YET</div>}
          {[...sessions].reverse().map((session, i) => {
            const arena = arenas.find(a => a.id === session.arenaId);
            if (!arena) return null;
            return (
              <div key={i} style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 12, padding: "14px", display: "flex", alignItems: "center", gap: 12 }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: `${arena.color}15`, border: `1px solid ${arena.color}40`, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <span style={{ color: arena.color, fontSize: 16 }}>{arena.icon}</span>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 11, fontWeight: "bold", letterSpacing: 2, color: arena.color }}>{arena.label}</div>
                  {session.note && <div style={{ fontSize: 10, color: "rgba(255,255,255,0.35)", marginTop: 2, fontStyle: "italic" }}>{session.note}</div>}
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{ fontSize: 12, color: "#E8E8E8" }}>{session.duration}m</div>
                  <div style={{ fontSize: 9, color: "rgba(255,255,255,0.25)", marginTop: 2 }}>{session.date === todayStr() ? "today" : session.date.slice(5)}</div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {tab === "journal" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {journals.length === 0 && <div style={{ textAlign: "center", color: "rgba(255,255,255,0.18)", fontSize: 11, letterSpacing: 3, marginTop: 40 }}>NO JOURNAL ENTRIES YET</div>}
          {[...journals].reverse().map((entry, i) => (
            <div key={i} style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(183,148,244,0.15)", borderRadius: 12, padding: "16px" }}>
              <div style={{ fontSize: 9, color: "#B794F4", letterSpacing: 3, marginBottom: 8 }}>{entry.date}</div>
              <div style={{ fontSize: 13, color: "rgba(255,255,255,0.7)", lineHeight: 1.6 }}>{entry.text}</div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ── NOTES SCREEN ───────────────────────────────────────────────────────────────
function NotesScreen({ onBack }) {
  const [notes, setNotes] = useState(() => load('arena_ideas', []));
  const [input, setInput] = useState("");
  const inputRef = useRef(null);
  const addNote = () => { const t = input.trim(); if (!t) return; const n = [{ id: Date.now(), text: t, ts: new Date().toLocaleDateString() }, ...notes]; setNotes(n); save('arena_ideas', n); setInput(""); inputRef.current?.focus(); };
  const deleteNote = (id) => { const n = notes.filter(x => x.id !== id); setNotes(n); save('arena_ideas', n); };
  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 20px 32px" }}>
      <button onClick={onBack} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, padding: 0, marginBottom: 28, textAlign: "left" }}>← BACK</button>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>CAPTURE</div>
      <div style={{ fontSize: 28, fontWeight: "bold", letterSpacing: 3, marginBottom: 6 }}>IDEA <span style={{ color: "#E8C547" }}>!</span></div>
      <div style={{ fontSize: 11, color: "rgba(255,255,255,0.3)", marginBottom: 24 }}>Raw thoughts. No filter. Capture now, refine later.</div>
      <div style={{ display: "flex", gap: 8, marginBottom: 24 }}>
        <textarea ref={inputRef} value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); addNote(); } }} placeholder="What just hit you?" rows={2} style={{ ...inputStyle, flex: 1, resize: "none", lineHeight: 1.5 }} />
        <button onClick={addNote} style={{ padding: "0 16px", background: "#E8C547", border: "none", borderRadius: 10, color: "#080810", fontSize: 18, cursor: "pointer", fontWeight: "bold", alignSelf: "stretch" }}>+</button>
      </div>
      <div style={{ flex: 1, overflowY: "auto", display: "flex", flexDirection: "column", gap: 10 }}>
        {notes.length === 0 && <div style={{ textAlign: "center", color: "rgba(255,255,255,0.18)", fontSize: 11, letterSpacing: 3, marginTop: 40 }}>NO IDEAS YET</div>}
        {notes.map(note => (
          <div key={note.id} style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 12, padding: "14px", display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}><div style={{ fontSize: 13, color: "rgba(255,255,255,0.8)", lineHeight: 1.5, marginBottom: 4 }}>{note.text}</div><div style={{ fontSize: 9, color: "rgba(255,255,255,0.2)", letterSpacing: 2 }}>{note.ts}</div></div>
            <button onClick={() => deleteNote(note.id)} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.2)", cursor: "pointer", fontSize: 14, padding: "2px 4px" }}>×</button>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── SETTINGS SCREEN ────────────────────────────────────────────────────────────
function SettingsScreen({ onBack, onNavigate }) {
  const [settings, setSettings] = useState(loadSettings);
  const updateSetting = (key, val) => { const s = { ...settings, [key]: val }; setSettings(s); save('arena_settings', s); };

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 22px 32px", overflowY: "auto" }}>
      <button onClick={onBack} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 28, textAlign: "left", padding: 0 }}>← BACK</button>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>CONFIGURE</div>
      <div style={{ fontSize: 26, fontWeight: "bold", letterSpacing: 2, marginBottom: 28 }}>SETTINGS</div>

      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        <div style={sectionCard}>
          <div style={labelStyle}>WIND-DOWN TIME</div>
          <div style={{ fontSize: 11, color: "rgba(255,255,255,0.3)", marginBottom: 12 }}>Daily notification to begin your wind-down ritual</div>
          <input type="time" value={settings.windDownTime} onChange={e => updateSetting('windDownTime', e.target.value)}
            style={{ ...inputStyle, colorScheme: "dark", fontSize: 18, textAlign: "center", letterSpacing: 4 }} />
        </div>

        <button onClick={() => onNavigate('habits')} style={{ ...sectionCard, cursor: "pointer", display: "flex", justifyContent: "space-between", alignItems: "center", border: "1px solid rgba(183,148,244,0.2)" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: "bold", letterSpacing: 2, color: "#B794F4", marginBottom: 4 }}>MANAGE HABITS</div>
            <div style={{ fontSize: 11, color: "rgba(255,255,255,0.3)" }}>Track what matters daily</div>
          </div>
          <div style={{ fontSize: 18, color: "rgba(255,255,255,0.2)" }}>›</div>
        </button>

        <button onClick={() => onNavigate('arenaEditor')} style={{ ...sectionCard, cursor: "pointer", display: "flex", justifyContent: "space-between", alignItems: "center", border: "1px solid rgba(232,197,71,0.2)" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: "bold", letterSpacing: 2, color: "#E8C547", marginBottom: 4 }}>MANAGE ARENAS</div>
            <div style={{ fontSize: 11, color: "rgba(255,255,255,0.3)" }}>Add, edit, or remove your life pillars</div>
          </div>
          <div style={{ fontSize: 18, color: "rgba(255,255,255,0.2)" }}>›</div>
        </button>
      </div>
    </div>
  );
}

// ── STUCK SCREEN ───────────────────────────────────────────────────────────────
function StuckScreen({ onBack, onSelectArena, arenas }) {
  const [phase, setPhase] = useState("config");
  const [selectedDuration, setSelectedDuration] = useState(10);
  const [isCustomActive, setIsCustomActive] = useState(false);
  const [customMinutes, setCustomMinutes] = useState("");
  const [timeLeft, setTimeLeft] = useState(0);
  const [prompt] = useState(STUCK_PROMPTS[Math.floor(Math.random() * STUCK_PROMPTS.length)]);
  const intervalRef = useRef(null);
  const effectiveDuration = isCustomActive && parseInt(customMinutes) > 0 ? parseInt(customMinutes) : selectedDuration;
  const circumference = 2 * Math.PI * 90;
  const totalSecs = effectiveDuration * 60;
  const progress = totalSecs ? 1 - timeLeft / totalSecs : 0;

  const startCountdown = () => {
    if (!effectiveDuration) return;
    const endTime = Date.now() + effectiveDuration * 60 * 1000;
    localStorage.setItem('stuckEndTime', endTime);
    setTimeLeft(effectiveDuration * 60);
    setPhase("countdown");
  };

  useEffect(() => {
    if (phase === "countdown") {
      intervalRef.current = setInterval(() => {
        const endTime = parseInt(localStorage.getItem('stuckEndTime'));
        const remaining = Math.round((endTime - Date.now()) / 1000);
        if (remaining <= 0) { clearInterval(intervalRef.current); setTimeLeft(0); setPhase("pickArena"); }
        else setTimeLeft(remaining);
      }, 1000);
    }
    return () => clearInterval(intervalRef.current);
  }, [phase]);

  if (phase === "config") return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 20px 32px" }}>
      <button onClick={onBack} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 36, textAlign: "left", padding: 0 }}>← BACK</button>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>EMERGENCY PROTOCOL</div>
      <div style={{ fontSize: 32, fontWeight: "bold", letterSpacing: 2, marginBottom: 6 }}>I AM <span style={{ color: "#FF8FA3" }}>STUCK</span></div>
      <div style={{ fontSize: 12, color: "rgba(255,255,255,0.4)", marginBottom: 28, lineHeight: 1.7 }}>Set a countdown. When it hits zero, you <em>must</em> enter an arena.</div>
      <div style={{ padding: "16px", background: "rgba(255,143,163,0.06)", border: "1px solid rgba(255,143,163,0.2)", borderRadius: 12, marginBottom: 28 }}>
        <div style={{ fontSize: 12, color: "rgba(255,143,163,0.8)", lineHeight: 1.6, fontStyle: "italic" }}>"{prompt}"</div>
      </div>
      <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 12 }}>GRACE PERIOD</div>
      <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 16 }}>
        {DURATIONS.map(d => <button key={d.value} onClick={() => { setSelectedDuration(d.value); setIsCustomActive(false); }} style={{ padding: "10px 12px", borderRadius: 10, flex: 1, border: !isCustomActive && selectedDuration === d.value ? "1.5px solid #FF8FA3" : "1px solid rgba(255,255,255,0.1)", background: !isCustomActive && selectedDuration === d.value ? "rgba(255,143,163,0.12)" : "transparent", color: !isCustomActive && selectedDuration === d.value ? "#FF8FA3" : "rgba(255,255,255,0.4)", cursor: "pointer", fontSize: 11, letterSpacing: 2, fontFamily: "'Courier New', monospace" }}>{d.label}</button>)}
        <button onClick={() => setIsCustomActive(true)} style={{ padding: "10px 12px", borderRadius: 10, flex: 1, border: isCustomActive ? "1.5px solid #FF8FA3" : "1px solid rgba(255,255,255,0.1)", background: isCustomActive ? "rgba(255,143,163,0.12)" : "transparent", color: isCustomActive ? "#FF8FA3" : "rgba(255,255,255,0.4)", cursor: "pointer", fontSize: 11, letterSpacing: 2, fontFamily: "'Courier New', monospace" }}>other</button>
      </div>
      {isCustomActive && <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 16 }}><input type="number" min="1" max="60" value={customMinutes} onChange={e => setCustomMinutes(e.target.value)} placeholder="min" autoFocus style={{ ...inputStyle, flex: 1, textAlign: "center", fontSize: 16, color: "#FF8FA3", borderColor: "#FF8FA3", background: "rgba(255,143,163,0.08)" }} /><div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", letterSpacing: 2 }}>MINUTES</div></div>}
      <button onClick={startCountdown} style={primaryBtn("#FF8FA3")}>START GRACE PERIOD</button>
    </div>
  );

  if (phase === "countdown") return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px 24px", gap: 28 }}>
      <div style={{ textAlign: "center" }}>
        <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>GRACE PERIOD</div>
        <div style={{ fontSize: 20, fontWeight: "bold", letterSpacing: 4, color: "#FF8FA3" }}>CHOOSE YOUR ARENA</div>
      </div>
      <div style={{ position: "relative", width: 220, height: 220 }}>
        <svg width="220" height="220" style={{ transform: "rotate(-90deg)" }}>
          <circle cx="110" cy="110" r="90" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="6" />
          <circle cx="110" cy="110" r="90" fill="none" stroke="#FF8FA3" strokeWidth="6" strokeLinecap="round" strokeDasharray={circumference} strokeDashoffset={circumference * progress} style={{ transition: "stroke-dashoffset 1s linear", filter: "drop-shadow(0 0 10px #FF8FA3)" }} />
        </svg>
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
          <div style={{ fontSize: 46, fontWeight: "bold", letterSpacing: 3, color: "#FF8FA3", fontVariantNumeric: "tabular-nums" }}>{formatTime(timeLeft)}</div>
          <div style={{ fontSize: 9, letterSpacing: 3, color: "rgba(255,255,255,0.25)", marginTop: 6 }}>UNTIL MANDATORY</div>
        </div>
      </div>
      <div style={{ padding: "14px 20px", background: "rgba(255,143,163,0.06)", borderRadius: 12, border: "1px solid rgba(255,143,163,0.15)", textAlign: "center", maxWidth: 280 }}>
        <div style={{ fontSize: 12, color: "rgba(255,143,163,0.7)", lineHeight: 1.6, fontStyle: "italic" }}>"{prompt}"</div>
      </div>
      <button onClick={() => setPhase("pickArena")} style={{ padding: "14px 32px", background: "transparent", border: "1px solid rgba(255,255,255,0.15)", borderRadius: 12, color: "rgba(255,255,255,0.4)", fontSize: 10, letterSpacing: 4, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>I'M READY NOW →</button>
    </div>
  );

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 20px 24px" }}>
      <div style={{ textAlign: "center", marginBottom: 28 }}>
        <div style={{ fontSize: 28, color: "#FF8FA3", marginBottom: 8, filter: "drop-shadow(0 0 12px #FF8FA3)" }}>⚡</div>
        <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>TIME IS UP</div>
        <div style={{ fontSize: 22, fontWeight: "bold", letterSpacing: 3 }}>PICK AN ARENA</div>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
        {arenas.map((arena, i) => <ArenaCard key={arena.id} arena={arena} sessCount={0} streak={0} i={i} onClick={() => onSelectArena(arena)} />)}
      </div>
    </div>
  );
}

// ── SHARED STYLES ──────────────────────────────────────────────────────────────
const labelStyle = { fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 10 };
const inputStyle = { width: "100%", padding: "12px 14px", borderRadius: 10, border: "1px solid rgba(255,255,255,0.1)", background: "rgba(255,255,255,0.04)", color: "rgba(255,255,255,0.8)", fontSize: 13, fontFamily: "'Courier New', monospace", outline: "none", boxSizing: "border-box" };
const sectionCard = { background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 14, padding: "16px" };
const primaryBtn = (color) => ({ width: "100%", padding: "16px", background: color, border: "none", borderRadius: 14, color: "#080810", fontSize: 13, fontWeight: "bold", letterSpacing: 5, cursor: "pointer", fontFamily: "'Courier New', monospace" });

// ── MAIN APP ───────────────────────────────────────────────────────────────────
export default function App() {
  const [arenas, setArenas] = useState(loadArenas);
  const [screen, setScreen] = useState(() => { const d = localStorage.getItem('arena_checkin_dismissed'); return d !== todayStr() ? "checkin" : "home"; });
  const [sessions, setSessions] = useState(loadSessions);
  const [selectedArena, setSelectedArena] = useState(null);
  const [selectedDuration, setSelectedDuration] = useState(25);
  const [customMinutes, setCustomMinutes] = useState("");
  const [isCustomActive, setIsCustomActive] = useState(false);
  const [logToCalendar, setLogToCalendar] = useState(false);
  const [sessionNote, setSessionNote] = useState("");
  const [timeLeft, setTimeLeft] = useState(0);
  const [totalTime, setTotalTime] = useState(0);
  const [isRunning, setIsRunning] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [focusExample, setFocusExample] = useState("");
  const [editMode, setEditMode] = useState(false);
  const [editingArena, setEditingArena] = useState(null);
  const intervalRef = useRef(null);

  const effectiveDuration = isCustomActive && parseInt(customMinutes) > 0 ? parseInt(customMinutes) : selectedDuration;
  const durationValid = !(isCustomActive && (!customMinutes || parseInt(customMinutes) <= 0));
  const todaySessions = sessions.filter(s => s.date === todayStr()).length;
  const arenaStreaks = Object.fromEntries(arenas.map(a => [a.id, getStreakForArena(a.id, sessions)]));

  // Re-letter arenas when they change
  const letteredArenas = arenas.map((a, i) => ({ ...a, letter: String.fromCharCode(65 + i) }));

  useEffect(() => {
    if (isRunning && !isPaused) {
      intervalRef.current = setInterval(() => {
        const endTime = parseInt(localStorage.getItem('timerEndTime'));
        const remaining = Math.round((endTime - Date.now()) / 1000);
        if (remaining <= 0) { clearInterval(intervalRef.current); setIsRunning(false); setTimeLeft(0); setScreen("complete"); }
        else setTimeLeft(remaining);
      }, 1000);
    } else clearInterval(intervalRef.current);
    return () => clearInterval(intervalRef.current);
  }, [isRunning, isPaused]);

  const saveArenas = (updated) => { setArenas(updated); save('arena_custom_arenas', updated); };

  const startArena = (gcal = false) => {
    const dur = effectiveDuration;
    if (!dur || dur <= 0) return;
    const now = new Date();
    const endTime = Date.now() + dur * 60 * 1000;
    localStorage.setItem('timerEndTime', endTime);
    setTimeLeft(dur * 60); setTotalTime(dur * 60); setIsRunning(true); setIsPaused(false); setLogToCalendar(gcal);
    setFocusExample(selectedArena.examples?.[Math.floor(Math.random() * (selectedArena.examples?.length || 1))] || "Stay focused.");
    if (gcal) {
      const end = new Date(endTime);
      const fmt = d => d.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";
      window.open(`https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(`[${selectedArena.label}] Focus Block`)}&dates=${fmt(now)}/${fmt(end)}&details=${encodeURIComponent(selectedArena.description || "")}`, "_blank");
    }
    setScreen("active");
    scheduleNotification(1, `${selectedArena.label} session complete`, "Your focus block has ended.", dur * 60);
  };

  const handlePause = () => {
    if (!isPaused) setIsPaused(true);
    else { localStorage.setItem('timerEndTime', Date.now() + timeLeft * 1000); setIsPaused(false); }
  };

  const handleArenaSelect = (arena) => { setSelectedArena(arena); setSessionNote(""); setScreen("select"); };

  const resetSession = () => {
    cancelNotification(1);
    setScreen("home"); setSelectedArena(null); setIsRunning(false);
    setLogToCalendar(false); setIsCustomActive(false); setCustomMinutes(""); setSessionNote("");
  };

  const handleComplete = () => {
    const s = { arenaId: selectedArena.id, duration: effectiveDuration, date: todayStr(), note: sessionNote, ts: Date.now() };
    const updated = [...sessions, s]; setSessions(updated); save('arena_sessions', updated);
    resetSession();
  };

  const progress = totalTime ? 1 - timeLeft / totalTime : 0;
  const circumference = 2 * Math.PI * 90;

  const wrap = (children, glow = null) => (
    <div style={{ minHeight: "100vh", background: "#080810", fontFamily: "'Courier New', monospace", color: "#E8E8E8", display: "flex", flexDirection: "column", alignItems: "center", position: "relative", overflow: "hidden" }}>
      {glow && <div style={{ position: "fixed", top: "-30%", left: "-20%", width: "140%", height: "120%", background: `radial-gradient(ellipse at 50% 20%, ${glow} 0%, transparent 55%)`, pointerEvents: "none", zIndex: 0 }} />}
      <div style={{ position: "relative", zIndex: 1, width: "100%", maxWidth: 430, minHeight: "100vh", display: "flex", flexDirection: "column" }}>{children}</div>
      <style>{globalStyles}</style>
    </div>
  );

  // ── Arena editor flow ──
  if (editingArena !== null) return wrap(
    <ArenaEditor
      arena={editingArena}
      onSave={(updated) => {
        const exists = arenas.find(a => a.id === updated.id);
        const newArenas = exists ? arenas.map(a => a.id === updated.id ? updated : a) : [...arenas, updated];
        saveArenas(newArenas); setEditingArena(null);
      }}
      onDelete={() => { saveArenas(arenas.filter(a => a.id !== editingArena.id)); setEditingArena(null); }}
      onClose={() => setEditingArena(null)}
    />
  );

  if (screen === "checkin") return wrap(<CheckinScreen onComplete={(completedCount) => {
  localStorage.setItem('arena_checkin_dismissed', todayStr());
  if (completedCount === MORNING_HABITS.length) {
    const now = new Date();
    const start = new Date(now.getTime() - 15 * 60 * 1000);
    const fmt = d => d.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";
    window.open(`https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent('[MORNING] Protocol Complete')}&dates=${fmt(start)}/${fmt(now)}&details=${encodeURIComponent('Reading · Goal Planning · Movement')}`, "_blank");
  }
  setScreen("home");
}} onSkip={() => { localStorage.setItem('arena_checkin_dismissed', todayStr()); setScreen("home"); }} />);
  if (screen === "notes") return wrap(<NotesScreen onBack={() => setScreen("home")} />);
  if (screen === "history") return wrap(<HistoryScreen onBack={() => setScreen("home")} sessions={sessions} arenas={letteredArenas} />);
  if (screen === "winddown") return wrap(<WindDownScreen onBack={() => setScreen("home")} onComplete={() => setScreen("home")} />);
  if (screen === "habits") return wrap(<HabitManager onBack={() => setScreen("home")} />);
  if (screen === "settings") return wrap(<SettingsScreen onBack={() => setScreen("home")} onNavigate={(s) => setScreen(s)} />);
  if (screen === "arenaEditor") return wrap(<div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 20px 32px" }}>
    <button onClick={() => setScreen("home")} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 28, textAlign: "left", padding: 0 }}>← BACK</button>
    <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>CUSTOMIZE</div>
    <div style={{ fontSize: 26, fontWeight: "bold", letterSpacing: 2, marginBottom: 20 }}>YOUR <span style={{ color: "#E8C547" }}>ARENAS</span></div>
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 9, flex: 1 }}>
      {letteredArenas.map((arena, i) => <ArenaCard key={arena.id} arena={arena} sessCount={0} streak={0} i={i} editMode onClick={() => {}} onEdit={() => setEditingArena(arena)} />)}
      <AddArenaCard i={letteredArenas.length} onClick={() => setEditingArena({})} />
    </div>
  </div>);
  if (screen === "stuck") return wrap(<StuckScreen onBack={() => setScreen("home")} onSelectArena={(arena) => { setSelectedArena(arena); setScreen("select"); }} arenas={letteredArenas} />);

  return wrap(
    <>
      {/* ── HOME ── */}
      {screen === "home" && (
        <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
          <div style={{ padding: "44px 20px 12px", display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div>
              <div style={{ fontSize: 9, letterSpacing: 6, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>ARENA PROTOCOL</div>
              <button onClick={() => setScreen("home")} style={{ background: "none", border: "none", padding: 0, cursor: "pointer", textAlign: "left" }}>
  <div style={{ fontSize: 22, fontWeight: "bold", letterSpacing: 2, lineHeight: 1.2 }}>ENTER THE<br /><span style={{ color: "#E8C547" }}>ARENA</span></div>
</button>
              {todaySessions > 0 && <div style={{ marginTop: 6, fontSize: 9, letterSpacing: 3, color: "rgba(255,255,255,0.25)" }}>● {todaySessions} SESSION{todaySessions !== 1 ? "S" : ""} TODAY</div>}
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 7, alignItems: "flex-end", marginTop: 4 }}>
              <button onClick={() => setScreen("notes")} style={topBtn("#E8C547")}>IDEA !</button>
              <button onClick={() => setScreen("history")} style={topBtn("#B794F4")}>STATS</button>
              <button onClick={() => setScreen("settings")} style={topBtn("rgba(255,255,255,0.4)")}>⚙</button>
            </div>
          </div>

          {/* Edit mode toggle */}
          <div style={{ padding: "0 20px 8px", display: "flex", justifyContent: "flex-end" }}>
            <button onClick={() => setEditMode(e => !e)} style={{ background: editMode ? "rgba(232,197,71,0.15)" : "none", border: editMode ? "1px solid rgba(232,197,71,0.4)" : "1px solid rgba(255,255,255,0.08)", borderRadius: 8, padding: "5px 12px", cursor: "pointer", color: editMode ? "#E8C547" : "rgba(255,255,255,0.25)", fontSize: 9, letterSpacing: 3, fontFamily: "'Courier New', monospace" }}>
              {editMode ? "DONE EDITING" : "EDIT ARENAS"}
            </button>
          </div>

          <div style={{ flex: 1, padding: "4px 14px 10px" }}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 9 }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
                {letteredArenas.slice(0, Math.ceil(letteredArenas.length / 2)).map((arena, i) => (
                  <ArenaCard key={arena.id} arena={arena} sessCount={sessions.filter(s => s.arenaId === arena.id && s.date === todayStr()).length} streak={arenaStreaks[arena.id] || 0} i={i} editMode={editMode} onClick={() => handleArenaSelect(arena)} onEdit={() => setEditingArena(arena)} />
                ))}
                {editMode && <AddArenaCard i={letteredArenas.length} onClick={() => setEditingArena({})} />}
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
                {letteredArenas.slice(Math.ceil(letteredArenas.length / 2)).map((arena, i) => (
                  <ArenaCard key={arena.id} arena={arena} sessCount={sessions.filter(s => s.arenaId === arena.id && s.date === todayStr()).length} streak={arenaStreaks[arena.id] || 0} i={i + Math.ceil(letteredArenas.length / 2)} editMode={editMode} onClick={() => handleArenaSelect(arena)} onEdit={() => setEditingArena(arena)} />
                ))}
              </div>
            </div>
          </div>

          <div style={{ padding: "10px 14px 12px" }}>
            <button onClick={() => setScreen("stuck")} style={{ width: "100%", padding: "14px", background: "rgba(255,143,163,0.06)", border: "1px solid rgba(255,143,163,0.25)", borderRadius: 14, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 10, fontFamily: "'Courier New', monospace" }}
              onPointerEnter={e => { e.currentTarget.style.background = "rgba(255,143,163,0.12)"; }}
              onPointerLeave={e => { e.currentTarget.style.background = "rgba(255,143,163,0.06)"; }}>
              <span style={{ fontSize: 13, color: "#FF8FA3" }}>⚡</span>
              <span style={{ fontSize: 11, letterSpacing: 4, color: "#FF8FA3", fontWeight: "bold" }}>I AM STUCK</span>
            </button>
          </div>

          <div style={{ padding: "8px 20px 24px", borderTop: "1px solid rgba(255,255,255,0.05)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ fontSize: 11, color: "rgba(255,255,255,0.3)", letterSpacing: 2 }}>SELECT AN ARENA</span>
            <div style={{ display: "flex", gap: 12 }}>
              <button onClick={() => setScreen("checkin")} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.2)", cursor: "pointer", fontSize: 10, letterSpacing: 2, fontFamily: "'Courier New', monospace" }}>☀ MORNING</button>
              <button onClick={() => setScreen("winddown")} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.2)", cursor: "pointer", fontSize: 10, letterSpacing: 2, fontFamily: "'Courier New', monospace" }}>☾ WIND DOWN</button>
            </div>
          </div>
        </div>
      )}

      {/* ── SELECT ── */}
      {screen === "select" && selectedArena && (
        <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "48px 24px 32px", overflowY: "auto" }}>
          <button onClick={() => { setScreen("home"); setIsCustomActive(false); setCustomMinutes(""); }} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 36, textAlign: "left", padding: 0 }}>← BACK</button>
          <div style={{ fontSize: 10, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>ARENA {selectedArena.letter}</div>
          <div style={{ fontSize: 36, fontWeight: "bold", letterSpacing: 3, color: selectedArena.color, marginBottom: 10 }}>{selectedArena.label}</div>
          <div style={{ fontSize: 12, color: "rgba(255,255,255,0.45)", marginBottom: 28, lineHeight: 1.7 }}>{selectedArena.description}</div>
          {selectedArena.examples?.length > 0 && (
            <div style={{ marginBottom: 28 }}>
              <div style={labelStyle}>EXAMPLES</div>
              {selectedArena.examples.map((ex, i) => (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "10px 0", borderBottom: "1px solid rgba(255,255,255,0.05)", fontSize: 12, color: "rgba(255,255,255,0.55)" }}>
                  <div style={{ width: 4, height: 4, borderRadius: "50%", background: selectedArena.color, flexShrink: 0 }} />{ex}
                </div>
              ))}
            </div>
          )}
          <div style={{ marginBottom: 24 }}>
            <div style={labelStyle}>BLOCK DURATION</div>
            <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
              {DURATIONS.map(d => <button key={d.value} onClick={() => { setSelectedDuration(d.value); setIsCustomActive(false); }} style={{ padding: "10px 12px", borderRadius: 10, flex: 1, border: !isCustomActive && selectedDuration === d.value ? `1.5px solid ${selectedArena.color}` : "1px solid rgba(255,255,255,0.1)", background: !isCustomActive && selectedDuration === d.value ? `${selectedArena.color}18` : "transparent", color: !isCustomActive && selectedDuration === d.value ? selectedArena.color : "rgba(255,255,255,0.4)", cursor: "pointer", fontSize: 11, letterSpacing: 2, fontFamily: "'Courier New', monospace" }}>{d.label}</button>)}
              <button onClick={() => setIsCustomActive(true)} style={{ padding: "10px 12px", borderRadius: 10, flex: 1, border: isCustomActive ? `1.5px solid ${selectedArena.color}` : "1px solid rgba(255,255,255,0.1)", background: isCustomActive ? `${selectedArena.color}18` : "transparent", color: isCustomActive ? selectedArena.color : "rgba(255,255,255,0.4)", cursor: "pointer", fontSize: 11, letterSpacing: 2, fontFamily: "'Courier New', monospace" }}>other</button>
            </div>
            {isCustomActive && <div style={{ marginTop: 10, display: "flex", alignItems: "center", gap: 10 }}>
              <input type="number" min="1" max="480" value={customMinutes} onChange={e => setCustomMinutes(e.target.value)} placeholder="min" autoFocus style={{ ...inputStyle, flex: 1, textAlign: "center", fontSize: 16, color: selectedArena.color, borderColor: selectedArena.color, background: `${selectedArena.color}10` }} />
              <div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", letterSpacing: 2 }}>MINUTES</div>
            </div>}
          </div>
          <div style={{ marginBottom: 28 }}>
            <div style={labelStyle}>NOTE <span style={{ color: "rgba(255,255,255,0.15)" }}>— OPTIONAL</span></div>
            <textarea value={sessionNote} onChange={e => setSessionNote(e.target.value)} placeholder="What specifically are you working on?" rows={2} style={{ ...inputStyle, resize: "none", lineHeight: 1.5, borderColor: sessionNote ? selectedArena.color + '50' : undefined }} />
          </div>
          <div>
            <div style={labelStyle}>ADD TO GOOGLE CALENDAR?</div>
            <div style={{ display: "flex", gap: 10 }}>
              <button onClick={() => durationValid && startArena(true)} style={{ flex: 1, padding: "16px", background: "transparent", border: `1px solid ${durationValid ? selectedArena.color : "rgba(255,255,255,0.1)"}`, borderRadius: 12, color: durationValid ? selectedArena.color : "rgba(255,255,255,0.2)", fontSize: 12, letterSpacing: 4, cursor: durationValid ? "pointer" : "not-allowed", fontFamily: "'Courier New', monospace" }}>YES</button>
              <button onClick={() => durationValid && startArena(false)} style={{ flex: 1, padding: "16px", background: "transparent", border: `1px solid ${durationValid ? "rgba(255,255,255,0.2)" : "rgba(255,255,255,0.07)"}`, borderRadius: 12, color: durationValid ? "rgba(255,255,255,0.55)" : "rgba(255,255,255,0.2)", fontSize: 12, letterSpacing: 4, cursor: durationValid ? "pointer" : "not-allowed", fontFamily: "'Courier New', monospace" }}>NO</button>
            </div>
            {!durationValid && <div style={{ fontSize: 9, color: "rgba(255,255,255,0.25)", letterSpacing: 2, marginTop: 10, textAlign: "center" }}>ENTER A DURATION FIRST</div>}
          </div>
        </div>
      )}

      {/* ── ACTIVE ── */}
      {screen === "active" && selectedArena && (
        <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px 24px", gap: 32 }}>
          <div style={{ textAlign: "center" }}>
            <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>{isPaused ? "PAUSED" : "NOW IN"}</div>
            <div style={{ fontSize: 22, fontWeight: "bold", letterSpacing: 5, color: selectedArena.color }}>{selectedArena.label}</div>
            {sessionNote && <div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", marginTop: 6, fontStyle: "italic" }}>{sessionNote}</div>}
          </div>
          <div style={{ position: "relative", width: 220, height: 220 }}>
            <svg width="220" height="220" style={{ transform: "rotate(-90deg)" }}>
              <circle cx="110" cy="110" r="90" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="6" />
              <circle cx="110" cy="110" r="90" fill="none" stroke={selectedArena.color} strokeWidth="6" strokeLinecap="round" strokeDasharray={circumference} strokeDashoffset={circumference * (1 - progress)} style={{ transition: "stroke-dashoffset 1s linear", filter: `drop-shadow(0 0 10px ${selectedArena.color})` }} />
            </svg>
            <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
              <div style={{ fontSize: 46, fontWeight: "bold", letterSpacing: 3, color: selectedArena.color, fontVariantNumeric: "tabular-nums" }}>{formatTime(timeLeft)}</div>
              <div style={{ fontSize: 9, letterSpacing: 3, color: "rgba(255,255,255,0.25)", marginTop: 6 }}>REMAINING</div>
            </div>
          </div>
          <div style={{ padding: "14px 20px", background: "rgba(255,255,255,0.04)", borderRadius: 12, border: "1px solid rgba(255,255,255,0.06)", textAlign: "center", maxWidth: 280 }}>
            <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 8 }}>FOCUS ON</div>
            <div style={{ fontSize: 13, color: "rgba(255,255,255,0.65)", lineHeight: 1.5 }}>{focusExample}</div>
          </div>
          <div style={{ display: "flex", gap: 10, width: "100%" }}>
            <button onClick={handlePause} style={{ flex: 1, padding: "15px", background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: 12, color: "rgba(255,255,255,0.7)", fontSize: 11, letterSpacing: 4, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>{isPaused ? "RESUME" : "PAUSE"}</button>
            <button onClick={() => { setIsRunning(false); setScreen("complete"); }} style={{ flex: 1, padding: "15px", background: `${selectedArena.color}18`, border: `1px solid ${selectedArena.color}`, borderRadius: 12, color: selectedArena.color, fontSize: 11, letterSpacing: 4, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>DONE</button>
          </div>
          <button onClick={resetSession} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.18)", cursor: "pointer", fontSize: 9, letterSpacing: 3 }}>ABANDON SESSION</button>
        </div>
      )}

      {/* ── COMPLETE ── */}
      {screen === "complete" && selectedArena && (
        <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px 24px", gap: 24, textAlign: "center" }}>
          <div style={{ fontSize: 56, color: selectedArena.color, filter: `drop-shadow(0 0 20px ${selectedArena.color})`, animation: "pop 0.4s ease" }}>{selectedArena.icon}</div>
          <div>
            <div style={{ fontSize: 10, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 8 }}>SESSION COMPLETE</div>
            <div style={{ fontSize: 34, fontWeight: "bold", letterSpacing: 3, color: selectedArena.color }}>{selectedArena.label}</div>
            <div style={{ fontSize: 12, color: "rgba(255,255,255,0.4)", marginTop: 8, letterSpacing: 3 }}>{effectiveDuration} MINUTES</div>
            {sessionNote && <div style={{ fontSize: 12, color: "rgba(255,255,255,0.3)", marginTop: 6, fontStyle: "italic" }}>{sessionNote}</div>}
          </div>
          {logToCalendar && <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)", letterSpacing: 3 }}>● LOGGED TO CALENDAR</div>}
          <button onClick={handleComplete} style={{ width: "100%", maxWidth: 320, padding: "18px", background: selectedArena.color, border: "none", borderRadius: 14, color: "#080810", fontSize: 13, fontWeight: "bold", letterSpacing: 5, cursor: "pointer", fontFamily: "'Courier New', monospace", boxShadow: `0 0 32px ${glowFor(selectedArena.color)}` }}>DONE</button>
        </div>
      )}
    </>,
    selectedArena ? glowFor(selectedArena.color) : null
  );
}

const topBtn = (color) => ({ background: `${color}18`, border: `1px solid ${color}40`, borderRadius: 10, padding: "7px 11px", cursor: "pointer", color, fontSize: 10, letterSpacing: 2, fontFamily: "'Courier New', monospace" });

const globalStyles = `
  @keyframes fadeUp { from { opacity: 0; transform: translateY(18px); } to { opacity: 1; transform: translateY(0); } }
  @keyframes pop { 0% { transform: scale(0.5); opacity: 0; } 70% { transform: scale(1.15); } 100% { transform: scale(1); opacity: 1; } }
  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
  body { margin: 0; }
  button:active { opacity: 0.75; }
  textarea::placeholder, input::placeholder { color: rgba(255,255,255,0.2); }
  input[type="time"]::-webkit-calendar-picker-indicator { filter: invert(1); opacity: 0.5; }
`;
