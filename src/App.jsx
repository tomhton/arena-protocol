import { useState, useEffect, useRef } from "react";

// ── NOTIFICATIONS (mock for browser, real on iOS) ──────────────────────────────
const LocalNotifications = {
  requestPermissions: async () => {},
  cancel: async () => {},
  schedule: async () => {},
};

// ── DEFAULT ARENAS ─────────────────────────────────────────────────────────────
const DEFAULT_ARENAS = [
  {
    id: "body", label: "BODY", letter: "A", color: "#C0392B",
    description: "The instrument. Without it, nothing else functions. Move it, fuel it, rest it.",
    icon: "◉",
    examples: ["10 min walk", "20 pushups", "Cold shower", "Cook a real meal", "Sleep before midnight", "5 min breathwork", "Stretch for 10 min", "Drink 2L of water"],
    subArenas: {
      "MOVE": ["10 min walk", "20 pushups", "Cold shower", "Stretch for 10 min"],
      "FUEL": ["Cook a real meal", "Drink 2L of water", "Prep meals for tomorrow", "No sugar today"],
      "REST": ["Sleep before midnight", "5 min breathwork", "20 min nap", "Legs up the wall 10 min"],
    },
  },
  {
    id: "spirit", label: "SPIRIT", letter: "B", color: "#D4A017",
    description: "The inner fire. Who you are beneath the noise. Purpose, identity, the story you tell yourself.",
    icon: "★",
    examples: ["Write 3 things you're grateful for", "Journal one page", "Read 10 pages", "Meditate 10 min", "Define today's one intention", "Review your goals", "Visualize your future self", "Name one lie depression told you today"],
    subArenas: {
      "REFLECT": ["Write 3 things you're grateful for", "Journal one page", "Define today's one intention", "Name one lie depression told you today"],
      "READ": ["Read 10 pages", "Review your goals", "Read one article that challenges you", "Reread a passage that matters"],
      "MEDITATE": ["Meditate 10 min", "Visualize your future self", "4-7-8 breathing for 5 min", "Sit in silence for 5 min"],
    },
  },
  {
    id: "tribe", label: "TRIBE", letter: "C", color: "#B87333",
    description: "The hearth. You exist because of others. Show up for them — and let them show up for you.",
    icon: "◇",
    examples: ["Send one meaningful text", "Call someone you've been avoiding", "Plan something with a friend", "Reply to a message you've been ignoring", "Tell someone you appreciate them", "Check in on family", "Accept an invitation"],
    subArenas: {
      "REACH OUT": ["Send one meaningful text", "Call someone you've been avoiding", "Tell someone you appreciate them", "Reply to a message you've been ignoring"],
      "SHOW UP": ["Check in on family", "Accept an invitation", "Be present — no phone for one hour", "Do something kind without being asked"],
      "PLAN": ["Plan something with a friend", "Schedule a catch-up call", "Suggest a date or activity", "Book something you'll look forward to"],
    },
  },
  {
    id: "craft", label: "CRAFT", letter: "D", color: "#708090",
    description: "The work. What you are building in the world — your output, your mastery, your mark.",
    icon: "△",
    examples: ["Send one important email", "Complete one work task", "Work on a side project for 25 min", "Research one lead", "Write 200 words", "Outline one idea", "Do one thing you've been avoiding", "Update one key metric"],
    subArenas: {
      "DEEP WORK": ["Work on a side project for 25 min", "Write 200 words", "Outline one idea", "Build one thing, start to finish"],
      "ADMIN": ["Send one important email", "Update one key metric", "Clear your inbox", "Do one thing you've been avoiding"],
      "BUILD": ["Research one lead", "Sketch a system or process", "Define the next milestone", "Learn one thing relevant to your craft"],
    },
  },
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

// ── APP SHORTCUTS ──────────────────────────────────────────────────────────────
const APP_SHORTCUTS = [
  {
    id: "spotify", label: "Spotify", color: "#1DB954",
    url: "spotify://", fallback: "https://open.spotify.com",
    svg: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm4.586 14.424a.622.622 0 01-.857.207c-2.348-1.435-5.304-1.76-8.785-.964a.622.622 0 11-.277-1.215c3.809-.87 7.076-.496 9.712 1.115.294.181.387.563.207.857zm1.223-2.722a.78.78 0 01-1.072.257c-2.687-1.652-6.785-2.131-9.965-1.166a.78.78 0 01-.977-.519.781.781 0 01.52-.978c3.632-1.102 8.147-.568 11.237 1.329a.78.78 0 01.257 1.077zm.105-2.835C14.692 8.95 9.375 8.775 6.297 9.71a.937.937 0 11-.543-1.794c3.527-1.070 9.398-.863 13.105 1.338a.937.937 0 11-.945 1.613z"/></svg>`,
  },
  {
    id: "audible", label: "Audible", color: "#F47920",
    url: "audible://", fallback: "https://www.audible.com",
    svg: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.486 2 2 6.486 2 12s4.486 10 10 10 10-4.486 10-10S17.514 2 12 2zm0 3c1.322 0 2.578.322 3.686.893L14.4 7.179A6.5 6.5 0 1018.5 12h1.5a8 8 0 11-8-7zm0 3a5 5 0 100 10A5 5 0 0012 8zm0 2a3 3 0 110 6 3 3 0 010-6z"/></svg>`,
  },
  {
    id: "health", label: "Health", color: "#FF2D55",
    url: "x-apple-health://", fallback: "https://www.apple.com/ios/health/",
    svg: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 21.593c-.524-.547-8.293-8.148-8.293-13.093C3.707 4.9 7.607 2 12 2s8.293 2.9 8.293 6.5c0 4.945-7.769 12.546-8.293 13.093z"/></svg>`,
  },
  {
    id: "youtube", label: "YouTube", color: "#FF0000",
    url: "youtube://", fallback: "https://youtube.com",
    svg: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M23.495 6.205a3.007 3.007 0 00-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 00.527 6.205a31.247 31.247 0 00-.522 5.805 31.247 31.247 0 00.522 5.783 3.007 3.007 0 002.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 002.088-2.088 31.247 31.247 0 00.5-5.783 31.247 31.247 0 00-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"/></svg>`,
  },
  {
    id: "notes", label: "Notes", color: "#FFD60A",
    url: "mobilenotes://", fallback: "https://icloud.com/notes",
    svg: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M20 2H4c-1.103 0-2 .897-2 2v18l4-4h14c1.103 0 2-.897 2-2V4c0-1.103-.897-2-2-2zM7 9h10v2H7V9zm7 4H7v-2h7v2z"/></svg>`,
  },
  {
    id: "calendar", label: "Calendar", color: "#1C7ED6",
    url: "calshow://", fallback: "https://calendar.google.com",
    svg: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M19 4h-1V2h-2v2H8V2H6v2H5c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h14c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2zm0 16H5V8h14v12z"/><path d="M7 10h5v5H7z"/></svg>`,
  },
];

const launchApp = (app) => {
  const a = document.createElement('a'); a.href = app.url;
  try { a.click(); setTimeout(() => { window.open(app.fallback, '_blank'); }, 1200); }
  catch { window.open(app.fallback, '_blank'); }
};

// ── PROTOCOLS ──────────────────────────────────────────────────────────────────
const DEFAULT_PROTOCOLS = [
  {
    id: "warrior",   name: "THE WARRIOR",   glyph: "⚔",  color: "#C0392B",
    description: "Body first. Then the work. No excuses.",
    blocks: [{ arenaId: "body", label: "BODY", duration: 20, color: "#C0392B" }, { arenaId: "craft", label: "CRAFT", duration: 25, color: "#708090" }],
  },
  {
    id: "monk",      name: "THE MONK",      glyph: "☽",  color: "#D4A017",
    description: "Silence and study. Turn inward, then outward.",
    blocks: [{ arenaId: "spirit", label: "SPIRIT", duration: 15, color: "#D4A017" }, { arenaId: "tribe", label: "TRIBE", duration: 10, color: "#B87333" }],
  },
  {
    id: "builder",   name: "THE BUILDER",   glyph: "◈",  color: "#708090",
    description: "Pure output. Build something that lasts.",
    blocks: [{ arenaId: "craft", label: "CRAFT", duration: 25, color: "#708090" }, { arenaId: "craft", label: "CRAFT", duration: 25, color: "#708090" }],
  },
  {
    id: "ember",     name: "THE EMBER",     glyph: "◉",  color: "#B87333",
    description: "A gentle day. Move, connect, rest.",
    blocks: [{ arenaId: "body", label: "BODY", duration: 10, color: "#C0392B" }, { arenaId: "tribe", label: "TRIBE", duration: 10, color: "#B87333" }, { arenaId: "spirit", label: "SPIRIT", duration: 10, color: "#D4A017" }],
  },
];

// ── FORGE REWARD SYSTEM ────────────────────────────────────────────────────────
// Milestone thresholds are intentionally non-round — feels discovered not scheduled
const FORGE_MILESTONES = [3, 7, 13, 21, 33, 50, 77, 111];
const FORGE_MARKS = ["▪","▸","◆","★","⬟","✦","❋","⟡"];
const FORGE_MARK_NAMES = ["First Blood","Kindled","Forged","Tempered","Hardened","Undying","Mythic","Eternal"];

const TITLES = [
  { id: "the_moving",   label: "THE MOVING",   condition: (s) => s.filter(x => x.arenaId === "body").length >= 7,    arenaId: "body"   },
  { id: "the_burning",  label: "THE BURNING",  condition: (s) => s.filter(x => x.arenaId === "body").length >= 20,   arenaId: "body"   },
  { id: "the_witness",  label: "THE WITNESS",  condition: (s) => s.filter(x => x.arenaId === "tribe").length >= 5,   arenaId: "tribe"  },
  { id: "the_builder",  label: "THE BUILDER",  condition: (s) => s.filter(x => x.arenaId === "craft").length >= 10,  arenaId: "craft"  },
  { id: "the_seeker",   label: "THE SEEKER",   condition: (s) => s.filter(x => x.arenaId === "spirit").length >= 7,  arenaId: "spirit" },
  { id: "the_returned", label: "THE RETURNED", condition: (s) => { const dates = [...new Set(s.map(x=>x.date))]; return dates.length >= 3; }, arenaId: null },
  { id: "the_forge",    label: "THE FORGE",    condition: (s) => { const arenas = new Set(s.map(x=>x.arenaId)); return arenas.size >= 4; }, arenaId: null },
  { id: "the_unbroken", label: "THE UNBROKEN", condition: (s) => { let streak=0,check=todayStr(); for(let i=0;i<365;i++){const d=new Date(check);d.setDate(d.getDate()-i);const ds=d.toISOString().split('T')[0];if(s.some(x=>x.date===ds))streak++;else break;} return streak>=7; }, arenaId: null },
];

const EMBER_DROPS = [
  { id: "drop_1",  trigger: (s) => s.length >= 1,  message: "The first step is always the hardest. You took it.",       glyph: "▸" },
  { id: "drop_5",  trigger: (s) => s.length >= 5,  message: "Five sessions. The forge is warming.",                      glyph: "◆" },
  { id: "drop_13", trigger: (s) => s.length >= 13, message: "Thirteen. An odd number. That's the point. Keep going.",    glyph: "★" },
  { id: "drop_3arena", trigger: (s) => { const today = todayStr(); return new Set(s.filter(x=>x.date===today).map(x=>x.arenaId)).size >= 3; }, message: "Three arenas in one day. You showed up everywhere.", glyph: "✦" },
  { id: "drop_week", trigger: (s) => { const dates = new Set(s.map(x=>x.date)); let streak=0; for(let i=0;i<7;i++){const d=new Date();d.setDate(d.getDate()-i);if(dates.has(d.toISOString().split('T')[0]))streak++; else break;} return streak>=7; }, message: "Seven consecutive days. Depression told you this was impossible.", glyph: "⬟" },
];

const getForgeMarkForArena = (arenaId, sessions) => {
  const count = sessions.filter(s => s.arenaId === arenaId).length;
  let markIdx = -1;
  for (let i = FORGE_MILESTONES.length - 1; i >= 0; i--) {
    if (count >= FORGE_MILESTONES[i]) { markIdx = i; break; }
  }
  return markIdx >= 0 ? { mark: FORGE_MARKS[markIdx], name: FORGE_MARK_NAMES[markIdx], count } : null;
};

const getUnlockedTitles = (sessions) => TITLES.filter(t => t.condition(sessions));
const getActiveTitle = (sessions) => { const t = getUnlockedTitles(sessions); return t.length > 0 ? t[t.length - 1] : null; };

const checkEmberDrop = (sessions, seenDrops) => {
  for (const drop of EMBER_DROPS) {
    if (!seenDrops.includes(drop.id) && drop.trigger(sessions)) return drop;
  }
  return null;
};

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
const loadProtocols = () => load('arena_protocols', DEFAULT_PROTOCOLS);
const loadSeenDrops = () => load('arena_seen_drops', []);

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

// ── ARENA CARD MATERIAL STYLES ─────────────────────────────────────────────────
const ARENA_MATERIAL = {
  body: {
    bg: "radial-gradient(ellipse at 60% 30%, #1a0a08 0%, #0d0505 100%)",
    border: "1px solid rgba(192,57,43,0.18)",
    hoverBg: "radial-gradient(ellipse at 60% 30%, #220d0a 0%, #110707 100%)",
    hoverBorder: `1px solid rgba(192,57,43,0.45)`,
    hoverShadow: `0 4px 24px rgba(192,57,43,0.22), inset 0 0 0 1px rgba(192,57,43,0.15), 0 0 8px rgba(192,57,43,0.1)`,
  },
  spirit: {
    bg: "radial-gradient(ellipse at 60% 30%, #1a1408 0%, #0d0b06 100%)",
    border: "1px solid rgba(212,160,23,0.18)",
    hoverBg: "radial-gradient(ellipse at 60% 30%, #211a09 0%, #120e07 100%)",
    hoverBorder: `1px solid rgba(212,160,23,0.45)`,
    hoverShadow: `0 4px 24px rgba(212,160,23,0.2), inset 0 0 0 1px rgba(212,160,23,0.12), 0 0 8px rgba(212,160,23,0.08)`,
  },
  tribe: {
    bg: "radial-gradient(ellipse at 40% 70%, #150f09 0%, #0e0a07 100%)",
    border: "1px solid rgba(184,115,51,0.18)",
    hoverBg: "radial-gradient(ellipse at 40% 70%, #1c140b 0%, #120d08 100%)",
    hoverBorder: `1px solid rgba(184,115,51,0.45)`,
    hoverShadow: `0 4px 24px rgba(184,115,51,0.2), inset 0 1px 0 rgba(184,115,51,0.12), 0 0 8px rgba(184,115,51,0.08)`,
  },
  craft: {
    bg: "radial-gradient(ellipse at 50% 50%, #141416 0%, #0a0a0c 100%)",
    border: "1px solid rgba(112,128,144,0.18)",
    hoverBg: "radial-gradient(ellipse at 50% 50%, #18191c 0%, #0d0d10 100%)",
    hoverBorder: `1px solid rgba(112,128,144,0.4)`,
    hoverShadow: `0 4px 24px rgba(112,128,144,0.15), inset 0 0 0 1px rgba(112,128,144,0.1), 0 -1px 0 rgba(112,128,144,0.2)`,
  },
};

const getArenaStyle = (arenaId) => ARENA_MATERIAL[arenaId] || {
  bg: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)",
  hoverBg: "rgba(255,255,255,0.06)", hoverBorder: "1px solid rgba(255,255,255,0.15)",
  hoverShadow: "0 6px 20px rgba(255,255,255,0.05)",
};

