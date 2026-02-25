import { LocalNotifications } from '@capacitor/local-notifications';
import { useState, useEffect, useRef } from "react";

const ARENAS = [
  {
    id: "work",
    label: "WORK",
    letter: "A",
    color: "#E8C547",
    glow: "rgba(232,197,71,0.3)",
    description: "Anything that moves your professional life forward or protects your income. Emails, reports, outreach, meetings, skill-building for your career, business planning, or revenue-generating tasks.",
    examples: ["Reply to one email", "Update one metric", "Research one lead", "Outline webinar ideas", "Prep for a meeting", "Send a follow-up"],
    icon: "◈",
  },
  {
    id: "body",
    label: "BODY",
    letter: "B",
    color: "#4ECDC4",
    glow: "rgba(78,205,196,0.3)",
    description: "Anything that improves your physical or mental state. Exercise, stretching, walking, sleep optimization, hydration, nutrition, breathwork, or nervous system regulation.",
    examples: ["10 pushups", "5-minute walk", "Refill water bottle", "Quick mobility stretch", "Breathwork for 5 min", "Prep a real meal"],
    icon: "◎",
  },
  {
    id: "environment",
    label: "ENVIRONMENT",
    letter: "C",
    color: "#A8E6A3",
    glow: "rgba(168,230,163,0.3)",
    description: "Anything that improves your physical space or reduces chaos around you. Cleaning, organizing, laundry, resetting your desk, or preparing for tomorrow so your future self isn't starting from friction.",
    examples: ["Clear desk surface", "10 min laundry", "Take trash out", "Make bed", "Prep clothes for tomorrow", "Wipe down kitchen"],
    icon: "⬡",
  },
  {
    id: "relationships",
    label: "RELATIONSHIPS",
    letter: "D",
    color: "#FF8FA3",
    glow: "rgba(255,143,163,0.3)",
    description: "Anything that strengthens connection with others. Texting friends, following up with contacts, calling family, pursuing romantic connection, or simply being present with someone who matters.",
    examples: ["Send one thoughtful text", "Reply to one match", "Schedule coffee", "Check in with sibling", "Write a voice note", "Plan something with a friend"],
    icon: "◇",
  },
  {
    id: "build",
    label: "BUILD",
    letter: "E",
    color: "#B794F4",
    glow: "rgba(183,148,244,0.3)",
    description: "Anything that builds your future beyond your current job. Side projects, personal brand, creative work, financial planning, or planting seeds that will compound over time.",
    examples: ["Outline a business idea", "Write 200 words", "Design one draft", "Review investment strategy", "Record a voice memo idea", "Research a new skill"],
    icon: "△",
  },
  {
    id: "recover",
    label: "RECOVER",
    letter: "F",
    color: "#F4A261",
    glow: "rgba(244,162,97,0.3)",
    description: "Intentional rest that restores energy without spiraling. Reading, music, light gaming, journaling, meditation — the key word is intentional. You chose this. It has a container. It ends.",
    examples: ["Read 10 pages", "Journal one page", "15-min show timer", "Lie down and breathe", "Listen to one album", "Meditate for 10 min"],
    icon: "○",
  },
];

const DURATIONS = [
  { label: "15m", value: 15 },
  { label: "25m", value: 25 },
  { label: "45m", value: 45 },
  { label: "60m", value: 60 },
  { label: "90m", value: 90 },
];

