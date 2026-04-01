// DataStore.swift — Arena Protocol
// All models, defaults, and persistence layer
// iOS 26 / Swift 6 compatible using @Observable + UserDefaults

import Foundation
import Observation
@preconcurrency import UserNotifications
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Models

struct Arena: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var label: String
    var letter: String
    var color: String          // hex string
    var subtitle: String
    var description: String
    var icon: String
    var examples: [String]
    var subArenas: [String: [String]]
    var backgroundImageName: String? = nil   // asset catalog name or Documents filename

    static func reletter(_ arenas: [Arena]) -> [Arena] {
        arenas.enumerated().map { i, a in
            var updated = a
            updated.letter = String(UnicodeScalar(65 + i)!)
            return updated
        }
    }
}

struct Session: Identifiable, Codable {
    var id: String = UUID().uuidString
    var arenaId: String
    var duration: Int          // minutes
    var date: String           // yyyy-MM-dd
    var note: String
    var ts: Double             // epoch ms
    var social: Bool = false
}

struct ArenaProtocolModel: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var glyph: String
    var color: String
    var description: String
    var blocks: [ProtocolBlock]
}

struct ProtocolBlock: Codable, Hashable {
    var arenaId: String
    var label: String
    var duration: Int
    var color: String
}

struct Habit: Identifiable, Codable {
    var id: String
    var name: String
    var goal: String
    var color: String
    var createdAt: String
}

struct HabitLog: Codable {
    var habitId: String
    var date: String
    var value: Bool
    var ts: Double
}

struct JournalEntry: Codable {
    var date: String
    var text: String
    var ts: Double
}

struct IdeaNote: Identifiable, Codable {
    var id: Double
    var text: String
    var ts: String
}

struct CompletedSession: Equatable {
    let arena: Arena
    let durationMins: Int
    let note: String
    let social: Bool
}

// MARK: - Forge Drop Result

/// Carries the full outcome of a session completion through the drop pipeline.
/// The modal reads this to show narrative + egg + hatch in a seamless flow.
struct ForgeDropResult: Identifiable {
    let id = UUID()
    var narrative: EmberDrop?            // forge narrative or legacy drop
    var eggDrop: InventoryEgg?           // egg that just dropped (nil if none)
    var hatchedItems: [InventoryItem]    // eggs that auto-hatched this session

    var hasContent: Bool { narrative != nil || eggDrop != nil || !hatchedItems.isEmpty }
}

struct DockApp: Identifiable, Codable {
    var id: String
    var name: String
    var urlScheme: String
    var sfSymbol: String
    var brandColor: String
}

enum CalendarViewStyle: String, Codable, CaseIterable {
    case timeline   // vertical timeline with time column
    case compact    // minimal horizontal cards
    case agenda     // list with grouping (now / up next / later)

    var label: String {
        switch self {
        case .timeline: return "TIMELINE"
        case .compact:  return "COMPACT"
        case .agenda:   return "AGENDA"
        }
    }

    var icon: String {
        switch self {
        case .timeline: return "◫"
        case .compact:  return "▬"
        case .agenda:   return "☰"
        }
    }
}

struct AppSettings: Codable {
    var windDownTime: String = "21:30"
    var clockTimezone: String = "America/Los_Angeles"
    var calendarEnabled: Bool = false
    var calendarAutoStart: Bool = false
    var calendarViewStyle: CalendarViewStyle = .timeline
}

// MARK: - Forge Progression Models

enum EggRarity: String, Codable, CaseIterable, Sendable {
    case common, uncommon, rare, epic, legendary, echo

    var displayName: String {
        switch self {
        case .common:    return "COMMON"
        case .uncommon:  return "UNCOMMON"
        case .rare:      return "RARE"
        case .epic:      return "EPIC"
        case .legendary: return "LEGENDARY"
        case .echo:      return "ECHO"
        }
    }
    var glyph: String {
        switch self {
        case .common:    return "▪"
        case .uncommon:  return "◆"
        case .rare:      return "★"
        case .epic:      return "⬟"
        case .legendary: return "✦"
        case .echo:      return "◈"
        }
    }
    var hexColor: String {
        switch self {
        case .common:    return "#9CA3AF"
        case .uncommon:  return "#60A5FA"
        case .rare:      return "#A78BFA"
        case .epic:      return "#F59E0B"
        case .legendary: return "#E8C547"
        case .echo:      return "#34D399"
        }
    }
    var hatchThreshold: Int {
        switch self {
        case .common:    return 5
        case .uncommon:  return 15
        case .rare:      return 30
        case .epic:      return 60
        case .legendary: return 100
        case .echo:      return 100
        }
    }
}

enum InventoryItemType: String, Codable, Sendable {
    case title, glyph, badge, aura, fragment, echo, skin
}

// MARK: - Button Skins

struct ButtonSkin: Identifiable, Codable {
    let id: String
    let name: String
    let material: String       // rendering key for Phase 2
    let rarity: EggRarity
    let description: String
    let glyph: String
}

/// Master catalog of all skins. Keyed by id.
let SKIN_CATALOG: [ButtonSkin] = [
    // Common
    ButtonSkin(id: "slate",         name: "SLATE",          material: "slate",
               rarity: .common,     description: "Cold-pressed stone. Quiet and unyielding.",          glyph: "▬"),
    ButtonSkin(id: "leather",       name: "LEATHER",        material: "leather",
               rarity: .common,     description: "Worn hide, cracked with use. It remembers.",         glyph: "≋"),
    // Uncommon
    ButtonSkin(id: "obsidian",      name: "OBSIDIAN",       material: "obsidian",
               rarity: .uncommon,   description: "Volcanic glass — sharp edges, deep black mirror.",   glyph: "◆"),
    ButtonSkin(id: "bronze",        name: "BRONZE",         material: "bronze",
               rarity: .uncommon,   description: "Hammered alloy. Warm to the touch.",                 glyph: "⬡"),
    // Rare
    ButtonSkin(id: "marble",        name: "MARBLE",         material: "marble",
               rarity: .rare,       description: "Veined stone from a forgotten quarry.",              glyph: "◇"),
    ButtonSkin(id: "ironwood",      name: "IRONWOOD",       material: "ironwood",
               rarity: .rare,       description: "Petrified grain. Harder than the axe that felled it.", glyph: "⊞"),
    // Epic
    ButtonSkin(id: "volcanic",      name: "VOLCANIC",       material: "volcanic",
               rarity: .epic,       description: "Still hot. Cracks glow like cooling magma.",         glyph: "⬢"),
    ButtonSkin(id: "frosted_glass", name: "FROSTED GLASS",  material: "frosted_glass",
               rarity: .epic,       description: "Translucent ice. Light bends through it.",           glyph: "◈"),
    // Legendary
    ButtonSkin(id: "celestial",     name: "CELESTIAL",      material: "celestial",
               rarity: .legendary,  description: "Night sky compressed into a surface. Stars drift.",  glyph: "✦"),
    ButtonSkin(id: "void",          name: "VOID",           material: "void",
               rarity: .legendary,  description: "Nothing. And somehow, it pulls you in.",             glyph: "◉"),
]

struct InventoryEgg: Identifiable, Codable {
    var id: String
    var rarity: EggRarity
    var droppedAt: Double           // epoch ms
    var sessionCountOnDrop: Int     // sessions.count when dropped
    var hatchThreshold: Int         // cached at drop time
    var isHatched: Bool
    var rewardId: String?
    var sourceArenaId: String?
    var sourceTrigger: String
}

struct InventoryItem: Identifiable, Codable {
    var id: String
    var type: InventoryItemType
    var rarity: EggRarity
    var name: String
    var description: String
    var glyph: String
    var isEquipped: Bool
    var unlockedAt: Double          // epoch ms
    var arenaId: String?            // for glyph items
}

