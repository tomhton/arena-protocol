// ArenaProtocolApp.swift — Arena Protocol
// App entry point — iOS 26 / Swift 6

import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@main
struct ArenaProtocolApp: App {
    @State private var store = DataStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    #if canImport(ActivityKit)
                    // Clean up orphaned session activities from crashes / force-quits.
                    // Idle activities are intentional — leave them alone.
                    if store.activeSession == nil && store.stackedSessions.isEmpty {
                        Task {
                            for a in Activity<ArenaLiveActivityAttributes>.activities {
                                guard a.attributes.arenaId != "idle" else { continue }
                                await a.end(nil, dismissalPolicy: .immediate)
                            }
                        }
                    }
                    #endif
                    // Smart notifications — check on every foreground
                    store.checkStreakProtectionNotification()
                    // Seed arena ranks from existing streak data on first launch
                    store.seedArenaRanksIfNeeded()
                }
        }
    }
}