// ── ARENA ILLUSTRATIONS (SVG watermarks) ──────────────────────────────────────
const ARENA_SVG = {
  body: (color) => (
    <svg viewBox="0 0 120 140" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ width: "100%", height: "100%" }}>
      {/* Abstract human torso/silhouette — shoulders, neck, chest, strong posture */}
      <defs>
        <radialGradient id="bodyGrad" cx="50%" cy="40%" r="60%">
          <stop offset="0%" stopColor={color} stopOpacity="0.28"/>
          <stop offset="100%" stopColor={color} stopOpacity="0"/>
        </radialGradient>
      </defs>
      {/* Torso shape */}
      <path d="M60 8 C60 8 52 10 48 16 C44 22 43 30 43 36 C43 42 44 46 44 46 L38 50 C30 54 22 62 20 72 C18 80 20 90 20 98 L20 132 L44 132 L44 108 C44 104 46 100 50 98 C54 96 60 95 60 95 C60 95 66 96 70 98 C74 100 76 104 76 108 L76 132 L100 132 L100 98 C100 90 102 80 100 72 C98 62 90 54 82 50 L76 46 C76 46 77 42 77 36 C77 30 76 22 72 16 C68 10 60 8 60 8 Z" fill={`url(#bodyGrad)`} stroke={color} strokeWidth="0.8" strokeOpacity="0.35"/>
      {/* Neck */}
      <path d="M54 8 C54 8 55 4 60 3 C65 4 66 8 66 8 L66 18 L54 18 Z" fill={color} fillOpacity="0.12" stroke={color} strokeWidth="0.6" strokeOpacity="0.2"/>
      {/* Shoulder lines — strength detail */}
      <path d="M44 46 C36 44 28 46 22 52" stroke={color} strokeWidth="1" strokeOpacity="0.25" strokeLinecap="round"/>
      <path d="M76 46 C84 44 92 46 98 52" stroke={color} strokeWidth="1" strokeOpacity="0.25" strokeLinecap="round"/>
      {/* Spine line */}
      <line x1="60" y1="46" x2="60" y2="95" stroke={color} strokeWidth="0.7" strokeOpacity="0.2" strokeDasharray="2 3"/>
      {/* Chest center mark */}
      <circle cx="60" cy="58" r="3" fill={color} fillOpacity="0.15" stroke={color} strokeWidth="0.8" strokeOpacity="0.3"/>
    </svg>
  ),

  spirit: (color) => (
    <svg viewBox="0 0 120 140" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ width: "100%", height: "100%" }}>
      {/* Upright flame — tall, tapering, alive */}
      <defs>
        <radialGradient id="spiritGrad" cx="50%" cy="70%" r="55%">
          <stop offset="0%" stopColor={color} stopOpacity="0.32"/>
          <stop offset="100%" stopColor={color} stopOpacity="0"/>
        </radialGradient>
        <radialGradient id="spiritCore" cx="50%" cy="60%" r="30%">
          <stop offset="0%" stopColor={color} stopOpacity="0.5"/>
          <stop offset="100%" stopColor={color} stopOpacity="0"/>
        </radialGradient>
      </defs>
      {/* Outer flame body */}
      <path d="M60 12 C60 12 46 28 42 46 C38 62 40 72 44 80 C48 88 54 92 60 92 C66 92 72 88 76 80 C80 72 82 62 78 46 C74 28 60 12 60 12 Z" fill="url(#spiritGrad)" stroke={color} strokeWidth="0.7" strokeOpacity="0.3"/>
      {/* Inner flame — narrower, brighter core */}
      <path d="M60 28 C60 28 52 42 50 54 C48 64 50 72 54 78 C56 82 60 84 60 84 C60 84 64 82 66 78 C70 72 72 64 70 54 C68 42 60 28 60 28 Z" fill="url(#spiritCore)" stroke={color} strokeWidth="0.5" strokeOpacity="0.4"/>
      {/* Flame tip wisp */}
      <path d="M60 12 C62 6 63 2 60 0 C57 2 58 6 60 12 Z" fill={color} fillOpacity="0.2"/>
      {/* Heat shimmer lines */}
      <path d="M48 100 C50 108 54 118 54 128" stroke={color} strokeWidth="0.8" strokeOpacity="0.15" strokeLinecap="round"/>
      <path d="M60 94 L60 132" stroke={color} strokeWidth="0.8" strokeOpacity="0.18" strokeLinecap="round"/>
      <path d="M72 100 C70 108 66 118 66 128" stroke={color} strokeWidth="0.8" strokeOpacity="0.15" strokeLinecap="round"/>
      {/* Base glow pool */}
      <ellipse cx="60" cy="128" rx="22" ry="5" fill={color} fillOpacity="0.1"/>
    </svg>
  ),

  tribe: (color) => (
    <svg viewBox="0 0 120 140" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ width: "100%", height: "100%" }}>
      {/* Two hands reaching toward each other — nearly touching, Sistine-chapel energy */}
      <defs>
        <radialGradient id="tribeGrad" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor={color} stopOpacity="0.25"/>
          <stop offset="100%" stopColor={color} stopOpacity="0"/>
        </radialGradient>
      </defs>
      {/* Left hand — reaching right */}
      <g opacity="0.9">
        {/* Palm */}
        <path d="M8 72 C8 68 10 64 14 63 C18 62 22 64 24 68 L24 80 C24 84 22 88 18 89 C14 90 10 88 8 84 Z" fill={color} fillOpacity="0.12" stroke={color} strokeWidth="0.8" strokeOpacity="0.35"/>
        {/* Index finger */}
        <path d="M24 68 L24 58 C24 54 26 52 28 52 C30 52 32 54 32 58 L32 72" stroke={color} strokeWidth="1.2" strokeOpacity="0.38" strokeLinecap="round" fill="none"/>
        {/* Middle finger */}
        <path d="M26 70 L28 54 C28 50 30 48 32 48 C34 48 36 50 36 54 L36 70" stroke={color} strokeWidth="1.2" strokeOpacity="0.33" strokeLinecap="round" fill="none"/>
        {/* Ring finger */}
        <path d="M28 72 L32 58 C32 54 34 52 36 52 C38 52 40 54 40 58 L40 72" stroke={color} strokeWidth="1.1" strokeOpacity="0.28" strokeLinecap="round" fill="none"/>
        {/* Pinky */}
        <path d="M30 75 L34 64 C34 61 36 59 38 60 C40 61 41 63 40 66 L38 76" stroke={color} strokeWidth="1" strokeOpacity="0.22" strokeLinecap="round" fill="none"/>
        {/* Thumb */}
        <path d="M8 78 C6 74 6 68 10 66 C12 65 15 66 16 68" stroke={color} strokeWidth="1.2" strokeOpacity="0.3" strokeLinecap="round" fill="none"/>
      </g>
      {/* Right hand — reaching left, mirrored */}
      <g opacity="0.9">
        <path d="M112 72 C112 68 110 64 106 63 C102 62 98 64 96 68 L96 80 C96 84 98 88 102 89 C106 90 110 88 112 84 Z" fill={color} fillOpacity="0.12" stroke={color} strokeWidth="0.8" strokeOpacity="0.35"/>
        <path d="M96 68 L96 58 C96 54 94 52 92 52 C90 52 88 54 88 58 L88 72" stroke={color} strokeWidth="1.2" strokeOpacity="0.38" strokeLinecap="round" fill="none"/>
        <path d="M94 70 L92 54 C92 50 90 48 88 48 C86 48 84 50 84 54 L84 70" stroke={color} strokeWidth="1.2" strokeOpacity="0.33" strokeLinecap="round" fill="none"/>
        <path d="M92 72 L88 58 C88 54 86 52 84 52 C82 52 80 54 80 58 L80 72" stroke={color} strokeWidth="1.1" strokeOpacity="0.28" strokeLinecap="round" fill="none"/>
        <path d="M90 75 L86 64 C86 61 84 59 82 60 C80 61 79 63 80 66 L82 76" stroke={color} strokeWidth="1" strokeOpacity="0.22" strokeLinecap="round" fill="none"/>
        <path d="M112 78 C114 74 114 68 110 66 C108 65 105 66 104 68" stroke={color} strokeWidth="1.2" strokeOpacity="0.3" strokeLinecap="round" fill="none"/>
      </g>
      {/* The gap — sacred space between fingertips */}
      <ellipse cx="60" cy="60" rx="8" ry="8" fill="url(#tribeGrad)"/>
      {/* Faint connection light between tips */}
      <line x1="40" y1="56" x2="80" y2="56" stroke={color} strokeWidth="0.5" strokeOpacity="0.15" strokeDasharray="1 4"/>
      {/* Wrist/arm suggestion */}
      <path d="M8 84 L2 110 C2 118 6 126 10 128 L18 130" stroke={color} strokeWidth="1" strokeOpacity="0.15" strokeLinecap="round" fill="none"/>
      <path d="M112 84 L118 110 C118 118 114 126 110 128 L102 130" stroke={color} strokeWidth="1" strokeOpacity="0.15" strokeLinecap="round" fill="none"/>
    </svg>
  ),

  craft: (color) => (
    <svg viewBox="0 0 120 140" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ width: "100%", height: "100%" }}>
      {/* Anvil + raised hammer — weight, work, the mark */}
      <defs>
        <radialGradient id="craftGrad" cx="50%" cy="55%" r="55%">
          <stop offset="0%" stopColor={color} stopOpacity="0.22"/>
          <stop offset="100%" stopColor={color} stopOpacity="0"/>
        </radialGradient>
      </defs>
      {/* Hammer handle */}
      <path d="M82 10 C84 8 87 8 89 10 L94 22 C96 24 96 27 94 29 L76 46 C74 48 71 48 69 46 L64 40 C62 38 62 35 64 33 Z" fill={color} fillOpacity="0.18" stroke={color} strokeWidth="0.9" strokeOpacity="0.45"/>
      {/* Hammer head — heavy block */}
      <rect x="60" y="28" width="26" height="16" rx="2" transform="rotate(-45 60 28)" fill={color} fillOpacity="0.22" stroke={color} strokeWidth="1" strokeOpacity="0.45"/>
      {/* Handle shaft */}
      <path d="M69 46 L38 92" stroke={color} strokeWidth="4" strokeOpacity="0.3" strokeLinecap="round"/>
      {/* Anvil body */}
      <path d="M22 98 L98 98 L98 94 C98 90 96 86 90 84 L76 82 L76 76 C76 72 72 70 68 70 L52 70 C48 70 44 72 44 76 L44 82 L30 84 C24 86 22 90 22 94 Z" fill={color} fillOpacity="0.16" stroke={color} strokeWidth="0.9" strokeOpacity="0.4"/>
      {/* Anvil horn */}
      <path d="M22 94 L12 90 C10 88 10 86 12 85 L22 84" fill={color} fillOpacity="0.12" stroke={color} strokeWidth="0.8" strokeOpacity="0.3"/>
      {/* Anvil base */}
      <rect x="28" y="98" width="64" height="8" rx="2" fill={color} fillOpacity="0.14" stroke={color} strokeWidth="0.8" strokeOpacity="0.3"/>
      <rect x="34" y="106" width="52" height="6" rx="2" fill={color} fillOpacity="0.1" stroke={color} strokeWidth="0.7" strokeOpacity="0.25"/>
      {/* Impact sparks from hammer strike */}
      <circle cx="70" cy="74" r="1.5" fill={color} fillOpacity="0.5"/>
      <path d="M70 74 L76 66" stroke={color} strokeWidth="0.8" strokeOpacity="0.4" strokeLinecap="round"/>
      <path d="M70 74 L78 72" stroke={color} strokeWidth="0.8" strokeOpacity="0.35" strokeLinecap="round"/>
      <path d="M70 74 L74 82" stroke={color} strokeWidth="0.7" strokeOpacity="0.25" strokeLinecap="round"/>
      {/* Glow pool */}
      <ellipse cx="60" cy="116" rx="30" ry="5" fill="url(#craftGrad)"/>
    </svg>
  ),
};