struct RebirthState: Codable {
    var arenaId: String
    var islandLevel: Int            // 1–10
    var totalSessionsAllTime: Int   // preserved across resets
    var rebirthDates: [String]      // yyyy-MM-dd of each reset
}

// MARK: - Arena Rank Progression

enum ArenaRankTier: Int, Codable, CaseIterable, Comparable {
    case dormant       = 0   // 0 streak
    case sparked       = 1   // 1–2 days
    case kindling      = 2   // 3–6 days
    case burning       = 3   // 7–13 days
    case blazing       = 4   // 14–20 days
    case inferno       = 5   // 21–33 days
    case transcendent  = 6   // 34–49 days
    case eternalFlame  = 7   // 50+ days

    static func < (lhs: ArenaRankTier, rhs: ArenaRankTier) -> Bool { lhs.rawValue < rhs.rawValue }

    static func from(streak: Int) -> ArenaRankTier {
        switch streak {
        case 0:      return .dormant
        case 1...2:  return .sparked
        case 3...6:  return .kindling
        case 7...13: return .burning
        case 14...20: return .blazing
        case 21...33: return .inferno
        case 34...49: return .transcendent
        default:      return .eternalFlame
        }
    }

    var label: String {
        switch self {
        case .dormant:      return "DORMANT"
        case .sparked:      return "SPARKED"
        case .kindling:     return "KINDLING"
        case .burning:      return "BURNING"
        case .blazing:      return "BLAZING"
        case .inferno:      return "INFERNO"
        case .transcendent: return "TRANSCENDENT"
        case .eternalFlame: return "ETERNAL FLAME"
        }
    }

    /// Border line width progression
    var borderWidth: CGFloat {
        switch self {
        case .dormant:      return 1
        case .sparked:      return 1
        case .kindling:     return 1.2
        case .burning:      return 1.5
        case .blazing:      return 1.8
        case .inferno:      return 2.0
        case .transcendent: return 2.2
        case .eternalFlame: return 2.5
        }
    }

    /// Border base opacity
    var borderOpacity: Double {
        switch self {
        case .dormant:      return 0.18
        case .sparked:      return 0.30
        case .kindling:     return 0.40
        case .burning:      return 0.50
        case .blazing:      return 0.60
        case .inferno:      return 0.70
        case .transcendent: return 0.80
        case .eternalFlame: return 0.90
        }
    }
}

struct ArenaRankState: Codable, Identifiable {
    var id: String { arenaId }
    var arenaId: String
    var peakStreak: Int              // highest streak ever achieved
    var achievedRank: ArenaRankTier  // locked-in rank from peak streak
    var achievedAt: Double           // epoch ms when current rank was reached
}

struct PlayerProfile: Codable {
    var equippedTitle: String?              // displayed title string
    var equippedGlyphs: [String: String]    // arenaId → glyph character
    var equippedSkins: [String: String] = [:]  // arenaId → skinId
    var isPublic: Bool
    var joinedAt: Double                    // epoch ms
}

struct JointArenaEntry: Identifiable {
    let id = UUID()
    let arena: Arena
    let minutes: Int
    var note: String = ""
    var calEventId: String? = nil
    var scheduledStart: Date = Date()
    var scheduledEnd: Date = Date()
}

struct ActiveSessionState {
    var arena: Arena
    var durationMins: Int
    var note: String
    var startTime: Date
    var endTime: Date
    var isPaused: Bool = false
    var pausedRemaining: TimeInterval = 0
    var jointArenas: [Arena] = []
    var jointEntries: [JointArenaEntry] = []
    var calEventId: String? = nil
    var social: Bool = false
}

// MARK: - ActiveSessionState timeline helpers

extension ActiveSessionState {
    /// Ordered list of every arena time slot for this session (primary first, then joints in sequence).
    var timeline: [(arena: Arena, start: Date, end: Date)] {
        let primaryEnd = jointEntries.isEmpty ? endTime : jointEntries[0].scheduledStart
        var slots: [(arena: Arena, start: Date, end: Date)] = [(arena, startTime, primaryEnd)]
        for entry in jointEntries {
            slots.append((entry.arena, entry.scheduledStart, entry.scheduledEnd))
        }
        return slots
    }

    /// The arena slot actively running at `now` (start ≤ now < end). nil if between slots or complete.
    func currentSlot(now: Date = Date()) -> (arena: Arena, start: Date, end: Date)? {
        timeline.first { $0.start <= now && now < $0.end }
    }

    /// The slot immediately after the currently-running one, or the first upcoming slot if none active.
    func nextSlot(now: Date = Date()) -> (arena: Arena, start: Date, end: Date)? {
        let tl = timeline
        if let idx = tl.firstIndex(where: { $0.start <= now && now < $0.end }) {
            let next = idx + 1
            return next < tl.count ? tl[next] : nil
        }
        return tl.first { $0.start > now }
    }
}

struct MorningCheckin: Codable {
    var date: String
    var completed: [String]
}

// MARK: - Scheduling & Deadlines

enum ScheduledKind: String, Codable, Equatable {
    case arena
    case arenaProtocol = "protocol"
}

struct ScheduledBlock: Identifiable, Codable {
    var id: String = UUID().uuidString
    var kind: ScheduledKind
    var itemId: String          // arenaId or protocolId
    var itemLabel: String       // cached display name
    var itemGlyph: String       // cached icon/glyph
    var itemColor: String       // cached hex color
    var scheduledAt: Date
    var durationMins: Int       // arena: user-specified; protocol: sum of blocks
    var note: String = ""
    var notificationId: String? = nil
}

struct ArenaDeadline: Identifiable, Codable {
    var id: String = UUID().uuidString
    var arenaId: String
    var arenaLabel: String
    var arenaColor: String
    var targetDate: Date
    var targetSessions: Int     // number of sessions to complete by targetDate
    var note: String = ""
    var isCompleted: Bool = false
}

// MARK: - Static Defaults

let DEFAULT_DOCK_APPS: [DockApp] = [
    DockApp(id: "spotify",   name: "Spotify",  urlScheme: "spotify://",        sfSymbol: "music.note",          brandColor: "#1DB954"),
    DockApp(id: "audible",   name: "Audible",  urlScheme: "audible://",        sfSymbol: "headphones",          brandColor: "#F47920"),
    DockApp(id: "health",    name: "Health",   urlScheme: "x-apple-health://", sfSymbol: "heart.fill",          brandColor: "#FF2D55"),
    DockApp(id: "youtube",   name: "YouTube",  urlScheme: "youtube://",        sfSymbol: "play.rectangle.fill", brandColor: "#FF0000"),
    DockApp(id: "notes",     name: "Notes",    urlScheme: "mobilenotes://",    sfSymbol: "note.text",           brandColor: "#FFD60A"),
    DockApp(id: "gcalendar", name: "Calendar", urlScheme: "googlecalendar://", sfSymbol: "calendar",            brandColor: "#1A73E8"),
]