function formatTime(seconds) {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

async function scheduleTimerNotification(durationSeconds, arenaLabel) {
  try {
    await LocalNotifications.requestPermissions();
    await LocalNotifications.cancel({ notifications: [{ id: 1 }] });
    await LocalNotifications.schedule({
      notifications: [{
        id: 1,
        title: `${arenaLabel} session complete`,
        body: "Your focus block has ended.",
        schedule: { at: new Date(Date.now() + durationSeconds * 1000) },
        sound: 'default',
      }]
    });
  } catch (e) {
    console.log('Notification error:', e);
  }
}

async function cancelTimerNotification() {
  try {
    await LocalNotifications.cancel({ notifications: [{ id: 1 }] });
  } catch (e) {}
}

function ArenaCard({ arena, sessCount, i, onClick }) {
  return (
    <button
      onClick={onClick}
      style={{
        background: "rgba(255,255,255,0.03)",
        border: "1px solid rgba(255,255,255,0.07)",
        borderRadius: 16,
        padding: "18px 14px",
        cursor: "pointer",
        textAlign: "left",
        position: "relative",
        overflow: "hidden",
        transition: "all 0.25s ease",
        animation: `fadeUp 0.5s ease ${i * 0.07}s both`,
        width: "100%",
      }}
      onPointerEnter={e => {
        e.currentTarget.style.border = `1px solid ${arena.color}50`;
        e.currentTarget.style.background = "rgba(255,255,255,0.06)";
        e.currentTarget.style.transform = "translateY(-3px)";
        e.currentTarget.style.boxShadow = `0 8px 24px ${arena.glow}`;
      }}
      onPointerLeave={e => {
        e.currentTarget.style.border = "1px solid rgba(255,255,255,0.07)";
        e.currentTarget.style.background = "rgba(255,255,255,0.03)";
        e.currentTarget.style.transform = "translateY(0)";
        e.currentTarget.style.boxShadow = "none";
      }}
    >
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 2, background: arena.color, borderRadius: "16px 16px 0 0" }} />
      <div style={{ fontSize: 10, color: "rgba(255,255,255,0.25)", letterSpacing: 4, marginBottom: 10 }}>{arena.letter}</div>
      <div style={{ fontSize: 20, color: arena.color, marginBottom: 6 }}>{arena.icon}</div>
      <div style={{ fontSize: 12, fontWeight: "bold", letterSpacing: 2, color: "#E8E8E8" }}>{arena.label}</div>
      {sessCount > 0 && (
        <div style={{ position: "absolute", top: 10, right: 10, fontSize: 8, color: arena.color, letterSpacing: 1 }}>● {sessCount}</div>
      )}
    </button>
  );
}

