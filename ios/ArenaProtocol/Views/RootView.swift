// RootView.swift — Arena Protocol
// NavigationStack-based router. Replaces the old ZStack+switch pattern.

import SwiftUI

// MARK: - Screen enum

enum Screen: Hashable {
    case home       // not a destination — navigate(.home) always pops to root
    case checkin
    case select(Arena)
    case active(Arena, Int, String)          // arena, durationMins, note
    case complete(Arena, Int, String)        // arena, durationMins, note
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

// MARK: - Root

struct RootView: View {
    @Environment(DataStore.self) private var store
    @State private var pendingDrop: EmberDrop? = nil

    // Initial path: push checkin if not yet dismissed today
    @State private var path: NavigationPath = {
        if UserDefaults.standard.string(forKey: "arena_checkin_dismissed") == todayString() {
            return NavigationPath()
        }
        var p = NavigationPath()
        p.append(Screen.checkin)
        return p
    }()

    var body: some View {
        ZStack {
            Color(hex: "#080810").ignoresSafeArea()

            NavigationStack(path: $path) {
                HomeView(navigate: navigate, pendingDrop: $pendingDrop)
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: Screen.self) { screen in
                        destination(for: screen)
                            .toolbar(.hidden, for: .navigationBar)
                    }
            }

            GrainOverlay()
        }
        .onOpenURL { url in
            guard url.scheme == "arenaprotocol",
                  url.host == "active",
                  let session = store.activeSession else { return }
            path = NavigationPath()
            path.append(Screen.active(session.arena, session.durationMins, session.note))
        }
    }

    // MARK: - Destination builder

    @ViewBuilder
    private func destination(for screen: Screen) -> some View {
        switch screen {
        case .home:
            HomeView(navigate: navigate, pendingDrop: $pendingDrop)
        case .checkin:
            MorningCheckinView(
                onComplete: { _ in
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
                .navigationBarBackButtonHidden(true)
        case .complete(let arena, let duration, let note):
            CompleteView(arena: arena, duration: duration, note: note) {
                let s = Session(arenaId: arena.id, duration: duration,
                                date: todayString(), note: note,
                                ts: Date().timeIntervalSince1970 * 1000)
                store.addSession(s)
                pendingDrop = store.checkAndClaimEmberDrop()
                navigate(.home)
            }
            .navigationBarBackButtonHidden(true)
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
            .navigationBarBackButtonHidden(true)
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
            ArenaEditorView(arena: arena)
        case .newArena:
            ArenaEditorView(arena: nil)
        case .stuck:
            StuckView(navigate: navigate)
        }
    }

    // MARK: - Navigation

    func navigate(_ s: Screen) {
        switch s {
        case .home:
            path = NavigationPath()
        default:
            path.append(s)
        }
    }

    // Convenience alias — some views call this to go back one level
    func navigateBack() {
        if !path.isEmpty { path.removeLast() }
    }
}

// MARK: - Grain Overlay

struct GrainOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
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

// MARK: - Color extensions

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
    static let background  = Color(hex: "#080810")
    static let textPrimary = Color(hex: "#E8E8E8")
    static let textMuted   = Color.white.opacity(0.35)
    static let cardBg      = Color.white.opacity(0.03)
    static let cardBorder  = Color.white.opacity(0.07)
}