let DEFAULT_ARENAS: [Arena] = [
    Arena(
        id: "alignment", label: "ALIGNMENT", letter: "A", color: "#60A5FA",
        subtitle: "plan · research · organise · ready",
        description: "Set the conditions for everything else. You can't build on a shaky foundation.",
        icon: "🎯",
        examples: ["Write today's single most important task", "Review and prioritise your inbox",
                   "Plan tomorrow the night before", "Weekly review — what worked, what didn't",
                   "Clarify one ambiguous project", "Research before you decide",
                   "Organise your workspace", "Map out the next 3 steps"],
        subArenas: [
            "PLANNING": ["Write today's single most important task", "Plan tomorrow the night before",
                         "Weekly review — what worked, what didn't", "Map out the next 3 steps"],
            "RESEARCH": ["Clarify one ambiguous project", "Research before you decide",
                         "Read for 20 min on a relevant topic", "Summarise what you learned"],
            "ORGANISE": ["Clear your workspace", "Process your inbox to zero",
                         "Capture all open loops", "File or delete things that aren't actions"]
        ],
        backgroundImageName: "bg_alignment"
    ),
    Arena(
        id: "work", label: "WORK", letter: "B", color: "#E8C547",
        subtitle: "execute · build · ship · produce",
        description: "The work itself. Ideas without output are just noise. Show up and produce.",
        icon: "⚡",
        examples: ["25 min deep work session", "Ship one thing — however small",
                   "Work on the hardest task first", "Write 200 words",
                   "Complete one task end-to-end", "Learn one skill for 20 min",
                   "Do one thing you've been avoiding", "Build a system for a repeated task"],
        subArenas: [
            "DEEP WORK": ["25 min deep work session", "Work on the hardest task first",
                          "Write 200 words", "Build a system for a repeated task"],
            "BUILD": ["Ship one thing — however small", "Complete one task end-to-end",
                      "Sketch a prototype or outline", "Build one thing, start to finish"],
            "MASTERY": ["Learn one skill for 20 min", "Study something outside your comfort zone",
                        "Practice deliberately for 15 min", "Teach what you learned today"]
        ],
        backgroundImageName: "bg_labor"
    ),
    Arena(
        id: "recovery", label: "RECOVERY", letter: "C", color: "#A78BFA",
        subtitle: "decompress · reflect · restore · learn",
        description: "The mind needs rest too. Downtime done right is not laziness — it's maintenance.",
        icon: "🌙",
        examples: ["5 min breathing or meditation", "Journal for 10 min", "Read something non-urgent",
                   "Walk without a destination", "Close all tabs and rest",
                   "Listen to music with no other task", "Reflect on what went well today",
                   "Write down three things you're grateful for"],
        subArenas: [
            "DECOMPRESS": ["Close all tabs and rest", "Listen to music with no other task",
                           "Walk without a destination", "5 min breathing or meditation"],
            "REFLECT": ["Journal for 10 min", "Write down three things you're grateful for",
                        "Reflect on what went well today", "Review what you'd do differently"],
            "LEARN": ["Read something non-urgent", "Watch an educational video",
                      "Take notes on a book chapter", "Study something you're curious about"]
        ],
        backgroundImageName: "bg_recharge"
    ),
    Arena(
        id: "movement", label: "MOVEMENT", letter: "D", color: "#34D399",
        subtitle: "move · train · recover · fuel",
        description: "The body is not separate from performance. Move it deliberately, every day.",
        icon: "🏃",
        examples: ["10 min walk", "Strength training", "Cook a real meal",
                   "Stretch for 10 min", "5 min breathwork", "Cold shower",
                   "Drink 2L of water", "20 min run", "No screens 1hr before bed"],
        subArenas: [
            "TRAIN": ["Strength training", "10 min walk", "20 min run", "Cold shower"],
            "RECOVER": ["Stretch for 10 min", "5 min breathwork", "Sleep before midnight", "20 min nap"],
            "FUEL": ["Cook a real meal", "Drink 2L of water", "Prep meals for tomorrow", "No sugar today"]
        ],
        backgroundImageName: "bg_movement"
    )
]

// Social is not a regular arena — it's a modifier/standalone mode.
// This constant is used when the user starts a Social-only session.
let SOCIAL_ARENA = Arena(
    id: "social", label: "SOCIAL", letter: "S", color: "#B794F4",
    subtitle: "connect · share · be present",
    description: "Time with others. Every session can be social — this one is dedicated to it.",
    icon: "🤝",
    examples: ["Coffee with a friend", "Group workout", "Team collaboration",
               "Family time", "Social event", "Catch up with someone",
               "Shared meal", "Coworking session"],
    subArenas: [:],
    backgroundImageName: "bg_social"
)

let DEFAULT_PROTOCOLS: [ArenaProtocolModel] = [
    ArenaProtocolModel(
        id: "launcher", name: "THE LAUNCHER", glyph: "◎", color: "#60A5FA",
        description: "Align, then execute. Build momentum from a clean start.",
        blocks: [
            ProtocolBlock(arenaId: "alignment", label: "ALIGNMENT", duration: 15, color: "#60A5FA"),
            ProtocolBlock(arenaId: "work",      label: "WORK",      duration: 25, color: "#E8C547")
        ]
    ),
    ArenaProtocolModel(
        id: "warrior", name: "THE WARRIOR", glyph: "◆", color: "#E8C547",
        description: "Move the body. Then move the work. No excuses.",
        blocks: [
            ProtocolBlock(arenaId: "movement", label: "MOVEMENT", duration: 20, color: "#34D399"),
            ProtocolBlock(arenaId: "work",     label: "WORK",     duration: 30, color: "#E8C547")
        ]
    ),
    ArenaProtocolModel(
        id: "recharge", name: "THE RECHARGE", glyph: "◑", color: "#A78BFA",
        description: "Body and mind recovery. Reset before the next push.",
        blocks: [
            ProtocolBlock(arenaId: "movement", label: "MOVEMENT", duration: 20, color: "#34D399"),
            ProtocolBlock(arenaId: "recovery", label: "RECOVERY", duration: 20, color: "#A78BFA")
        ]
    ),
    ArenaProtocolModel(
        id: "full-day", name: "THE FULL DAY", glyph: "◉", color: "#E8C547",
        description: "All four arenas. A complete session.",
        blocks: [
            ProtocolBlock(arenaId: "alignment", label: "ALIGNMENT", duration: 10, color: "#60A5FA"),
            ProtocolBlock(arenaId: "work",      label: "WORK",      duration: 25, color: "#E8C547"),
            ProtocolBlock(arenaId: "movement",  label: "MOVEMENT",  duration: 15, color: "#34D399"),
            ProtocolBlock(arenaId: "recovery",  label: "RECOVERY",  duration: 10, color: "#A78BFA")
        ]
    )
]

let MORNING_HABITS_STATIC: [(id: String, label: String, duration: String, description: String, color: String)] = [
    ("reading",  "READING",       "5 MIN", "Something positive. Feed your mind before the world does.",                        "#E8C547"),
    ("goals",    "GOAL PLANNING", "5 MIN", "Set your intentions. What are the three arenas you're entering today?",            "#4ECDC4"),
    ("movement", "MOVEMENT",      "5 MIN", "Get moving. Signal to your body that today has already begun.",                    "#A8E6A3")
]

let STUCK_PROMPTS = [
    "You've been circling. Pick one arena. Enter it.",
    "Momentum is a choice. What's the smallest move?",
    "Stuck means your brain needs a container. Give it one.",
    "The resistance you feel? That's the arena calling.",
    "Don't optimize. Don't plan. Just start.",
    "One minute of action beats an hour of intention.",
    "Your future self already made the decision. Catch up.",
    "The timer ends. You move. No negotiation."
]

let ARENA_ICONS = [
    // Geometric
    "◈", "◎", "⬡", "◇", "△", "○", "◉", "◆", "▲", "★", "⬟", "⬠", "⊕", "⊗", "⊘", "❋", "✦", "⟡",
    // Emoji — focus & work
    "🎯", "⚡️", "🔥", "💡", "🧠", "🛠", "📐", "🗂",
    // Emoji — health
    "💪", "🏃", "🧘", "🥗", "💤", "🌿", "🫀", "🌊",
    // Emoji — connection
    "🤝", "💬", "🌐", "🏡", "❤️", "🫂", "👁", "🌱",
    // Emoji — misc
    "🎲", "🌙", "☀️", "🗺", "🔑", "⚙️", "🎵", "📖"
]
let ARENA_COLORS = ["#E8C547", "#4ECDC4", "#A8E6A3", "#FF8FA3", "#B794F4", "#F4A261",
                    "#60A5FA", "#F87171", "#34D399", "#A78BFA", "#FB923C", "#38BDF8",
                    "#E879F9", "#4ADE80"]
