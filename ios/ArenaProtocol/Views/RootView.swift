// RootView.swift — Arena Protocol
// Navigation controller — routes to all screens

import SwiftUI

enum Screen: Hashable {
    case home
    case checkin
    case select(Arena)
    case active(Arena, Int, String)   // arena, durationMins, note
    case complete(Arena, Int, String) // arena, durationMins, note
    case protocols
    case activeProtocol(ArenaProtocolModel)
    case history
    case notes
    case winddown
    case habits
    case settings
    case arenaEditor
    case editArena(Arena)
    case newArena
    case stuck
}

struct RootView: View {
    @Environment(DataStore.self) private var store
    @State private var screen: Screen = .checkin
    @State private var screenStack: [Screen] = []
    @State private var pendingDrop: EmberDrop? = nil
    @State private var checkinDismissed: Bool = {
        UserDefaults.standard.string(forKey: "arena_checkin_dismissed") == todayString()
    }()

    var body: some View {
        ZStack {
            Color(hex: "#080810").ignoresSafeArea()
            GrainOverlay()

            Group {
                switch screen {
                case .home:
                    HomeView(navigate: navigate, pendingDrop: $pendingDrop)
                case .checkin:
                    MorningCheckinView(
                        onComplete: { count in
                            UserDefaults.standard.set(todayString(), forKey: "arena_checkin_dismissed")
                            navigate(.home)
                        },
                        onSkip: {
                            UserDefaults.standard.set(todayString(), forKey: "arena_checkin_dismissed")
                            navigate(.home)
                        }
                    )
                case .select(let arena):
                    SelectView(arena: arena, navigate: navigate)
                case .active(let arena, let duration, let note):
                    ActiveSessionView(arena: arena, duration: duration, note: note, navigate: navigate)
                case .complete(let arena, let duration, let note):
                    CompleteView(arena: arena, duration: duration, note: note) {
                        let s = Session(arenaId: arena.id, duration: duration,
                                        date: todayString(), note: note, ts: Date().timeIntervalSince1970 * 1000)
                        store.addSession(s)
                        pendingDrop = store.checkAndClaimEmberDrop()
                        navigate(.home)
                    }
                case .protocols:
                    ProtocolsView(navigate: navigate)
                case .activeProtocol(let proto):
                    ActiveProtocolView(protocol: proto) { blocks in
                        for b in blocks {
                            let s = Session(arenaId: b.arenaId, duration: b.duration,
                                            date: todayString(), note: "Protocol: \(proto.name)",
                                            ts: Date().timeIntervalSince1970 * 1000)
                            store.addSession(s)
                        }
                        pendingDrop = store.checkAndClaimEmberDrop()
                        navigate(.home)
                    } onAbandon: { navigate(.home) }
                case .history:
                    HistoryView(navigate: navigate)
                case .notes:
                    NotesView(navigate: navigate)
                case .winddown:
                    WindDownView(navigate: navigate)
                case .habits:
                    HabitManagerView(navigate: navigate)
                case .settings:
                    SettingsView(navigate: navigate)
                case .arenaEditor:
                    ArenaListEditorView(navigate: navigate)
                case .editArena(let arena):
                    ArenaEditorView(arena: arena, navigate: navigate)
                case .newArena:
                    ArenaEditorView(arena: nil, navigate: navigate)
                case .stuck:
                    StuckView(navigate: navigate)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: "\(screen)")
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    guard value.startLocation.x < 44,
                          value.translation.width > 60,
                          swipeBackEnabled else { return }
                    navigateBack()
                },
            including: swipeBackEnabled ? .all : .none
        )
        .onAppear {
            if UserDefaults.standard.string(forKey: "arena_checkin_dismissed") == todayString() {
                screen = .home
            } else {
                screen = .checkin
            }
        }
        .onOpenURL { url in
            guard url.scheme == "arenaprotocol", url.host == "active",
                  let session = store.activeSession else { return }
            screen = .active(session.arena, session.durationMins, session.note)
        }
    }

    private var swipeBackEnabled: Bool {
        switch screen {
        case .home, .active, .complete:
            return false
        default:
            return true
        }
    }

    func navigate(_ s: Screen) {
        if case .home = s {
            screenStack.removeAll()
        } else {
            screenStack.append(screen)
        }
        screen = s
    }

    func navigateBack() {
        screen = screenStack.popLast() ?? .home
    }
}

// MARK: - Grain Overlay

struct GrainOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                // lightweight noise effect
                for _ in 0..<Int(size.width * size.height / 800) {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let r = CGRect(x: x, y: y, width: 1, height: 1)
                    ctx.fill(Path(r), with: .color(.white.opacity(Double.random(in: 0.01...0.04))))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .opacity(0.35)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

}

extension Color {
    static let background = Color(hex: "#080810")
    static let textPrimary = Color(hex: "#E8E8E8")
    static let textMuted   = Color.white.opacity(0.35)
    static let cardBg      = Color.white.opacity(0.03)
    static let cardBorder  = Color.white.opacity(0.07)
}