export default function App() {
  const [screen, setScreen] = useState("home");
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
  const [completedSessions, setCompletedSessions] = useState([]);
  const [focusExample, setFocusExample] = useState("");
  const startTimeRef = useRef(null);
  const intervalRef = useRef(null);

  const effectiveDuration = isCustomActive && parseInt(customMinutes) > 0
    ? parseInt(customMinutes)
    : selectedDuration;
  const durationValid = !(isCustomActive && (!customMinutes || parseInt(customMinutes) <= 0));

  useEffect(() => {
  if (isRunning && !isPaused) {
    intervalRef.current = setInterval(() => {
      const endTime = parseInt(localStorage.getItem('timerEndTime'));
      const remaining = Math.round((endTime - Date.now()) / 1000);
      if (remaining <= 0) {
        clearInterval(intervalRef.current);
        setIsRunning(false);
        setTimeLeft(0);
        setScreen("complete");
      } else {
        setTimeLeft(remaining);
      }
    }, 1000);
  } else {
    clearInterval(intervalRef.current);
  }
  return () => clearInterval(intervalRef.current);
}, [isRunning, isPaused]);

const startArena = (gcal = false) => {
  const dur = effectiveDuration;
  if (!dur || dur <= 0) return;
  const now = new Date();
  startTimeRef.current = now;
  const endTime = Date.now() + dur * 60 * 1000;
  localStorage.setItem('timerEndTime', endTime);
  setTimeLeft(dur * 60);
  setTotalTime(dur * 60);
  setIsRunning(true);
  setIsPaused(false);
  setLogToCalendar(gcal);
  setFocusExample(selectedArena.examples[Math.floor(Math.random() * selectedArena.examples.length)]);
  if (gcal) {
    const end = new Date(endTime);
    const fmt = (d) => d.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";
    const details = [selectedArena.description, sessionNote ? `Note: ${sessionNote}` : ""].filter(Boolean).join("\n\n");
    window.open(`https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(`[${selectedArena.label}] Focus Block`)}&dates=${fmt(now)}/${fmt(end)}&details=${encodeURIComponent(details)}`, "_blank");
  }
  setScreen("active");
  scheduleTimerNotification(dur * 60, selectedArena.label);
};

  const handleArenaSelect = (arena) => {
    setSelectedArena(arena);
    setSessionNote("");
    setScreen("select");
  };

  const resetSession = () => {
    cancelTimerNotification();
    setScreen("home");
    setSelectedArena(null);
    setIsRunning(false);
    setLogToCalendar(false);
    setIsCustomActive(false);
    setCustomMinutes("");
    setSessionNote("");
    startTimeRef.current = null;
  };

  const handleComplete = () => {
    setCompletedSessions((prev) => [...prev, { arena: selectedArena, duration: effectiveDuration }]);
    resetSession();
  };

  const progress = totalTime ? 1 - timeLeft / totalTime : 0;
  const circumference = 2 * Math.PI * 90;

  return (
    <div style={{
      minHeight: "100vh", background: "#080810",
      fontFamily: "'Courier New', monospace", color: "#E8E8E8",
      display: "flex", flexDirection: "column", alignItems: "center",
      position: "relative", overflow: "hidden",
    }}>
      {selectedArena && (
        <div style={{
          position: "fixed", top: "-30%", left: "-20%", width: "140%", height: "120%",
          background: `radial-gradient(ellipse at 50% 20%, ${selectedArena.glow} 0%, transparent 55%)`,
          pointerEvents: "none", zIndex: 0, transition: "all 1.2s ease",
        }} />
      )}

      <div style={{ position: "relative", zIndex: 1, width: "100%", maxWidth: 430, minHeight: "100vh", display: "flex", flexDirection: "column" }}>

        {/* ── HOME ── */}
        {screen === "home" && (
          <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
            <div style={{ padding: "52px 24px 20px" }}>
              <div style={{ fontSize: 10, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 10 }}>ARENA PROTOCOL</div>
              <div style={{ fontSize: 26, fontWeight: "bold", letterSpacing: 2, lineHeight: 1.2 }}>
                WHERE IS YOUR<br />ATTENTION?
              </div>
              {completedSessions.length > 0 && (
                <div style={{ marginTop: 10, fontSize: 10, letterSpacing: 4, color: "rgba(255,255,255,0.25)" }}>
                  ● {completedSessions.length} SESSION{completedSessions.length !== 1 ? "S" : ""} LOGGED TODAY
                </div>
              )}
            </div>

            <div style={{ flex: 1, padding: "8px 16px 24px" }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
                <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                  {ARENAS.slice(0, 3).map((arena, i) => (
                    <ArenaCard key={arena.id} arena={arena} sessCount={completedSessions.filter(s => s.arena.id === arena.id).length} i={i} onClick={() => handleArenaSelect(arena)} />
                  ))}
                </div>
                <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                  {ARENAS.slice(3, 6).map((arena, i) => (
                    <ArenaCard key={arena.id} arena={arena} sessCount={completedSessions.filter(s => s.arena.id === arena.id).length} i={i + 3} onClick={() => handleArenaSelect(arena)} />
                  ))}
                </div>
              </div>
            </div>

            <div style={{ padding: "12px 24px", borderTop: "1px solid rgba(255,255,255,0.05)", fontSize: 9, color: "rgba(255,255,255,0.18)", letterSpacing: 3, textAlign: "center" }}>
              SELECT AN ARENA TO BEGIN
            </div>
          </div>
        )}

        {/* ── SELECT / CONFIGURE ── */}
        {screen === "select" && selectedArena && (
          <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "48px 24px 32px", overflowY: "auto" }}>
            <button
              onClick={() => { setScreen("home"); setIsCustomActive(false); setCustomMinutes(""); }}
              style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 36, textAlign: "left", padding: 0 }}
            >← BACK</button>

            <div style={{ fontSize: 10, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>ARENA {selectedArena.letter}</div>
            <div style={{ fontSize: 36, fontWeight: "bold", letterSpacing: 3, color: selectedArena.color, marginBottom: 10 }}>{selectedArena.label}</div>
            <div style={{ fontSize: 12, color: "rgba(255,255,255,0.45)", marginBottom: 28, lineHeight: 1.7 }}>{selectedArena.description}</div>

            {/* Examples */}
            <div style={{ marginBottom: 28 }}>
              <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 12 }}>EXAMPLES</div>
              {selectedArena.examples.map((ex, i) => (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "10px 0", borderBottom: "1px solid rgba(255,255,255,0.05)", fontSize: 12, color: "rgba(255,255,255,0.55)" }}>
                  <div style={{ width: 4, height: 4, borderRadius: "50%", background: selectedArena.color, flexShrink: 0 }} />
                  {ex}
                </div>
              ))}
            </div>

            {/* Duration */}
            <div style={{ marginBottom: 24 }}>
              <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 12 }}>BLOCK DURATION</div>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {DURATIONS.map((d) => (
                  <button key={d.value} onClick={() => { setSelectedDuration(d.value); setIsCustomActive(false); }} style={{
                    padding: "10px 12px", borderRadius: 10, flex: 1,
                    border: !isCustomActive && selectedDuration === d.value ? `1.5px solid ${selectedArena.color}` : "1px solid rgba(255,255,255,0.1)",
                    background: !isCustomActive && selectedDuration === d.value ? `${selectedArena.color}18` : "transparent",
                    color: !isCustomActive && selectedDuration === d.value ? selectedArena.color : "rgba(255,255,255,0.4)",
                    cursor: "pointer", fontSize: 11, letterSpacing: 2,
                    fontFamily: "'Courier New', monospace", transition: "all 0.2s",
                  }}>{d.label}</button>
                ))}
                <button onClick={() => setIsCustomActive(true)} style={{
                  padding: "10px 12px", borderRadius: 10, flex: 1,
                  border: isCustomActive ? `1.5px solid ${selectedArena.color}` : "1px solid rgba(255,255,255,0.1)",
                  background: isCustomActive ? `${selectedArena.color}18` : "transparent",
                  color: isCustomActive ? selectedArena.color : "rgba(255,255,255,0.4)",
                  cursor: "pointer", fontSize: 11, letterSpacing: 2,
                  fontFamily: "'Courier New', monospace", transition: "all 0.2s",
                }}>custom</button>
              </div>
              {isCustomActive && (
                <div style={{ marginTop: 10, display: "flex", alignItems: "center", gap: 10 }}>
                  <input
                    type="number" min="1" max="480" value={customMinutes}
                    onChange={e => setCustomMinutes(e.target.value)}
                    placeholder="min" autoFocus
                    style={{
                      flex: 1, padding: "12px 14px", borderRadius: 10,
                      border: `1.5px solid ${selectedArena.color}`,
                      background: `${selectedArena.color}10`, color: selectedArena.color,
                      fontSize: 16, fontFamily: "'Courier New', monospace",
                      letterSpacing: 2, outline: "none", textAlign: "center",
                    }}
                  />
                  <div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", letterSpacing: 2 }}>MINUTES</div>
                </div>
              )}
            </div>

            {/* Note */}
            <div style={{ marginBottom: 28 }}>
              <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 12 }}>
                NOTE <span style={{ color: "rgba(255,255,255,0.15)", letterSpacing: 2 }}>— OPTIONAL</span>
              </div>
              <textarea
                value={sessionNote}
                onChange={e => setSessionNote(e.target.value)}
                placeholder="What specifically are you working on?"
                rows={2}
                style={{
                  width: "100%", padding: "12px 14px", borderRadius: 10,
                  border: sessionNote ? `1px solid ${selectedArena.color}50` : "1px solid rgba(255,255,255,0.08)",
                  background: "rgba(255,255,255,0.03)", color: "rgba(255,255,255,0.7)",
                  fontSize: 12, fontFamily: "'Courier New', monospace",
                  lineHeight: 1.5, resize: "none", outline: "none",
                  transition: "border 0.2s", boxSizing: "border-box",
                }}
              />
              <div style={{ fontSize: 9, color: "rgba(255,255,255,0.2)", letterSpacing: 1, marginTop: 6 }}>
                Added to Google Calendar description if logging
              </div>
            </div>

            {/* GCal Y/N */}
            <div>
              <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 12 }}>ADD TO GOOGLE CALENDAR?</div>
              <div style={{ display: "flex", gap: 10 }}>
                <button
                  onClick={() => durationValid && startArena(true)}
                  style={{
                    flex: 1, padding: "16px", background: "transparent",
                    border: `1px solid ${durationValid ? selectedArena.color : "rgba(255,255,255,0.1)"}`,
                    borderRadius: 12, color: durationValid ? selectedArena.color : "rgba(255,255,255,0.2)",
                    fontSize: 12, letterSpacing: 4,
                    cursor: durationValid ? "pointer" : "not-allowed",
                    fontFamily: "'Courier New', monospace", transition: "all 0.2s",
                  }}
                >YES</button>
                <button
                  onClick={() => durationValid && startArena(false)}
                  style={{
                    flex: 1, padding: "16px", background: "transparent",
                    border: `1px solid ${durationValid ? "rgba(255,255,255,0.2)" : "rgba(255,255,255,0.07)"}`,
                    borderRadius: 12, color: durationValid ? "rgba(255,255,255,0.55)" : "rgba(255,255,255,0.2)",
                    fontSize: 12, letterSpacing: 4,
                    cursor: durationValid ? "pointer" : "not-allowed",
                    fontFamily: "'Courier New', monospace", transition: "all 0.2s",
                  }}
                >NO</button>
              </div>
              {!durationValid && (
                <div style={{ fontSize: 9, color: "rgba(255,255,255,0.25)", letterSpacing: 2, marginTop: 10, textAlign: "center" }}>
                  ENTER A DURATION FIRST
                </div>
              )}
            </div>
          </div>
        )}

        {/* ── ACTIVE TIMER ── */}
        {screen === "active" && selectedArena && (
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px 24px", gap: 32 }}>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>{isPaused ? "PAUSED" : "NOW IN"}</div>
              <div style={{ fontSize: 22, fontWeight: "bold", letterSpacing: 5, color: selectedArena.color }}>{selectedArena.label}</div>
              {sessionNote ? <div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", marginTop: 6, fontStyle: "italic" }}>{sessionNote}</div> : null}
            </div>

            <div style={{ position: "relative", width: 220, height: 220 }}>
              <svg width="220" height="220" style={{ transform: "rotate(-90deg)" }}>
                <circle cx="110" cy="110" r="90" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="6" />
                <circle cx="110" cy="110" r="90" fill="none"
                  stroke={selectedArena.color} strokeWidth="6" strokeLinecap="round"
                  strokeDasharray={circumference} strokeDashoffset={circumference * (1 - progress)}
                  style={{ transition: "stroke-dashoffset 1s linear", filter: `drop-shadow(0 0 10px ${selectedArena.color})` }}
                />
              </svg>
              <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
                <div style={{ fontSize: 46, fontWeight: "bold", letterSpacing: 3, color: selectedArena.color, fontVariantNumeric: "tabular-nums" }}>
                  {formatTime(timeLeft)}
                </div>
                <div style={{ fontSize: 9, letterSpacing: 3, color: "rgba(255,255,255,0.25)", marginTop: 6 }}>REMAINING</div>
              </div>
            </div>

            <div style={{ padding: "14px 20px", background: "rgba(255,255,255,0.04)", borderRadius: 12, border: "1px solid rgba(255,255,255,0.06)", textAlign: "center", maxWidth: 280 }}>
              <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)", marginBottom: 8 }}>FOCUS ON</div>
              <div style={{ fontSize: 13, color: "rgba(255,255,255,0.65)", lineHeight: 1.5 }}>{focusExample}</div>
            </div>

            <div style={{ display: "flex", gap: 10, width: "100%" }}>
              <button onClick={() => setIsPaused(p => !p)} style={{
                flex: 1, padding: "15px", background: "rgba(255,255,255,0.05)",
                border: "1px solid rgba(255,255,255,0.1)", borderRadius: 12,
                color: "rgba(255,255,255,0.7)", fontSize: 11, letterSpacing: 4,
                cursor: "pointer", fontFamily: "'Courier New', monospace",
              }}>{isPaused ? "RESUME" : "PAUSE"}</button>
              <button onClick={() => { setIsRunning(false); setScreen("complete"); }} style={{
                flex: 1, padding: "15px", background: `${selectedArena.color}18`,
                border: `1px solid ${selectedArena.color}`, borderRadius: 12,
                color: selectedArena.color, fontSize: 11, letterSpacing: 4,
                cursor: "pointer", fontFamily: "'Courier New', monospace",
              }}>DONE</button>
            </div>

            <button onClick={resetSession} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.18)", cursor: "pointer", fontSize: 9, letterSpacing: 3 }}>
              ABANDON SESSION
            </button>
          </div>
        )}

        {/* ── COMPLETE ── */}
        {screen === "complete" && selectedArena && (
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px 24px", gap: 24, textAlign: "center" }}>
            <div style={{ fontSize: 56, color: selectedArena.color, filter: `drop-shadow(0 0 20px ${selectedArena.color})`, animation: "pop 0.4s ease" }}>
              {selectedArena.icon}
            </div>
            <div>
              <div style={{ fontSize: 10, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 8 }}>SESSION COMPLETE</div>
              <div style={{ fontSize: 34, fontWeight: "bold", letterSpacing: 3, color: selectedArena.color }}>{selectedArena.label}</div>
              <div style={{ fontSize: 12, color: "rgba(255,255,255,0.4)", marginTop: 8, letterSpacing: 3 }}>{effectiveDuration} MINUTES</div>
              {sessionNote ? <div style={{ fontSize: 12, color: "rgba(255,255,255,0.3)", marginTop: 6, fontStyle: "italic" }}>{sessionNote}</div> : null}
            </div>
            {logToCalendar && (
              <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)", letterSpacing: 3 }}>● LOGGED TO CALENDAR</div>
            )}
            <button onClick={handleComplete} style={{
              width: "100%", maxWidth: 320, padding: "18px",
              background: selectedArena.color, border: "none", borderRadius: 14,
              color: "#080810", fontSize: 13, fontWeight: "bold", letterSpacing: 5,
              cursor: "pointer", fontFamily: "'Courier New', monospace",
              boxShadow: `0 0 32px ${selectedArena.glow}`,
            }}>DONE</button>
          </div>
        )}
      </div>

      <style>{`
        @keyframes fadeUp {
          from { opacity: 0; transform: translateY(18px); }
          to   { opacity: 1; transform: translateY(0); }
        }
        @keyframes pop {
          0%   { transform: scale(0.5); opacity: 0; }
          70%  { transform: scale(1.15); }
          100% { transform: scale(1); opacity: 1; }
        }
        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        body { margin: 0; }
        button:active { opacity: 0.75; }
        textarea::placeholder { color: rgba(255,255,255,0.2); }
      `}</style>
    </div>
  );
}