let DURATIONS = [5, 10, 30, 60, 90]

struct IntervalPreset {
    let label: String
    let icon: String
    let minutes: Int
}

let INTERVAL_PRESETS: [IntervalPreset] = [
    IntervalPreset(label: "FLOW",     icon: "〜", minutes: 5),
    IntervalPreset(label: "DRIFT",    icon: "◌",  minutes: 10),
    IntervalPreset(label: "WALK",     icon: "◎",  minutes: 20),
    IntervalPreset(label: "BREATHE",  icon: "◉",  minutes: 4),
    IntervalPreset(label: "REST",     icon: "△",  minutes: 15),
    IntervalPreset(label: "RESET",    icon: "⬡",  minutes: 30),
]

// MARK: - Forge / Reward

let FORGE_MILESTONES = [3, 7, 13, 21, 33, 50, 77, 111]
let FORGE_MARKS = ["▪", "▸", "◆", "★", "⬟", "✦", "❋", "⟡"]
let FORGE_MARK_NAMES = ["First Blood", "Kindled", "Forged", "Tempered", "Hardened", "Undying", "Mythic", "Eternal"]

struct ForgeMark {
    let mark: String
    let name: String
    let count: Int
}

func getForgeMarkForArena(arenaId: String, sessions: [Session]) -> ForgeMark? {
    let count = sessions.filter { $0.arenaId == arenaId }.count
    for i in stride(from: FORGE_MILESTONES.count - 1, through: 0, by: -1) {
        if count >= FORGE_MILESTONES[i] {
            return ForgeMark(mark: FORGE_MARKS[i], name: FORGE_MARK_NAMES[i], count: count)
        }
    }
    return nil
}

struct Title: Sendable {
    let id: String
    let label: String
    let arenaId: String?
    let condition: @Sendable ([Session]) -> Bool
}

let TITLES: [Title] = [
    Title(id: "the_moving",   label: "THE MOVING",   arenaId: "body",   condition: { $0.filter { $0.arenaId == "body"   }.count >= 7  }),
    Title(id: "the_burning",  label: "THE BURNING",  arenaId: "body",   condition: { $0.filter { $0.arenaId == "body"   }.count >= 20 }),
    Title(id: "the_witness",  label: "THE WITNESS",  arenaId: "tribe",  condition: { $0.filter { $0.arenaId == "tribe"  }.count >= 5  }),
    Title(id: "the_builder",  label: "THE BUILDER",  arenaId: "craft",  condition: { $0.filter { $0.arenaId == "craft"  }.count >= 10 }),
    Title(id: "the_seeker",   label: "THE SEEKER",   arenaId: "spirit", condition: { $0.filter { $0.arenaId == "spirit" }.count >= 7  }),
    Title(id: "the_returned", label: "THE RETURNED", arenaId: nil,      condition: { Set($0.map { $0.date }).count >= 3 }),
    Title(id: "the_forge",    label: "THE FORGE",    arenaId: nil,      condition: { Set($0.map { $0.arenaId }).count >= 4 }),
    Title(id: "the_unbroken", label: "THE UNBROKEN", arenaId: nil,      condition: { sessions in
        let dates = Set(sessions.map { $0.date })
        var streak = 0
        var check = todayString()
        let cal = Calendar.current
        for _ in 0..<365 {
            if dates.contains(check) {
                streak += 1
                let d = cal.date(byAdding: .day, value: -1, to: dateFromString(check))!
                check = stringFromDate(d)
            } else { break }
        }
        return streak >= 7
    })
]

struct EmberDrop: Identifiable, Sendable {
    let id: String
    let message: String
    let glyph: String
    let trigger: @Sendable ([Session]) -> Bool
}

let EMBER_DROPS: [EmberDrop] = [
    EmberDrop(id: "drop_1",     message: "The first step is always the hardest. You took it.",            glyph: "▸", trigger: { $0.count >= 1  }),
    EmberDrop(id: "drop_5",     message: "Five sessions. The forge is warming.",                          glyph: "◆", trigger: { $0.count >= 5  }),
    EmberDrop(id: "drop_13",    message: "Thirteen. An odd number. That's the point. Keep going.",        glyph: "★", trigger: { $0.count >= 13 }),
    EmberDrop(id: "drop_3arena",message: "Three arenas in one day. You showed up everywhere.",             glyph: "✦", trigger: { sessions in
        let today = todayString()
        return Set(sessions.filter { $0.date == today }.map { $0.arenaId }).count >= 3
    }),
    EmberDrop(id: "drop_week",  message: "Seven consecutive days. Depression told you this was impossible.", glyph: "⬟", trigger: { sessions in
        let dates = Set(sessions.map { $0.date })
        let cal = Calendar.current
        for i in 0..<7 {
            let d = cal.date(byAdding: .day, value: -i, to: Date())!
            if !dates.contains(stringFromDate(d)) { return false }
        }
        return true
    })
]

func getUnlockedTitles(sessions: [Session]) -> [Title] {
    TITLES.filter { $0.condition(sessions) }
}

func getActiveTitle(sessions: [Session]) -> Title? {
    getUnlockedTitles(sessions: sessions).last
}

func checkEmberDrop(sessions: [Session], seenDrops: [String]) -> EmberDrop? {
    EMBER_DROPS.first { !seenDrops.contains($0.id) && $0.trigger(sessions) }
}

// MARK: - Date Helpers

func todayString() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: Date())
}

func dateFromString(_ s: String) -> Date {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.date(from: s) ?? Date()
}

func stringFromDate(_ d: Date) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: d)
}

func formatTime(_ seconds: Int) -> String {
    String(format: "%02d:%02d", seconds / 60, seconds % 60)
}

func uid() -> String { UUID().uuidString.lowercased().prefix(7).map { String($0) }.joined() }

// MARK: - Streak / Stats

func getStreakForArena(arenaId: String, sessions: [Session]) -> Int {
    let dates = Array(Set(sessions.filter { $0.arenaId == arenaId }.map { $0.date })).sorted(by: >)
    guard !dates.isEmpty else { return 0 }
    var streak = 0
    var check = todayString()
    let cal = Calendar.current
    for d in dates {
        if d == check {
            streak += 1
            let next = cal.date(byAdding: .day, value: -1, to: dateFromString(check))!
            check = stringFromDate(next)
        } else { break }
    }
    return streak
}

struct WeekDay {
    let date: String
    let label: String
    let sessions: [Session]
    let arenas: [String]
}

func getWeeklyData(sessions: [Session]) -> [WeekDay] {
    let cal = Calendar.current
    let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
    let labelFmt = DateFormatter(); labelFmt.dateFormat = "EEE"
    return (0..<7).reversed().map { i in
        let d = cal.date(byAdding: .day, value: -i, to: Date())!
        let ds = fmt.string(from: d)
        let daySessions = sessions.filter { $0.date == ds }
        return WeekDay(date: ds, label: labelFmt.string(from: d),
                       sessions: daySessions,
                       arenas: Array(Set(daySessions.map { $0.arenaId })))
    }
}

struct HabitCell {
    let date: String
    let value: Bool?
}

func getHabitGrid(habitId: String, logs: [HabitLog]) -> [HabitCell] {
    let cal = Calendar.current
    let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
    return (0..<70).reversed().map { i in
        let d = cal.date(byAdding: .day, value: -i, to: Date())!
        let ds = fmt.string(from: d)
        let log = logs.first { $0.habitId == habitId && $0.date == ds }
        return HabitCell(date: ds, value: log?.value)
    }
}