const getArenaSVG = (arenaId, color) => ARENA_SVG[arenaId] ? ARENA_SVG[arenaId](color) : null;

// ── ARENA CARD ─────────────────────────────────────────────────────────────────
function ArenaCard({ arena, sessCount, streak, i, onClick, editMode, onEdit, sessions = [] }) {
  const mat = getArenaStyle(arena.id);
  const forge = getForgeMarkForArena(arena.id, sessions);
  const illustration = getArenaSVG(arena.id, arena.color);
  return (
    <div style={{ position: "relative", animation: `fadeUp 0.5s ease ${i * 0.07}s both`, width: "100%" }}>
      <button onClick={editMode ? onEdit : onClick} style={{
        background: mat.bg, border: editMode ? `1px solid ${arena.color}40` : mat.border,
        borderRadius: 14, padding: "16px 12px 14px", cursor: "pointer", textAlign: "left",
        position: "relative", overflow: "hidden", transition: "all 0.25s ease", width: "100%",
        minHeight: 110,
      }}
        onPointerEnter={e => { if (!editMode) { e.currentTarget.style.background = mat.hoverBg; e.currentTarget.style.border = mat.hoverBorder; e.currentTarget.style.transform = "translateY(-2px)"; e.currentTarget.style.boxShadow = mat.hoverShadow; } }}
        onPointerLeave={e => { if (!editMode) { e.currentTarget.style.background = mat.bg; e.currentTarget.style.border = mat.border; e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "none"; } }}
      >
        {/* Top accent bar */}
        <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 2, background: arena.color, borderRadius: "14px 14px 0 0", opacity: 0.85 }} />

        {/* SVG illustration — faded watermark, bottom-right anchored */}
        {illustration && (
          <div style={{
            position: "absolute", bottom: -8, right: -8,
            width: 90, height: 105,
            opacity: 0.13,
            pointerEvents: "none",
            mixBlendMode: "screen",
            filter: `drop-shadow(0 0 8px ${arena.color}40)`,
          }}>
            {illustration}
          </div>
        )}

        {/* Content layer */}
        <div style={{ position: "relative", zIndex: 1 }}>
          <div style={{ fontSize: 9, color: "rgba(255,255,255,0.2)", letterSpacing: 3, marginBottom: 10 }}>{arena.letter}</div>
          <div style={{ fontSize: 11, fontWeight: "bold", letterSpacing: 3, color: "#E8E8E8", marginBottom: 2 }}>{arena.label}</div>
          {streak > 1 && !editMode && (
            <div style={{ fontSize: 8, color: arena.color, letterSpacing: 1, opacity: 0.8 }}>🔥 {streak}d streak</div>
          )}
        </div>

        {/* Forge mark */}
        {forge && <div style={{ position: "absolute", bottom: 8, left: 10, fontSize: 10, color: arena.color, filter: `drop-shadow(0 0 4px ${arena.color})`, opacity: 0.9, zIndex: 2 }} title={forge.name}>{forge.mark}</div>}
        {!editMode && sessCount > 0 && streak <= 1 && !forge && <div style={{ position: "absolute", top: 10, right: 10, fontSize: 8, color: arena.color, zIndex: 2 }}>●{sessCount}</div>}
        {editMode && <div style={{ position: "absolute", top: 8, right: 8, fontSize: 12, color: arena.color, opacity: 0.7, zIndex: 2 }}>✎</div>}
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
      <button onClick={() => onComplete(checkin.completed.length)} style={{ width: "100%", padding: "17px", background: allDone ? "#E8C547" : "rgba(255,255,255,0.04)", border: allDone ? "none" : "1px solid rgba(255,255,255,0.1)", borderRadius: 14, color: allDone ? "#080810" : "rgba(255,255,255,0.4)", fontSize: 13, fontWeight: allDone ? "bold" : "normal", letterSpacing: 5, cursor: "pointer", fontFamily: "'Courier New', monospace", transition: "all 0.3s ease", boxShadow: allDone ? "0 0 24px rgba(232,197,71,0.3)" : "none", marginBottom: 20 }}>
        {allDone ? "ENTER THE ARENA →" : "CONTINUE →"}
      </button>
      <AppShortcutsBar />
      <button onClick={onSkip} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.18)", cursor: "pointer", fontSize: 9, letterSpacing: 3, fontFamily: "'Courier New', monospace", marginTop: 12 }}>SKIP MORNING PROTOCOL</button>
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
function HistoryScreen({ onBack, sessions, arenas, onExportCSV, onExportJSON }) {
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

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10, marginBottom: 14 }}>
        {[{ label: "SESSIONS", value: totalSessions }, { label: "MINUTES", value: totalMinutes }, { label: "DAYS", value: activeDays }].map(stat => (
          <div key={stat.label} style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 12, padding: "14px 10px", textAlign: "center" }}>
            <div style={{ fontSize: 22, fontWeight: "bold", color: "#E8E8E8", marginBottom: 4 }}>{stat.value}</div>
            <div style={{ fontSize: 8, letterSpacing: 3, color: "rgba(255,255,255,0.25)" }}>{stat.label}</div>
          </div>
        ))}
      </div>

      {/* Export buttons */}
      <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
        <button onClick={onExportCSV} style={{ flex: 1, padding: "10px 8px", background: "rgba(76,205,196,0.06)", border: "1px solid rgba(76,205,196,0.2)", borderRadius: 10, color: "#4ECDC4", fontSize: 9, letterSpacing: 2, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>↓ CSV</button>
        <button onClick={onExportJSON} style={{ flex: 1, padding: "10px 8px", background: "rgba(183,148,244,0.06)", border: "1px solid rgba(183,148,244,0.2)", borderRadius: 10, color: "#B794F4", fontSize: 9, letterSpacing: 2, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>↓ JSON</button>
        <div style={{ flex: 2, padding: "10px 8px", background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <span style={{ fontSize: 8, color: "rgba(255,255,255,0.2)", letterSpacing: 1 }}>NOTION · OBSIDIAN · SHEETS</span>
        </div>
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

// ── APP SHORTCUTS BAR ──────────────────────────────────────────────────────────
function AppShortcutsBar() {
  return (
    <div style={{ padding: "10px 16px 8px", display: "flex", gap: 6, justifyContent: "center", alignItems: "center" }}>
      {APP_SHORTCUTS.map(app => (
        <button
          key={app.id}
          onClick={() => launchApp(app)}
          title={app.label}
          style={{
            flex: 1, maxWidth: 50, aspectRatio: "1",
            background: `${app.color}10`,
            border: `1px solid ${app.color}25`,
            borderRadius: 14, cursor: "pointer",
            display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
            gap: 3, transition: "all 0.18s ease", padding: "6px 2px 4px",
          }}
          onPointerEnter={e => { e.currentTarget.style.background = `${app.color}22`; e.currentTarget.style.border = `1px solid ${app.color}55`; e.currentTarget.style.transform = "translateY(-2px)"; e.currentTarget.style.boxShadow = `0 4px 12px ${app.color}20`; }}
          onPointerLeave={e => { e.currentTarget.style.background = `${app.color}10`; e.currentTarget.style.border = `1px solid ${app.color}25`; e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "none"; }}
        >
          <span
            style={{ width: 18, height: 18, color: app.color, display: "flex", alignItems: "center", justifyContent: "center", filter: `drop-shadow(0 0 4px ${app.color}50)` }}
            dangerouslySetInnerHTML={{ __html: app.svg.replace('currentColor', app.color) }}
          />
          <span style={{ fontSize: 6, letterSpacing: 0.5, color: `${app.color}80`, fontFamily: "'Courier New', monospace", lineHeight: 1 }}>{app.label.slice(0, 6).toUpperCase()}</span>
        </button>
      ))}
    </div>
  );
}

// ── EMBER DROP MODAL ───────────────────────────────────────────────────────────
function EmberDropModal({ drop, onDismiss }) {
  if (!drop) return null;
  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.85)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 999, padding: 24 }} onClick={onDismiss}>
      <div style={{ background: "linear-gradient(160deg, #0f0d0a, #080810)", border: "1px solid rgba(232,197,71,0.3)", borderRadius: 24, padding: "40px 28px", textAlign: "center", maxWidth: 320, animation: "pop 0.4s ease", boxShadow: "0 0 60px rgba(232,197,71,0.12)" }}>
        <div style={{ fontSize: 64, color: "#E8C547", filter: "drop-shadow(0 0 24px rgba(232,197,71,0.5))", marginBottom: 16, animation: "pop 0.5s ease 0.1s both" }}>{drop.glyph}</div>
        <div style={{ fontSize: 9, letterSpacing: 6, color: "rgba(232,197,71,0.6)", marginBottom: 10 }}>EMBER DROP</div>
        <div style={{ fontSize: 14, color: "rgba(255,255,255,0.85)", lineHeight: 1.7, marginBottom: 28, fontStyle: "italic" }}>{drop.message}</div>
        <div style={{ fontSize: 9, letterSpacing: 3, color: "rgba(255,255,255,0.2)" }}>TAP TO CONTINUE</div>
      </div>
    </div>
  );
}

// ── FORGE MARK BADGE (on arena cards in history) ───────────────────────────────
function ForgeMarkBadge({ arenaId, sessions, color }) {
  const forge = getForgeMarkForArena(arenaId, sessions);
  if (!forge) return null;
  return (
    <span title={`${forge.name} — ${forge.count} sessions`} style={{ fontSize: 10, color, filter: `drop-shadow(0 0 4px ${color}80)`, marginLeft: 4 }}>{forge.mark}</span>
  );
}

// ── PROTOCOLS SCREEN ───────────────────────────────────────────────────────────
function ProtocolsScreen({ onBack, onStartProtocol, arenas }) {
  const [protocols, setProtocols] = useState(loadProtocols);
  const [editing, setEditing] = useState(null);
  const [editBlocks, setEditBlocks] = useState([]);
  const [editName, setEditName] = useState("");
  const [editDesc, setEditDesc] = useState("");

  const startEdit = (p) => {
    setEditing(p.id);
    setEditBlocks([...p.blocks]);
    setEditName(p.name);
    setEditDesc(p.description);
  };

  const saveEdit = () => {
    const updated = protocols.map(p => p.id === editing ? { ...p, name: editName, description: editDesc, blocks: editBlocks } : p);
    setProtocols(updated); save('arena_protocols', updated); setEditing(null);
  };

  const updateBlockDuration = (idx, dur) => {
    const b = [...editBlocks]; b[idx] = { ...b[idx], duration: Math.max(5, Math.min(120, parseInt(dur) || 5)) }; setEditBlocks(b);
  };

  const getTotalTime = (blocks) => blocks.reduce((s, b) => s + b.duration, 0);

  if (editing) {
    const p = protocols.find(x => x.id === editing);
    return (
      <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 22px 32px", overflowY: "auto" }}>
        <button onClick={() => setEditing(null)} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 28, textAlign: "left", padding: 0 }}>← BACK</button>
        <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>EDIT PROTOCOL</div>
        <div style={{ fontSize: 24, fontWeight: "bold", letterSpacing: 2, color: p.color, marginBottom: 24 }}>{editName}</div>
        <div style={{ marginBottom: 20 }}>
          <div style={labelStyle}>NAME</div>
          <input value={editName} onChange={e => setEditName(e.target.value.toUpperCase())} style={{ ...inputStyle, color: p.color, borderColor: p.color + '50', letterSpacing: 3 }} />
        </div>
        <div style={{ marginBottom: 20 }}>
          <div style={labelStyle}>DESCRIPTION</div>
          <input value={editDesc} onChange={e => setEditDesc(e.target.value)} style={{ ...inputStyle }} />
        </div>
        <div style={{ marginBottom: 24 }}>
          <div style={labelStyle}>BLOCKS — ADJUST DURATIONS</div>
          {editBlocks.map((block, idx) => (
            <div key={idx} style={{ display: "flex", alignItems: "center", gap: 10, padding: "12px 0", borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
              <div style={{ width: 8, height: 8, borderRadius: "50%", background: block.color, flexShrink: 0 }} />
              <div style={{ flex: 1, fontSize: 11, letterSpacing: 2, color: "#E8E8E8" }}>{block.label}</div>
              <input type="number" min="5" max="120" value={block.duration} onChange={e => updateBlockDuration(idx, e.target.value)}
                style={{ ...inputStyle, width: 60, textAlign: "center", padding: "8px", fontSize: 13, color: block.color, borderColor: block.color + '40' }} />
              <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)" }}>MIN</div>
            </div>
          ))}
        </div>
        <button onClick={saveEdit} style={{ ...primaryBtn(p.color) }}>SAVE PROTOCOL</button>
      </div>
    );
  }

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 22px 32px", overflowY: "auto" }}>
      <button onClick={onBack} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 28, textAlign: "left", padding: 0 }}>← BACK</button>
      <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>CHAIN YOUR ARENAS</div>
      <div style={{ fontSize: 26, fontWeight: "bold", letterSpacing: 2, marginBottom: 6 }}>PROTOCOLS</div>
      <div style={{ fontSize: 11, color: "rgba(255,255,255,0.3)", marginBottom: 28, lineHeight: 1.6 }}>Back-to-back arenas. One progress bar. One unbroken chain.</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        {protocols.map((p, pi) => {
          const total = getTotalTime(p.blocks);
          return (
            <div key={p.id} style={{ background: `${p.color}08`, border: `1px solid ${p.color}25`, borderRadius: 18, padding: "20px", animation: `fadeUp 0.4s ease ${pi * 0.08}s both` }}>
              <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 12 }}>
                <div>
                  <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
                    <span style={{ fontSize: 18, color: p.color, filter: `drop-shadow(0 0 6px ${p.color}60)` }}>{p.glyph}</span>
                    <span style={{ fontSize: 13, fontWeight: "bold", letterSpacing: 3, color: p.color }}>{p.name}</span>
                  </div>
                  <div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", lineHeight: 1.5 }}>{p.description}</div>
                </div>
                <button onClick={() => startEdit(p)} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.2)", cursor: "pointer", fontSize: 11, padding: "4px 8px", fontFamily: "'Courier New', monospace", letterSpacing: 1 }}>✎</button>
              </div>
              {/* Block strip */}
              <div style={{ display: "flex", gap: 4, marginBottom: 12 }}>
                {p.blocks.map((block, bi) => (
                  <div key={bi} style={{ flex: block.duration, height: 6, background: block.color, borderRadius: 3, opacity: 0.7 }} title={`${block.label} — ${block.duration}m`} />
                ))}
              </div>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                <div style={{ display: "flex", gap: 8 }}>
                  {p.blocks.map((block, bi) => (
                    <div key={bi} style={{ fontSize: 9, color: block.color, letterSpacing: 1, opacity: 0.8 }}>{block.label} {block.duration}m</div>
                  ))}
                </div>
                <div style={{ fontSize: 10, color: "rgba(255,255,255,0.3)", letterSpacing: 2 }}>{total}m total</div>
              </div>
              <button onClick={() => onStartProtocol(p)} style={{ marginTop: 14, width: "100%", padding: "13px", background: `${p.color}18`, border: `1px solid ${p.color}50`, borderRadius: 12, color: p.color, fontSize: 11, letterSpacing: 4, cursor: "pointer", fontFamily: "'Courier New', monospace", fontWeight: "bold" }}>
                BEGIN PROTOCOL →
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ── ACTIVE PROTOCOL SCREEN ─────────────────────────────────────────────────────
function ActiveProtocolScreen({ protocol, onComplete, onAbandon }) {
  const [blockIdx, setBlockIdx] = useState(0);
  const [timeLeft, setTimeLeft] = useState(protocol.blocks[0].duration * 60);
  const [isPaused, setIsPaused] = useState(false);
  const [isRunning, setIsRunning] = useState(true);
  const [completedBlocks, setCompletedBlocks] = useState([]);
  const intervalRef = useRef(null);
  const endTimeRef = useRef(Date.now() + protocol.blocks[0].duration * 60 * 1000);

  const currentBlock = protocol.blocks[blockIdx];
  const totalBlocks = protocol.blocks.length;
  const totalDuration = protocol.blocks.reduce((s, b) => s + b.duration, 0) * 60;
  const completedTime = completedBlocks.reduce((s, b) => s + b.duration * 60, 0);
  const overallProgress = (completedTime + (currentBlock.duration * 60 - timeLeft)) / totalDuration;
  const circumference = 2 * Math.PI * 90;
  const blockProgress = 1 - timeLeft / (currentBlock.duration * 60);

  useEffect(() => {
    if (isRunning && !isPaused) {
      intervalRef.current = setInterval(() => {
        const remaining = Math.round((endTimeRef.current - Date.now()) / 1000);
        if (remaining <= 0) {
          clearInterval(intervalRef.current);
          const nextIdx = blockIdx + 1;
          if (nextIdx < totalBlocks) {
            setCompletedBlocks(prev => [...prev, currentBlock]);
            setBlockIdx(nextIdx);
            setTimeLeft(protocol.blocks[nextIdx].duration * 60);
            endTimeRef.current = Date.now() + protocol.blocks[nextIdx].duration * 60 * 1000;
          } else {
            setIsRunning(false);
            onComplete([...completedBlocks, currentBlock]);
          }
        } else setTimeLeft(remaining);
      }, 1000);
    } else clearInterval(intervalRef.current);
    return () => clearInterval(intervalRef.current);
  }, [isRunning, isPaused, blockIdx]);

  const handlePause = () => {
    if (!isPaused) setIsPaused(true);
    else { endTimeRef.current = Date.now() + timeLeft * 1000; setIsPaused(false); }
  };

  const formatTime = (s) => `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", padding: "40px 24px 32px" }}>
      {/* Protocol name */}
      <div style={{ textAlign: "center", marginBottom: 20 }}>
        <div style={{ fontSize: 9, letterSpacing: 6, color: "rgba(255,255,255,0.22)", marginBottom: 4 }}>PROTOCOL</div>
        <div style={{ fontSize: 16, fontWeight: "bold", letterSpacing: 4, color: protocol.color }}>{protocol.name}</div>
      </div>

      {/* Overall progress bar with labeled segments */}
      <div style={{ width: "100%", marginBottom: 24 }}>
        <div style={{ position: "relative", height: 8, background: "rgba(255,255,255,0.06)", borderRadius: 4, overflow: "hidden" }}>
          {/* Segment divisions */}
          {protocol.blocks.map((block, bi) => {
            const segStart = protocol.blocks.slice(0, bi).reduce((s, b) => s + b.duration, 0) / (totalDuration / 60);
            const segWidth = block.duration / (totalDuration / 60);
            const segFilled = bi < blockIdx ? 1 : bi === blockIdx ? blockProgress : 0;
            return (
              <div key={bi} style={{ position: "absolute", top: 0, left: `${segStart * 100}%`, width: `${segWidth * 100}%`, height: "100%", background: block.color, transform: `scaleX(${segFilled})`, transformOrigin: "left", transition: "transform 1s linear", opacity: 0.85 }} />
            );
          })}
        </div>
        {/* Segment labels */}
        <div style={{ display: "flex", marginTop: 6 }}>
          {protocol.blocks.map((block, bi) => {
            const segWidth = block.duration / (totalDuration / 60);
            return (
              <div key={bi} style={{ flex: block.duration, textAlign: "center", fontSize: 7, letterSpacing: 1, color: bi === blockIdx ? block.color : bi < blockIdx ? `${block.color}60` : "rgba(255,255,255,0.2)", transition: "color 0.3s" }}>
                {bi < blockIdx ? "✓" : block.label}
              </div>
            );
          })}
        </div>
      </div>

      {/* Current block timer */}
      <div style={{ textAlign: "center", marginBottom: 8 }}>
        <div style={{ fontSize: 9, letterSpacing: 5, color: "rgba(255,255,255,0.22)" }}>{isPaused ? "PAUSED" : "NOW IN"}</div>
        <div style={{ fontSize: 18, fontWeight: "bold", letterSpacing: 4, color: currentBlock.color, marginTop: 2 }}>{currentBlock.label}</div>
        <div style={{ fontSize: 9, color: "rgba(255,255,255,0.25)", marginTop: 2 }}>BLOCK {blockIdx + 1} OF {totalBlocks}</div>
      </div>

      <div style={{ position: "relative", width: 200, height: 200, marginBottom: 24 }}>
        <svg width="200" height="200" style={{ transform: "rotate(-90deg)" }}>
          <circle cx="100" cy="100" r="90" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="5" />
          <circle cx="100" cy="100" r="90" fill="none" stroke={currentBlock.color} strokeWidth="5" strokeLinecap="round" strokeDasharray={circumference} strokeDashoffset={circumference * (1 - blockProgress)} style={{ transition: "stroke-dashoffset 1s linear", filter: `drop-shadow(0 0 8px ${currentBlock.color})` }} />
        </svg>
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
          <div style={{ fontSize: 42, fontWeight: "bold", letterSpacing: 2, color: currentBlock.color, fontVariantNumeric: "tabular-nums" }}>{formatTime(timeLeft)}</div>
          <div style={{ fontSize: 8, letterSpacing: 3, color: "rgba(255,255,255,0.2)", marginTop: 4 }}>REMAINING</div>
        </div>
      </div>

      <div style={{ display: "flex", gap: 10, width: "100%", marginBottom: 12 }}>
        <button onClick={handlePause} style={{ flex: 1, padding: "14px", background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: 12, color: "rgba(255,255,255,0.6)", fontSize: 10, letterSpacing: 4, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>{isPaused ? "RESUME" : "PAUSE"}</button>
        <button onClick={() => onComplete([...completedBlocks, { ...currentBlock, duration: Math.round((currentBlock.duration * 60 - timeLeft) / 60) }])} style={{ flex: 1, padding: "14px", background: `${currentBlock.color}18`, border: `1px solid ${currentBlock.color}`, borderRadius: 12, color: currentBlock.color, fontSize: 10, letterSpacing: 4, cursor: "pointer", fontFamily: "'Courier New', monospace" }}>DONE</button>
      </div>
      <button onClick={onAbandon} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.18)", cursor: "pointer", fontSize: 9, letterSpacing: 3 }}>ABANDON PROTOCOL</button>
    </div>
  );
}

// ── DATA EXPORT ────────────────────────────────────────────────────────────────
function exportCSV(sessions, arenas) {
  const rows = [["Date", "Arena", "Duration (min)", "Quest", "Timestamp"]];
  sessions.forEach(s => {
    const arena = arenas.find(a => a.id === s.arenaId);
    rows.push([s.date, arena?.label || s.arenaId, s.duration, s.note || "", new Date(s.ts).toISOString()]);
  });
  const csv = rows.map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(",")).join("\n");
  const blob = new Blob([csv], { type: "text/csv" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a"); a.href = url; a.download = `arena_sessions_${todayStr()}.csv`; a.click();
  URL.revokeObjectURL(url);
}

function exportJSON(sessions, arenas) {
  const data = {
    exported: new Date().toISOString(),
    platform: "Arena Protocol",
    sessions: sessions.map(s => ({ ...s, arenaLabel: arenas.find(a => a.id === s.arenaId)?.label || s.arenaId })),
    summary: {
      totalSessions: sessions.length,
      totalMinutes: sessions.reduce((s, x) => s + (x.duration || 0), 0),
      uniqueDays: new Set(sessions.map(s => s.date)).size,
      byArena: arenas.map(a => ({ id: a.id, label: a.label, sessions: sessions.filter(s => s.arenaId === a.id).length, minutes: sessions.filter(s => s.arenaId === a.id).reduce((acc, s) => acc + (s.duration || 0), 0) })),
    },
  };
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob); const a = document.createElement("a"); a.href = url; a.download = `arena_data_${todayStr()}.json`; a.click(); URL.revokeObjectURL(url);
}


function SelectScreen({ selectedArena, sessionNote, setSessionNote, selectedDuration, setSelectedDuration, isCustomActive, setIsCustomActive, customMinutes, setCustomMinutes, durationValid, startArena, onBack }) {
  const [activeSubArena, setActiveSubArena] = useState(null);
  const subArenas = selectedArena.subArenas || null;
  const subArenaKeys = subArenas ? Object.keys(subArenas) : [];
  const filteredExamples = activeSubArena && subArenas ? subArenas[activeSubArena] : null;

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "48px 24px 32px", overflowY: "auto" }}>
      <button onClick={onBack} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 36, textAlign: "left", padding: 0 }}>← BACK</button>

      {/* Arena header — with large illustration */}
      <div style={{ position: "relative", marginBottom: 24 }}>
        {/* Background illustration — large, centered, very faint */}
        {getArenaSVG(selectedArena.id, selectedArena.color) && (
          <div style={{
            position: "absolute", top: -20, right: -24,
            width: 160, height: 180,
            opacity: 0.07,
            pointerEvents: "none",
            mixBlendMode: "screen",
            filter: `drop-shadow(0 0 20px ${selectedArena.color}60)`,
          }}>
            {getArenaSVG(selectedArena.id, selectedArena.color)}
          </div>
        )}
        <div style={{ position: "relative", zIndex: 1 }}>
          <div style={{ fontSize: 10, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>ARENA {selectedArena.letter}</div>
          <div style={{ fontSize: 36, fontWeight: "bold", letterSpacing: 3, color: selectedArena.color, marginBottom: 10, filter: `drop-shadow(0 0 20px ${selectedArena.color}40)` }}>{selectedArena.label}</div>
          <div style={{ fontSize: 12, color: "rgba(255,255,255,0.45)", marginBottom: 0, lineHeight: 1.7 }}>{selectedArena.description}</div>
        </div>
      </div>

      {/* Quest field — PRIMARY moment */}
      <div style={{ marginBottom: 28 }}>
        <div style={{ fontSize: 9, letterSpacing: 5, color: selectedArena.color, marginBottom: 12, opacity: 0.8 }}>TODAY'S QUEST</div>
        <textarea
          value={sessionNote}
          onChange={e => setSessionNote(e.target.value)}
          placeholder="Name your quest for this arena..."
          rows={2}
          style={{
            ...inputStyle,
            resize: "none",
            lineHeight: 1.6,
            fontSize: sessionNote ? 15 : 13,
            color: sessionNote ? selectedArena.color : "rgba(255,255,255,0.35)",
            borderColor: sessionNote ? selectedArena.color + '60' : "rgba(255,255,255,0.1)",
            background: sessionNote ? `${selectedArena.color}0e` : "rgba(255,255,255,0.03)",
            transition: "all 0.2s ease",
            fontWeight: sessionNote ? "bold" : "normal",
            letterSpacing: sessionNote ? 1 : 0,
            boxShadow: sessionNote ? `0 0 16px ${selectedArena.color}18` : "none",
          }}
        />
        {sessionNote && (
          <div style={{ fontSize: 9, letterSpacing: 3, color: selectedArena.color, marginTop: 6, opacity: 0.6 }}>
            ▸ YOUR QUEST IS SET
          </div>
        )}
      </div>

      {/* Sub-arenas */}
      {subArenaKeys.length > 0 && (
        <div style={{ marginBottom: 20 }}>
          <div style={labelStyle}>FOCUS AREA</div>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 14 }}>
            {subArenaKeys.map(key => (
              <button
                key={key}
                onClick={() => setActiveSubArena(activeSubArena === key ? null : key)}
                style={{
                  padding: "8px 14px", borderRadius: 20, cursor: "pointer",
                  border: activeSubArena === key ? `1.5px solid ${selectedArena.color}` : "1px solid rgba(255,255,255,0.12)",
                  background: activeSubArena === key ? `${selectedArena.color}20` : "rgba(255,255,255,0.03)",
                  color: activeSubArena === key ? selectedArena.color : "rgba(255,255,255,0.45)",
                  fontSize: 9, letterSpacing: 3, fontFamily: "'Courier New', monospace",
                  transition: "all 0.18s ease",
                }}
              >{key}</button>
            ))}
          </div>

          {/* Example tasks for selected sub-arena */}
          {activeSubArena && filteredExamples && (
            <div style={{ display: "flex", flexDirection: "column", gap: 6, animation: "fadeUp 0.2s ease" }}>
              {filteredExamples.map((ex, i) => (
                <button
                  key={i}
                  onClick={() => setSessionNote(ex)}
                  style={{
                    textAlign: "left", padding: "10px 14px", borderRadius: 10, cursor: "pointer",
                    border: sessionNote === ex ? `1px solid ${selectedArena.color}60` : "1px solid rgba(255,255,255,0.06)",
                    background: sessionNote === ex ? `${selectedArena.color}15` : "rgba(255,255,255,0.02)",
                    color: sessionNote === ex ? selectedArena.color : "rgba(255,255,255,0.55)",
                    fontSize: 12, fontFamily: "'Courier New', monospace",
                    display: "flex", alignItems: "center", gap: 10,
                    transition: "all 0.15s ease",
                  }}
                >
                  <div style={{ width: 5, height: 5, borderRadius: "50%", background: selectedArena.color, flexShrink: 0, opacity: sessionNote === ex ? 1 : 0.4 }} />
                  {ex}
                </button>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Duration */}
      <div style={{ marginBottom: 24 }}>
        <div style={labelStyle}>BLOCK DURATION</div>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {DURATIONS.map(d => (
            <button key={d.value} onClick={() => { setSelectedDuration(d.value); setIsCustomActive(false); }} style={{ padding: "10px 12px", borderRadius: 10, flex: 1, border: !isCustomActive && selectedDuration === d.value ? `1.5px solid ${selectedArena.color}` : "1px solid rgba(255,255,255,0.1)", background: !isCustomActive && selectedDuration === d.value ? `${selectedArena.color}18` : "transparent", color: !isCustomActive && selectedDuration === d.value ? selectedArena.color : "rgba(255,255,255,0.4)", cursor: "pointer", fontSize: 11, letterSpacing: 2, fontFamily: "'Courier New', monospace" }}>{d.label}</button>
          ))}
          <button onClick={() => setIsCustomActive(true)} style={{ padding: "10px 12px", borderRadius: 10, flex: 1, border: isCustomActive ? `1.5px solid ${selectedArena.color}` : "1px solid rgba(255,255,255,0.1)", background: isCustomActive ? `${selectedArena.color}18` : "transparent", color: isCustomActive ? selectedArena.color : "rgba(255,255,255,0.4)", cursor: "pointer", fontSize: 11, letterSpacing: 2, fontFamily: "'Courier New', monospace" }}>other</button>
        </div>
        {isCustomActive && (
          <div style={{ marginTop: 10, display: "flex", alignItems: "center", gap: 10 }}>
            <input type="number" min="1" max="480" value={customMinutes} onChange={e => setCustomMinutes(e.target.value)} placeholder="min" autoFocus style={{ ...inputStyle, flex: 1, textAlign: "center", fontSize: 16, color: selectedArena.color, borderColor: selectedArena.color, background: `${selectedArena.color}10` }} />
            <div style={{ fontSize: 11, color: "rgba(255,255,255,0.35)", letterSpacing: 2 }}>MINUTES</div>
          </div>
        )}
      </div>

      {/* Launch */}
      <div>
        <div style={labelStyle}>ADD TO GOOGLE CALENDAR?</div>
        <div style={{ display: "flex", gap: 10 }}>
          <button onClick={() => durationValid && startArena(true)} style={{ flex: 1, padding: "16px", background: "transparent", border: `1px solid ${durationValid ? selectedArena.color : "rgba(255,255,255,0.1)"}`, borderRadius: 12, color: durationValid ? selectedArena.color : "rgba(255,255,255,0.2)", fontSize: 12, letterSpacing: 4, cursor: durationValid ? "pointer" : "not-allowed", fontFamily: "'Courier New', monospace" }}>YES</button>
          <button onClick={() => durationValid && startArena(false)} style={{ flex: 1, padding: "16px", background: "transparent", border: `1px solid ${durationValid ? "rgba(255,255,255,0.2)" : "rgba(255,255,255,0.07)"}`, borderRadius: 12, color: durationValid ? "rgba(255,255,255,0.55)" : "rgba(255,255,255,0.2)", fontSize: 12, letterSpacing: 4, cursor: durationValid ? "pointer" : "not-allowed", fontFamily: "'Courier New', monospace" }}>NO</button>
        </div>
        {!durationValid && <div style={{ fontSize: 9, color: "rgba(255,255,255,0.25)", letterSpacing: 2, marginTop: 10, textAlign: "center" }}>ENTER A DURATION FIRST</div>}
      </div>
    </div>
  );
}


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
  // Protocol state
  const [activeProtocol, setActiveProtocol] = useState(null);
  // Forge / reward state
  const [seenDrops, setSeenDrops] = useState(loadSeenDrops);
  const [pendingDrop, setPendingDrop] = useState(null);
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
    // Check for ember drop
    const drop = checkEmberDrop(updated, seenDrops);
    if (drop) {
      const newSeen = [...seenDrops, drop.id]; setSeenDrops(newSeen); save('arena_seen_drops', newSeen);
      setPendingDrop(drop);
    }
    resetSession();
  };

  const handleProtocolComplete = (blocks) => {
    const newSessions = blocks.map(b => ({ arenaId: b.arenaId, duration: b.duration, date: todayStr(), note: `Protocol: ${activeProtocol.name}`, ts: Date.now() }));
    const updated = [...sessions, ...newSessions]; setSessions(updated); save('arena_sessions', updated);
    const drop = checkEmberDrop(updated, seenDrops);
    if (drop) { const newSeen = [...seenDrops, drop.id]; setSeenDrops(newSeen); save('arena_seen_drops', newSeen); setPendingDrop(drop); }
    setActiveProtocol(null); setScreen("home");
  };

  const progress = totalTime ? 1 - timeLeft / totalTime : 0;
  const circumference = 2 * Math.PI * 90;

  const wrap = (children, glow = null) => (
    <div style={{ minHeight: "100vh", background: "#080810", fontFamily: "'Courier New', monospace", color: "#E8E8E8", display: "flex", flexDirection: "column", alignItems: "center", position: "relative", overflow: "hidden" }}>
      {/* Grain texture */}
      <div style={{ position: "fixed", inset: 0, pointerEvents: "none", zIndex: 2, opacity: 0.035, backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='1'/%3E%3C/svg%3E")`, backgroundSize: "200px 200px" }} />
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
  if (screen === "history") return wrap(<HistoryScreen onBack={() => setScreen("home")} sessions={sessions} arenas={letteredArenas} onExportCSV={() => exportCSV(sessions, letteredArenas)} onExportJSON={() => exportJSON(sessions, letteredArenas)} />);
  if (screen === "winddown") return wrap(<WindDownScreen onBack={() => setScreen("home")} onComplete={() => setScreen("home")} />);
  if (screen === "habits") return wrap(<HabitManager onBack={() => setScreen("home")} />);
  if (screen === "settings") return wrap(<SettingsScreen onBack={() => setScreen("home")} onNavigate={(s) => setScreen(s)} />);
  if (screen === "protocols") return wrap(<ProtocolsScreen onBack={() => setScreen("home")} arenas={letteredArenas} onStartProtocol={(p) => { setActiveProtocol(p); setScreen("activeProtocol"); }} />);
  if (screen === "activeProtocol" && activeProtocol) return wrap(<ActiveProtocolScreen protocol={activeProtocol} onComplete={handleProtocolComplete} onAbandon={() => { setActiveProtocol(null); setScreen("home"); }} />, activeProtocol.color + "22");
  if (screen === "arenaEditor") return wrap(<div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "52px 20px 32px" }}>
    <button onClick={() => setScreen("home")} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.35)", cursor: "pointer", fontSize: 10, letterSpacing: 4, marginBottom: 28, textAlign: "left", padding: 0 }}>← BACK</button>
    <div style={{ fontSize: 9, letterSpacing: 7, color: "rgba(255,255,255,0.25)", marginBottom: 4 }}>CUSTOMIZE</div>
    <div style={{ fontSize: 26, fontWeight: "bold", letterSpacing: 2, marginBottom: 20 }}>YOUR <span style={{ color: "#E8C547" }}>ARENAS</span></div>
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 9, flex: 1 }}>
      {letteredArenas.map((arena, i) => <ArenaCard key={arena.id} arena={arena} sessCount={0} streak={0} i={i} editMode onClick={() => {}} onEdit={() => setEditingArena(arena)} sessions={sessions} />)}
      <AddArenaCard i={letteredArenas.length} onClick={() => setEditingArena({})} />
    </div>
  </div>);
  if (screen === "stuck") return wrap(<StuckScreen onBack={() => setScreen("home")} onSelectArena={(arena) => { setSelectedArena(arena); setScreen("select"); }} arenas={letteredArenas} />);

  return wrap(
    <>
      <EmberDropModal drop={pendingDrop} onDismiss={() => setPendingDrop(null)} />
      {/* ── HOME ── */}
      {screen === "home" && (
        <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
          {/* Ember particles */}
          <div style={{ position: "fixed", inset: 0, pointerEvents: "none", zIndex: 0, overflow: "hidden" }}>
            {[
              { left: "12%", delay: "0s", dur: "7s", color: "#E8C547" },
              { left: "28%", delay: "1.8s", dur: "9s", color: "#C0392B" },
              { left: "55%", delay: "0.6s", dur: "8s", color: "#D4A017" },
              { left: "72%", delay: "3s", dur: "6.5s", color: "#E8C547" },
              { left: "88%", delay: "1.2s", dur: "10s", color: "#B87333" },
              { left: "42%", delay: "4s", dur: "7.5s", color: "#708090" },
            ].map((e, i) => (
              <div key={i} style={{
                position: "absolute", bottom: "-10px", left: e.left,
                width: 3, height: 3, borderRadius: "50%", background: e.color,
                opacity: 0.22, filter: `blur(0.5px) drop-shadow(0 0 3px ${e.color})`,
                animation: `emberRise ${e.dur} ${e.delay} infinite ease-in`,
              }} />
            ))}
          </div>
          <div style={{ padding: "44px 20px 12px", display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div>
              <div style={{ fontSize: 9, letterSpacing: 6, color: "rgba(255,255,255,0.25)", marginBottom: 6 }}>ARENA PROTOCOL</div>
              <button onClick={() => setScreen("home")} style={{ background: "none", border: "none", padding: 0, cursor: "pointer", textAlign: "left" }}>
                <div style={{ fontSize: 22, fontWeight: "bold", letterSpacing: 2, lineHeight: 1.2 }}>ENTER THE<br /><span style={{ color: "#E8C547" }}>ARENA</span></div>
              </button>
              {/* Forge title */}
              {(() => { const title = getActiveTitle(sessions); return title ? (
                <div style={{ marginTop: 5, fontSize: 8, letterSpacing: 4, color: title.arenaId ? (letteredArenas.find(a=>a.id===title.arenaId)?.color || "#E8C547") : "#E8C547", opacity: 0.75 }}>{title.label}</div>
              ) : null; })()}
              {todaySessions > 0 && <div style={{ marginTop: 4, fontSize: 9, letterSpacing: 3, color: "rgba(255,255,255,0.25)" }}>● {todaySessions} SESSION{todaySessions !== 1 ? "S" : ""} TODAY</div>}
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
                  <ArenaCard key={arena.id} arena={arena} sessCount={sessions.filter(s => s.arenaId === arena.id && s.date === todayStr()).length} streak={arenaStreaks[arena.id] || 0} i={i} editMode={editMode} onClick={() => handleArenaSelect(arena)} onEdit={() => setEditingArena(arena)} sessions={sessions} />
                ))}
                {editMode && <AddArenaCard i={letteredArenas.length} onClick={() => setEditingArena({})} />}
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
                {letteredArenas.slice(Math.ceil(letteredArenas.length / 2)).map((arena, i) => (
                  <ArenaCard key={arena.id} arena={arena} sessCount={sessions.filter(s => s.arenaId === arena.id && s.date === todayStr()).length} streak={arenaStreaks[arena.id] || 0} i={i + Math.ceil(letteredArenas.length / 2)} editMode={editMode} onClick={() => handleArenaSelect(arena)} onEdit={() => setEditingArena(arena)} sessions={sessions} />
                ))}
              </div>
            </div>
          </div>

          {/* App shortcuts — above I AM STUCK */}
          <AppShortcutsBar />

          <div style={{ padding: "0 14px 10px" }}>
            <button onClick={() => setScreen("protocols")} style={{ width: "100%", padding: "12px", background: "rgba(112,128,144,0.06)", border: "1px solid rgba(112,128,144,0.2)", borderRadius: 14, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 10, fontFamily: "'Courier New', monospace", marginBottom: 8 }}
              onPointerEnter={e => { e.currentTarget.style.background = "rgba(112,128,144,0.12)"; }}
              onPointerLeave={e => { e.currentTarget.style.background = "rgba(112,128,144,0.06)"; }}>
              <span style={{ fontSize: 11, color: "#708090" }}>◈</span>
              <span style={{ fontSize: 10, letterSpacing: 4, color: "#708090", fontWeight: "bold" }}>PROTOCOLS</span>
            </button>
            <button onClick={() => setScreen("stuck")} style={{ width: "100%", padding: "14px", background: "rgba(255,143,163,0.06)", border: "1px solid rgba(255,143,163,0.25)", borderRadius: 14, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 10, fontFamily: "'Courier New', monospace" }}
              onPointerEnter={e => { e.currentTarget.style.background = "rgba(255,143,163,0.12)"; }}
              onPointerLeave={e => { e.currentTarget.style.background = "rgba(255,143,163,0.06)"; }}>
              <span style={{ fontSize: 13, color: "#FF8FA3" }}>⚡</span>
              <span style={{ fontSize: 11, letterSpacing: 4, color: "#FF8FA3", fontWeight: "bold" }}>I AM STUCK</span>
            </button>
          </div>

          <div style={{ padding: "8px 20px 16px", borderTop: "1px solid rgba(255,255,255,0.05)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
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
        <SelectScreen
          selectedArena={selectedArena}
          sessionNote={sessionNote}
          setSessionNote={setSessionNote}
          selectedDuration={selectedDuration}
          setSelectedDuration={setSelectedDuration}
          isCustomActive={isCustomActive}
          setIsCustomActive={setIsCustomActive}
          customMinutes={customMinutes}
          setCustomMinutes={setCustomMinutes}
          durationValid={durationValid}
          startArena={startArena}
          onBack={() => { setScreen("home"); setIsCustomActive(false); setCustomMinutes(""); }}
        />
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
  @keyframes emberRise {
    0%   { transform: translateY(0) translateX(0) scale(1); opacity: 0.22; }
    20%  { opacity: 0.28; }
    50%  { transform: translateY(-40vh) translateX(8px) scale(1.3); opacity: 0.15; }
    80%  { transform: translateY(-75vh) translateX(-5px) scale(0.8); opacity: 0.06; }
    100% { transform: translateY(-100vh) translateX(3px) scale(0.5); opacity: 0; }
  }
  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
  body { margin: 0; }
  button:active { opacity: 0.75; }
  textarea::placeholder, input::placeholder { color: rgba(255,255,255,0.2); }
  input[type="time"]::-webkit-calendar-picker-indicator { filter: invert(1); opacity: 0.5; }
`;
