// WhatsNewView.swift — Arena Protocol
// In-app changelog. Shows recent version entries.

import SwiftUI

private struct VersionEntry: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let headline: String
    let bullets: [String]
}

private let CHANGELOG: [VersionEntry] = [
    VersionEntry(
        version: "v2.6.0", date: "Mar 18, 2026",
        headline: "Google Calendar read feed",
        bullets: [
            "NEXT BLOCK banner on home screen — shows upcoming calendar events within 90 min",
            "FROM YOUR CALENDAR section in SelectView — tap any event to pre-fill quest + duration",
            "Arena matching: gym/run → Health, meeting/sync → Connection, plan/review → Alignment, build/code → Execution",
            "Settings: full-access vs write-only calendar state shown distinctly",
        ]
    ),
    VersionEntry(
        version: "v2.5.0", date: "Mar 17, 2026",
        headline: "EventKit calendar + end time on timers",
        bullets: [
            "Arena Protocol calendar created in iOS Calendar app (syncs to Google Calendar if connected)",
            "Every session start and joint arena logs a focus block event automatically",
            "\"ends 4:22 PM PST\" shown below every active timer ring",
            "Settings: Clock Timezone picker (Device / Pacific / Mountain / Central / Eastern / UTC)",
        ]
    ),
    VersionEntry(
        version: "v2.4.0", date: "Mar 17, 2026",
        headline: "New default arenas + expanded editor",
        bullets: [
            "Default arenas: Alignment & Planning, Execution & Mastery, Health & Recovery, Connection & Community",
            "Arena editor: free-text/emoji icon input — type any character",
            "Expanded icon grid with focus, health, connection, and misc emojis",
            "Sub-arenas editor: add/remove/rename categories with example tasks per category",
        ]
    ),
    VersionEntry(
        version: "v2.3.0", date: "Mar 17, 2026",
        headline: "Multi-timer brainwork + interval periods",
        bullets: [
            "Arena breakdown card: proportional time bars, labeled rows, × remove, ADD ARENA in card",
            "Joint arena picker: arena chips + duration presets + confirm. Same arena can be added multiple times",
            "Mindless interval periods row on home screen: FLOW, DRIFT, WALK, BREATHE, REST, RESET",
            "IntervalTimerView: no-arena countdown with ring, pause/resume, auto-pops home",
        ]
    ),
    VersionEntry(
        version: "v2.2.0", date: "Mar 17, 2026",
        headline: "Joint arenas · drag-to-reorder · color wheel",
        bullets: [
            "Add a second (or third) arena mid-session — the ring sweeps an angular gradient through all arena colors",
            "Drag to reorder arena tiles in the arena editor",
            "Color wheel above preset swatches in arena editor for full HSB customization",
        ]
    ),
    VersionEntry(
        version: "v2.1.0", date: "Mar 17, 2026",
        headline: "Full SwiftUI navigation reform",
        bullets: [
            "NavigationStack replaces ZStack+switch — native iOS slide transitions everywhere",
            "Scroll works on every page (was broken by root gesture conflict)",
            "Swipe-back from left edge restored on all screens",
            "Dynamic Island compact ring now shows live countdown number",
        ]
    ),
]

struct WhatsNewView: View {
    var navigate: (Screen) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button { navigate(.home) } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 52)
                .padding(.bottom, 28)

                Text("RELEASE NOTES")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 4)
                Text("WHAT'S NEW")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .kerning(2)
                    .padding(.bottom, 28)

                ForEach(CHANGELOG) { entry in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(entry.version)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: "#E8C547"))
                                .kerning(1)
                            Text(entry.date)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.25))
                        }
                        Text(entry.headline)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .kerning(1)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(entry.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("·")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(Color(hex: "#E8C547").opacity(0.6))
                                        .padding(.top, 1)
                                    Text(bullet)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.white.opacity(0.55))
                                        .lineSpacing(3)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.02))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 12)
                }
            }
            .padding(.horizontal, 22)
        }
    }
}