func getHabitStreak(habitId: String, logs: [HabitLog]) -> Int {
    var streak = 0
    var check = todayString()
    let cal = Calendar.current
    for _ in 0..<365 {
        if let log = logs.first(where: { $0.habitId == habitId && $0.date == check }), log.value {
            streak += 1
            let d = cal.date(byAdding: .day, value: -1, to: dateFromString(check))!
            check = stringFromDate(d)
        } else { break }
    }
    return streak
}

// MARK: - Persistence

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()

func loadFromDefaults<T: Decodable>(_ key: String, fallback: T) -> T {
    guard let data = UserDefaults.standard.data(forKey: key),
          let val = try? decoder.decode(T.self, from: data) else { return fallback }
    return val
}

func saveToDefaults<T: Encodable>(_ key: String, _ value: T) {
    if let data = try? encoder.encode(value) {
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - DataStore (@Observable)

@Observable
final class DataStore {

    // State
    var arenas:     [Arena]              = loadFromDefaults("arena_custom_arenas",   fallback: DEFAULT_ARENAS)
    var socialArena: Arena              = loadFromDefaults("arena_social",           fallback: SOCIAL_ARENA)
    var sessions:   [Session]            = loadFromDefaults("arena_sessions",        fallback: [])
    var habits:     [Habit]              = loadFromDefaults("arena_habits",          fallback: [])
    var habitLogs:  [HabitLog]           = loadFromDefaults("arena_habit_logs",      fallback: [])
    var journals:   [JournalEntry]       = loadFromDefaults("arena_journals",        fallback: [])
    var ideas:      [IdeaNote]           = loadFromDefaults("arena_ideas",           fallback: [])
    var dockApps:   [DockApp]            = loadFromDefaults("arena_dock_apps",       fallback: DEFAULT_DOCK_APPS)
    var settings:   AppSettings          = loadFromDefaults("arena_settings",        fallback: AppSettings())
    var protocols:  [ArenaProtocolModel] = loadFromDefaults("arena_protocols",       fallback: DEFAULT_PROTOCOLS)
    var seenDrops:     [String]             = loadFromDefaults("arena_seen_drops",      fallback: [])
    var seenEggDrops:  [String]             = loadFromDefaults("arena_seen_egg_drops", fallback: [])
    var eggs:          [InventoryEgg]       = loadFromDefaults("arena_eggs",           fallback: [])
    var inventory:     [InventoryItem]      = loadFromDefaults("arena_inventory",      fallback: [])
    var rebirthStates: [RebirthState]       = loadFromDefaults("arena_rebirth",        fallback: [])
    var arenaRanks:    [ArenaRankState]     = loadFromDefaults("arena_ranks",          fallback: [])
    var playerProfile: PlayerProfile        = {
        let saved: PlayerProfile = loadFromDefaults("arena_profile",
            fallback: PlayerProfile(equippedTitle: nil, equippedGlyphs: [:], isPublic: false,
                                    joinedAt: Date().timeIntervalSince1970 * 1000))
        return saved
    }()
    var checkin:    MorningCheckin       = {
        let saved: MorningCheckin = loadFromDefaults("arena_checkin", fallback: MorningCheckin(date: "", completed: []))
        return saved.date == todayString() ? saved : MorningCheckin(date: todayString(), completed: [])
    }()
    var scheduledBlocks: [ScheduledBlock] = loadFromDefaults("arena_schedule",   fallback: [])
    var deadlines:       [ArenaDeadline]  = loadFromDefaults("arena_deadlines",  fallback: [])

    var activeSession: ActiveSessionState? = nil
    var stackedSessions: [ActiveSessionState] = []
    /// Set when a session expires. Observed by HomeView to trigger completion overlay.
    var pendingCompletion: CompletedSession? = nil

    // Transient UI state (not persisted)
    var expandedArenaId: String? = nil
    var sessionDisplayCollapsed: Bool = false
    var pendingCalSession: PendingCalSession? = nil

    // Tracks the last arena whose identity was broadcast to the Live Activity.
    // Updated by syncLiveActivity() so duplicate pushes are skipped.
    var liveArenaId: String = ""

    var letteredArenas: [Arena] { Arena.reletter(arenas) }
    var todaySessions:  Int    { sessions.filter { $0.date == todayString() }.count }
    /// Computed snapshot of the user's session patterns. Rebuilt on every access.
    /// Don't observe this in tight render loops — call once per session-end event.
    var sessionProfile: SessionProfile { buildSessionProfile(from: sessions, arenas: arenas) }

    // Save helpers
    func saveArenas()      { saveToDefaults("arena_custom_arenas",  arenas) }
    func saveSocialArena() { saveToDefaults("arena_social",         socialArena) }
    func moveArena(from source: IndexSet, to destination: Int) {
        arenas.move(fromOffsets: source, toOffset: destination)
        saveArenas()
    }
    func saveSessions()  { saveToDefaults("arena_sessions",       sessions) }
    func saveHabits()    { saveToDefaults("arena_habits",         habits) }
    func saveHabitLogs() { saveToDefaults("arena_habit_logs",     habitLogs) }
    func saveJournals()  { saveToDefaults("arena_journals",       journals) }
    func saveIdeas()     { saveToDefaults("arena_ideas",          ideas) }
    func saveDockApps()  { saveToDefaults("arena_dock_apps",      dockApps) }
    func saveSettings()  { saveToDefaults("arena_settings",       settings) }
    func saveProtocols() { saveToDefaults("arena_protocols",      protocols) }
    func saveSeenDrops()     { saveToDefaults("arena_seen_drops",      seenDrops) }
    func saveSeenEggDrops()  { saveToDefaults("arena_seen_egg_drops",  seenEggDrops) }
    func saveEggs()          { saveToDefaults("arena_eggs",            eggs) }
    func saveInventory()     { saveToDefaults("arena_inventory",       inventory) }
    func saveRebirthStates() { saveToDefaults("arena_rebirth",         rebirthStates) }
    func saveArenaRanks()    { saveToDefaults("arena_ranks",           arenaRanks) }
    func savePlayerProfile()   { saveToDefaults("arena_profile",        playerProfile) }
    func saveCheckin()         { saveToDefaults("arena_checkin",        checkin) }
    func saveScheduledBlocks() { saveToDefaults("arena_schedule",       scheduledBlocks) }
    func saveDeadlines()       { saveToDefaults("arena_deadlines",      deadlines) }

    // Idle Live Activity — shown on lock screen when no session is active
    #if canImport(ActivityKit)
    func startIdleActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // End any existing idle activities first
        Task {
            for a in Activity<ArenaLiveActivityAttributes>.activities {
                await a.end(nil, dismissalPolicy: .immediate)
            }
        }
        let attrs = ArenaLiveActivityAttributes(
            arenaId: "idle",
            questNote: "",
            startTime: Date()
        )
        let state = ArenaLiveActivityAttributes.ContentState(
            endTime: Date(),
            isPaused: false,
            pausedRemaining: 0,
            isIdle: true,
            arenaLabel: "ARENA PROTOCOL",
            arenaColor: "#E8C547",
            arenaIcon: "◈"
        )
        _ = try? Activity.request(attributes: attrs, content: .init(state: state, staleDate: nil))
    }

    func endIdleActivity() {
        Task {
            for a in Activity<ArenaLiveActivityAttributes>.activities where a.attributes.arenaId == "idle" {
                await a.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    /// Called every second from HomeView's always-running timer.
    /// Detects arena transitions and pushes an updated ContentState to the Live Activity
    /// so the lock screen / Dynamic Island switches arenas even when ActiveSessionView
    /// is not in the view hierarchy (e.g. user is on HomeView or phone is locked).
    func syncLiveActivity(now: Date = Date(), force: Bool = false) {
        let session = activeSession ?? stackedSessions.first
        guard let session else { return }
        guard let cur = session.currentSlot(now: now) else { return }
        guard force || cur.arena.id != liveArenaId else { return }
        liveArenaId = cur.arena.id
        let next = session.nextSlot(now: now)
        let normColor: String = {
            let c = cur.arena.color.trimmingCharacters(in: .whitespacesAndNewlines)
            return c.hasPrefix("#") ? c : "#\(c)"
        }()
        let newState = ArenaLiveActivityAttributes.ContentState(
            endTime: cur.end,
            isPaused: session.isPaused,
            pausedRemaining: session.isPaused ? session.pausedRemaining : 0,
            jointCount: session.jointEntries.count,
            arenaLabel: cur.arena.label,
            arenaColor: normColor,
            arenaIcon: cur.arena.icon.isEmpty ? "◉" : cur.arena.icon,
            currentArenaStart: cur.start,
            sessionEndTime: session.endTime,
            nextArenaLabel: next?.arena.label ?? "",
            nextArenaIcon: next?.arena.icon ?? ""
        )
        Task {
            for activity in Activity<ArenaLiveActivityAttributes>.activities {
                await activity.update(.init(state: newState, staleDate: cur.end))
            }
        }
    }

    /// Schedule background Live Activity updates at each future joint transition time.
    /// Uses `ProcessInfo.performExpiringActivity` to keep the app alive briefly after backgrounding.
    func scheduleLiveActivityTransitions() {
        guard let session = activeSession ?? stackedSessions.first else { return }
        let now = Date()
        let futureTransitions = session.timeline.filter { $0.start > now }
        guard !futureTransitions.isEmpty else { return }

        // Build all future states upfront so we don't reference `self` later
        struct ScheduledUpdate: Sendable {
            let fireAt: Date
            let state: ArenaLiveActivityAttributes.ContentState
            let staleDate: Date
            let arenaId: String
        }

        var scheduledUpdates: [ScheduledUpdate] = []
        let tl = session.timeline
        for (i, slot) in tl.enumerated() where slot.start > now {
            let normColor: String = {
                let c = slot.arena.color.trimmingCharacters(in: .whitespacesAndNewlines)
                return c.hasPrefix("#") ? c : "#\(c)"
            }()
            let next = (i + 1 < tl.count) ? tl[i + 1] : nil
            let st = ArenaLiveActivityAttributes.ContentState(
                endTime: slot.end,
                isPaused: session.isPaused,
                pausedRemaining: session.isPaused ? session.pausedRemaining : 0,
                jointCount: max(0, tl.count - i - 1),
                arenaLabel: slot.arena.label,
                arenaColor: normColor,
                arenaIcon: slot.arena.icon.isEmpty ? "◉" : slot.arena.icon,
                currentArenaStart: slot.start,
                sessionEndTime: session.endTime,
                nextArenaLabel: next?.arena.label ?? "",
                nextArenaIcon: next?.arena.icon ?? ""
            )
            scheduledUpdates.append(ScheduledUpdate(
                fireAt: slot.start,
                state: st,
                staleDate: slot.end,
                arenaId: slot.arena.id
            ))
        }
        let updates = scheduledUpdates

        // Fire transitions in a background-safe expiring activity
        ProcessInfo.processInfo.performExpiringActivity(
            withReason: "Update Live Activity for arena transition"
        ) { expired in
            guard !expired else { return }
            Task { @MainActor in
                for update in updates {
                    let delay = update.fireAt.timeIntervalSinceNow
                    if delay > 0 {
                        try? await Task.sleep(for: .seconds(delay))
                    }
                    for activity in Activity<ArenaLiveActivityAttributes>.activities {
                        await activity.update(.init(state: update.state, staleDate: update.staleDate))
                    }
                }
            }
        }
    }
    #endif

    // Active session lifecycle
    func startSession(arena: Arena, durationMins: Int, note: String, social: Bool = false) {
        let now = Date.now
        activeSession = ActiveSessionState(
            arena: arena,
            durationMins: durationMins,
            note: note,
            startTime: now,
            endTime: now + TimeInterval(durationMins * 60),
            social: social
        )
    }

    func endSession() {
        activeSession = nil
    }

    /// Central session tick — called every second from HomeView's always-running timer
    /// and from ActiveSessionView's own tick. Idempotent: first caller ends the session,
    /// subsequent calls are no-ops because activeSession is already nil.
    func tickSession(now: Date) {
        guard let session = activeSession, !session.isPaused else { return }
        guard session.endTime <= now else { return }
        // Log joint arenas before ending
        for entry in session.jointEntries {
            addSession(Session(
                arenaId: entry.arena.id,
                duration: entry.minutes,
                date: todayString(),
                note: session.note,
                ts: now.timeIntervalSince1970 * 1000,
                social: session.social
            ))
        }
        let completed = CompletedSession(
            arena: session.arena,
            durationMins: session.durationMins,
            note: session.note,
            social: session.social
        )
        endSession()
        pendingCompletion = completed
    }

    func togglePause() {
        guard var s = activeSession else { return }
        if s.isPaused {
            s.endTime = Date().addingTimeInterval(s.pausedRemaining)
            s.isPaused = false
            s.pausedRemaining = 0
        } else {
            s.pausedRemaining = max(0, s.endTime.timeIntervalSinceNow)
            s.isPaused = true
        }
        activeSession = s
    }

    // Move foreground session to stash (allows starting a new session)
    func stashSession() {
        guard let active = activeSession else { return }
        stackedSessions.append(active)
        activeSession = nil
    }

    // Bring a stashed session back to foreground
    func unstashSession(arenaId: String) {
        guard let idx = stackedSessions.firstIndex(where: { $0.arena.id == arenaId }) else { return }
        if let current = activeSession {
            stackedSessions.append(current)
        }
        activeSession = stackedSessions.remove(at: idx)
    }

    // Abandon a specific stashed session without touching the foreground
    func abandonStackedSession(arenaId: String) {
        stackedSessions.removeAll { $0.arena.id == arenaId }
    }

    // Session management
    func addSession(_ s: Session) {
        sessions.append(s)
        saveSessions()
        updateArenaRank(arenaId: s.arenaId)
        checkDeadlineCompletion()
    }

    // MARK: - Arena Rank Management

    func rankState(for arenaId: String) -> ArenaRankState {
        arenaRanks.first(where: { $0.arenaId == arenaId })
            ?? ArenaRankState(arenaId: arenaId, peakStreak: 0, achievedRank: .dormant, achievedAt: 0)
    }

    func updateArenaRank(arenaId: String) {
        let currentStreak = streak(for: arenaId)
        let currentTier = ArenaRankTier.from(streak: currentStreak)
        if let idx = arenaRanks.firstIndex(where: { $0.arenaId == arenaId }) {
            if currentStreak > arenaRanks[idx].peakStreak {
                arenaRanks[idx].peakStreak = currentStreak
            }
            if currentTier > arenaRanks[idx].achievedRank {
                arenaRanks[idx].achievedRank = currentTier
                arenaRanks[idx].achievedAt = Date().timeIntervalSince1970 * 1000
            }
        } else {
            arenaRanks.append(ArenaRankState(
                arenaId: arenaId,
                peakStreak: currentStreak,
                achievedRank: currentTier,
                achievedAt: Date().timeIntervalSince1970 * 1000
            ))
        }
        saveArenaRanks()
    }

    func resetArenaRank(arenaId: String) {
        arenaRanks.removeAll { $0.arenaId == arenaId }
        saveArenaRanks()
    }

    /// Seeds rank states from existing streak data for arenas that have no rank yet.
    /// Call once on app launch so existing users get their earned ranks.
    func seedArenaRanksIfNeeded() {
        var changed = false
        for arena in arenas {
            guard !arenaRanks.contains(where: { $0.arenaId == arena.id }) else { continue }
            let s = streak(for: arena.id)
            guard s > 0 else { continue }
            let tier = ArenaRankTier.from(streak: s)
            arenaRanks.append(ArenaRankState(
                arenaId: arena.id, peakStreak: s, achievedRank: tier,
                achievedAt: Date().timeIntervalSince1970 * 1000
            ))
            changed = true
        }
        if changed { saveArenaRanks() }
    }

    // MARK: - Scheduling

    func addScheduledBlock(_ block: ScheduledBlock) {
        var b = block
        let secsFromNow = b.scheduledAt.timeIntervalSinceNow
        if secsFromNow > 0 {
            let notifId = "sched_\(b.id)"
            let title = b.kind == .arena
                ? "Time for \(b.itemLabel)"
                : "\(b.itemLabel) protocol is starting"
            let body = b.note.isEmpty ? "Your scheduled session is starting now." : b.note
            scheduleNotification(id: notifId, title: title, body: body, secondsFromNow: secsFromNow)
            b.notificationId = notifId
        }
        scheduledBlocks.append(b)
        saveScheduledBlocks()
    }

    func removeScheduledBlock(id: String) {
        if let b = scheduledBlocks.first(where: { $0.id == id }),
           let notifId = b.notificationId {
            cancelNotification(id: notifId)
        }
        scheduledBlocks.removeAll { $0.id == id }
        saveScheduledBlocks()
    }

    func addDeadline(_ d: ArenaDeadline) {
        deadlines.append(d)
        saveDeadlines()
    }

    func removeDeadline(id: String) {
        deadlines.removeAll { $0.id == id }
        saveDeadlines()
    }

    func checkDeadlineCompletion() {
        var changed = false
        for i in deadlines.indices where !deadlines[i].isCompleted {
            let count = sessions.filter { $0.arenaId == deadlines[i].arenaId }.count
            if count >= deadlines[i].targetSessions {
                deadlines[i].isCompleted = true
                changed = true
            }
        }
        if changed { saveDeadlines() }
    }

    // Streak & forge
    func streak(for arenaId: String) -> Int { getStreakForArena(arenaId: arenaId, sessions: sessions) }
    func forgeMark(for arenaId: String) -> ForgeMark? { getForgeMarkForArena(arenaId: arenaId, sessions: sessions) }

    // Ember drop + egg drop
    /// Legacy entry point — still works for callers that only need EmberDrop.
    func checkAndClaimEmberDrop() -> EmberDrop? {
        checkAndClaimForgeResult().narrative
    }

    /// Full forge pipeline: narrative + egg drop + auto-hatch. Returns everything the modal needs.
    func checkAndClaimForgeResult() -> ForgeDropResult {
        let profile     = buildSessionProfile(from: sessions, arenas: arenas)
        let lastSession = sessions.max(by: { $0.ts < $1.ts })
        var result = ForgeDropResult(narrative: nil, eggDrop: nil, hatchedItems: [])

        // 1. Egg drops — independent of narrative
        if let (rarity, triggerId) = ForgeEngine.evaluateEggDrop(
            profile: profile,
            lastSession: lastSession,
            seenEggDropIds: seenEggDrops
        ) {
            seenEggDrops.append(triggerId)
            saveSeenEggDrops()
            addEgg(rarity: rarity, sourceArenaId: lastSession?.arenaId, sourceTrigger: triggerId)
            result.eggDrop = eggs.last
        }

        // 2. Auto-hatch any ready eggs — zero friction, immediate reward
        for egg in eggs where !egg.isHatched && isEggReady(egg) {
            hatchEgg(egg)
            if let reward = inventory.last {
                result.hatchedItems.append(reward)
            }
        }

        // 3. Egg proximity nudge — schedule ambient notification if close to hatching
        checkEggProximityNotification()

        // 4. Forge narratives (personalized, highest priority)
        if let narrative = ForgeEngine.evaluate(
            profile: profile,
            arenas: arenas,
            lastSession: lastSession,
            seenDropIds: seenDrops
        ) {
            let drop = narrative.toEmberDrop()
            seenDrops.append(drop.id)
            saveSeenDrops()
            result.narrative = drop
            // Smart notification: only for significant milestones when app is backgrounded
            scheduleForgeNotificationIfNeeded(narrative: narrative, profile: profile)
            return result
        }

        // 5. Fallback: legacy ember drops
        if let drop = checkEmberDrop(sessions: sessions, seenDrops: seenDrops) {
            seenDrops.append(drop.id)
            saveSeenDrops()
            result.narrative = drop
        }

        return result
    }

    // MARK: - Smart Notifications

    /// Schedule a notification only for significant forge milestones — never spam.
    /// Fires when the app is backgrounded and something meaningful happened.
    private func scheduleForgeNotificationIfNeeded(narrative: ForgeNarrative, profile: SessionProfile) {
        // Only notify on high-value events
        let notifyCategories: Set<ForgeCategory> = [.streak, .milestone, .recovery, .arenaDepth]
        guard notifyCategories.contains(narrative.category) else { return }
        guard narrative.urgency == .drop else { return }

        // Rate limit: max 1 forge notification per day
        let lastNotifKey = "arena_last_forge_notif_date"
        let today = todayString()
        if UserDefaults.standard.string(forKey: lastNotifKey) == today { return }
        UserDefaults.standard.set(today, forKey: lastNotifKey)

        // Schedule for 2 hours later — ambient reminder, not immediate
        scheduleNotification(
            id: "forge_milestone",
            title: "\(narrative.glyph) \(narrative.headline)",
            body: narrative.flavor,
            secondsFromNow: 7200
        )
    }

    // MARK: - Egg & Inventory

    /// Check if any incubating eggs are close to hatching and schedule a single nudge notification.
    /// Called after session completion. Max 1 egg nudge per day, never for eggs with 5+ sessions remaining.
    func checkEggProximityNotification() {
        let nudgedKey = "arena_last_egg_nudge_date"
        let today = todayString()
        guard UserDefaults.standard.string(forKey: nudgedKey) != today else { return }

        for egg in eggs where !egg.isHatched {
            let progress = eggProgress(egg)
            let remaining = egg.hatchThreshold - progress
            // Only nudge when 1-3 sessions away
            guard remaining > 0 && remaining <= 3 else { continue }
            UserDefaults.standard.set(today, forKey: nudgedKey)
            scheduleNotification(
                id: "egg_proximity",
                title: "\(egg.rarity.glyph) \(egg.rarity.displayName) egg is close",
                body: "\(remaining) session\(remaining == 1 ? "" : "s") until it hatches.",
                secondsFromNow: 3600  // 1 hour later — ambient, not immediate
            )
            return  // Only 1 nudge
        }
    }

    /// Schedule a streak-protection notification if the user has a streak ≥3 and hasn't done a session today.
    /// Called on app foreground. Max 1 per day, fires at 8pm local time.
    func checkStreakProtectionNotification() {
        let profile = buildSessionProfile(from: sessions, arenas: arenas)
        guard profile.currentGlobalStreak >= 3 else { return }
        guard todaySessions == 0 else {
            // Already done a session today — cancel any pending streak notification
            cancelNotification(id: "streak_protect")
            return
        }
        let protectKey = "arena_last_streak_protect_date"
        let today = todayString()
        guard UserDefaults.standard.string(forKey: protectKey) != today else { return }
        UserDefaults.standard.set(today, forKey: protectKey)

        // Schedule for 8pm today
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = 20; comps.minute = 0
        guard let target = cal.date(from: comps), target > now else { return }
        let interval = target.timeIntervalSince(now)

        scheduleNotification(
            id: "streak_protect",
            title: "\(profile.currentGlobalStreak)-day streak at risk",
            body: "One session keeps it alive. The arena is waiting.",
            secondsFromNow: interval
        )
    }

    func addEgg(rarity: EggRarity, sourceArenaId: String?, sourceTrigger: String) {
        let egg = InventoryEgg(
            id: UUID().uuidString,
            rarity: rarity,
            droppedAt: Date().timeIntervalSince1970 * 1000,
            sessionCountOnDrop: sessions.count,
            hatchThreshold: rarity.hatchThreshold,
            isHatched: false, rewardId: nil,
            sourceArenaId: sourceArenaId,
            sourceTrigger: sourceTrigger
        )
        eggs.append(egg)
        saveEggs()
    }

    func eggProgress(_ egg: InventoryEgg) -> Int {
        max(0, sessions.count - egg.sessionCountOnDrop)
    }

    func isEggReady(_ egg: InventoryEgg) -> Bool {
        !egg.isHatched && eggProgress(egg) >= egg.hatchThreshold
    }

    func hatchEgg(_ egg: InventoryEgg) {
        guard let idx = eggs.firstIndex(where: { $0.id == egg.id }), !egg.isHatched else { return }
        let reward = _generateHatchReward(rarity: egg.rarity)
        eggs[idx].isHatched = true
        eggs[idx].rewardId = reward.id
        inventory.append(reward)
        saveEggs()
        saveInventory()
    }

    private func _generateHatchReward(rarity: EggRarity) -> InventoryItem {
        let id = UUID().uuidString
        let ts = Date().timeIntervalSince1970 * 1000

        // 40% chance to drop a skin (if one exists for this rarity and isn't already owned)
        let ownedSkinIds = Set(inventory.filter { $0.type == .skin }.map { $0.name })
        let availableSkins = SKIN_CATALOG.filter { $0.rarity == rarity && !ownedSkinIds.contains($0.name) }
        if !availableSkins.isEmpty && Int.random(in: 0..<5) < 2,
           let skin = availableSkins.randomElement() {
            return InventoryItem(id: id, type: .skin, rarity: rarity,
                name: skin.name, description: skin.description,
                glyph: skin.glyph, isEquipped: false, unlockedAt: ts, arenaId: nil)
        }

        switch rarity {
        case .common:
            return InventoryItem(id: id, type: .fragment, rarity: .common,
                name: "FORGE SHARD",
                description: "The first crack in the ore. Something older lives inside.",
                glyph: "▪", isEquipped: false, unlockedAt: ts, arenaId: nil)
        case .uncommon:
            return InventoryItem(id: id, type: .glyph, rarity: .uncommon,
                name: "EMBER MARK",
                description: "An alternate forge glyph. Equip it to a specific arena in your profile.",
                glyph: "❋", isEquipped: false, unlockedAt: ts, arenaId: nil)
        case .rare:
            return InventoryItem(id: id, type: .title, rarity: .rare,
                name: "THE FORGED",
                description: "Earned through the fire. Others would see this title.",
                glyph: "★", isEquipped: false, unlockedAt: ts, arenaId: nil)
        case .epic:
            return InventoryItem(id: id, type: .aura, rarity: .epic,
                name: "ASCENDANT AURA",
                description: "A mark of sustained excellence. Visible on arena cards.",
                glyph: "⬟", isEquipped: false, unlockedAt: ts, arenaId: nil)
        case .legendary:
            return InventoryItem(id: id, type: .title, rarity: .legendary,
                name: "THE UNDYING",
                description: "You've been here longer than most will ever manage.",
                glyph: "✦", isEquipped: false, unlockedAt: ts, arenaId: nil)
        case .echo:
            return InventoryItem(id: id, type: .echo, rarity: .echo,
                name: "ECHO",
                description: "A snapshot of your best day. Preserved.",
                glyph: "◈", isEquipped: false, unlockedAt: ts, arenaId: nil)
        }
    }

    func equipItem(_ item: InventoryItem) {
        // Unequip all items of the same type first
        for i in inventory.indices where inventory[i].type == item.type {
            inventory[i].isEquipped = false
        }
        if let idx = inventory.firstIndex(where: { $0.id == item.id }) {
            inventory[idx].isEquipped = true
            if item.type == .title {
                playerProfile.equippedTitle = item.name
                savePlayerProfile()
            }
        }
        saveInventory()
    }

    func unequipItem(_ item: InventoryItem) {
        if let idx = inventory.firstIndex(where: { $0.id == item.id }) {
            inventory[idx].isEquipped = false
            if item.type == .title {
                playerProfile.equippedTitle = nil
                savePlayerProfile()
            }
        }
        saveInventory()
    }

    func equippedGlyph(for arenaId: String) -> String? {
        playerProfile.equippedGlyphs[arenaId]
    }

    // MARK: - Skin equip

    func equipSkin(_ skinName: String, to arenaId: String) {
        // Unequip this skin from any other arena
        for (aid, name) in playerProfile.equippedSkins where name == skinName && aid != arenaId {
            playerProfile.equippedSkins.removeValue(forKey: aid)
        }
        playerProfile.equippedSkins[arenaId] = skinName
        // Mark item as equipped
        if let idx = inventory.firstIndex(where: { $0.type == .skin && $0.name == skinName }) {
            inventory[idx].isEquipped = true
        }
        savePlayerProfile()
        saveInventory()
    }

    func unequipSkin(from arenaId: String) {
        if let skinName = playerProfile.equippedSkins[arenaId],
           let idx = inventory.firstIndex(where: { $0.type == .skin && $0.name == skinName }) {
            // Only mark unequipped if not assigned to another arena
            let stillUsed = playerProfile.equippedSkins.contains { $0.key != arenaId && $0.value == skinName }
            if !stillUsed { inventory[idx].isEquipped = false }
        }
        playerProfile.equippedSkins.removeValue(forKey: arenaId)
        savePlayerProfile()
        saveInventory()
    }

    func equippedSkin(for arenaId: String) -> ButtonSkin? {
        guard let name = playerProfile.equippedSkins[arenaId] else { return nil }
        return SKIN_CATALOG.first { $0.name == name }
    }

    func rebirthState(for arenaId: String) -> RebirthState? {
        rebirthStates.first { $0.arenaId == arenaId }
    }

    /// Resets an arena's session count and advances its Rebirth Island level.
    /// Requires arenaSessionCounts[arenaId] ≥ 111. Non-reversible — call only after confirmation.
    func rebirthArena(_ arenaId: String) {
        let total = sessions.filter { $0.arenaId == arenaId }.count
        guard total >= 111 else { return }
        if let idx = rebirthStates.firstIndex(where: { $0.arenaId == arenaId }) {
            rebirthStates[idx].islandLevel += 1
            rebirthStates[idx].totalSessionsAllTime += total
            rebirthStates[idx].rebirthDates.append(todayString())
        } else {
            rebirthStates.append(RebirthState(arenaId: arenaId, islandLevel: 1,
                                              totalSessionsAllTime: total, rebirthDates: [todayString()]))
        }
        sessions.removeAll { $0.arenaId == arenaId }
        saveSessions()
        saveRebirthStates()
    }

    // Export CSV
    func exportCSV() -> String {
        var rows = [["Date", "Arena", "Duration (min)", "Quest", "Timestamp"]]
        for s in sessions {
            let arena = letteredArenas.first { $0.id == s.arenaId }
            rows.append([s.date, arena?.label ?? s.arenaId, String(s.duration), s.note,
                         ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: s.ts / 1000))])
        }
        return rows.map { $0.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ",") }.joined(separator: "\n")
    }
}

// MARK: - Notifications

func scheduleNotification(id: String, title: String, body: String, secondsFromNow: TimeInterval) {
    guard secondsFromNow > 0 else { return }
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
        guard granted else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsFromNow, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.removeDeliveredNotifications(withIdentifiers: [id])
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.add(request)
    }
}

func cancelNotification(id: String) {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [id])
    center.removeDeliveredNotifications(withIdentifiers: [id])
}
