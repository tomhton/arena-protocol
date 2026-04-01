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
                    switch newPhase {
                    case .active:
                        #if canImport(ActivityKit)
                        if store.activeSession == nil && store.stackedSessions.isEmpty {
                            // Clean up orphaned session activities from crashes / force-quits.
                            Task {
                                for a in Activity<ArenaLiveActivityAttributes>.activities {
                                    guard a.attributes.arenaId != "idle" else { continue }
                                    await a.end(nil, dismissalPolicy: .immediate)
                                }
                            }
                        } else {
                            // Immediately sync Live Activity on foreground return —
                            // picks up any joint transitions that happened while backgrounded.
                            store.syncLiveActivity()
                        }
                        #endif
                        store.checkStreakProtectionNotification()
                        store.seedArenaRanksIfNeeded()

                    case .background:
                        #if canImport(ActivityKit)
                        // Schedule Live Activity updates for upcoming joint transitions
                        // while the app still has background execution time.
                        if store.activeSession != nil || !store.stackedSessions.isEmpty {
                            store.scheduleLiveActivityTransitions()
                        }
                        #endif

                    default:
                        break
                    }
                }
        }
    }
}
