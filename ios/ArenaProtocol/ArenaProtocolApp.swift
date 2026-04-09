// ArenaProtocolApp.swift — Arena Protocol
// App entry point — iOS 26 / Swift 6

import SwiftUI
import UserNotifications
import TipKit
#if canImport(ActivityKit)
import ActivityKit
#endif
import WidgetKit

@main
struct ArenaProtocolApp: App {
    @State private var store = DataStore()
    @Environment(\.scenePhase) private var scenePhase
    private let notificationDelegate: CalendarNotificationDelegate

    init() {
        let delegate = CalendarNotificationDelegate()
        self.notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
        Self.registerNotificationCategories()
        try? Tips.configure([.displayFrequency(.weekly)])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
                .onAppear { notificationDelegate.store = store }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        #if canImport(ActivityKit)
                        if store.activeSession == nil && store.stackedSessions.isEmpty {
                            Task {
                                for a in Activity<ArenaLiveActivityAttributes>.activities {
                                    guard a.attributes.arenaId != "idle" else { continue }
                                    await a.end(nil, dismissalPolicy: .immediate)
                                }
                            }
                        } else {
                            store.syncLiveActivity()
                        }
                        #endif
                        store.checkStreakProtectionNotification()
                        store.seedArenaRanksIfNeeded()

                        // Sync arena list to App Group for Shortcuts + Control Center
                        syncArenasToSharedStore()

                        // Consume pending Shortcut intents
                        consumePendingIntent()
                        consumePendingChecklistTask()

                        // Sync bracket-prefixed calendar events for auto-start
                        if store.settings.calendarAutoStart {
                            CalendarSyncManager.shared.cleanupOldEntries()
                            _ = CalendarSyncManager.shared.syncBracketEvents(
                                arenas: store.letteredArenas,
                                socialArena: store.socialArena
                            )
                        }

                    case .background:
                        #if canImport(ActivityKit)
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

    private func syncArenasToSharedStore() {
        let shared = store.letteredArenas.map {
            SharedArena(id: $0.id, label: $0.label, icon: $0.icon, color: $0.color)
        }
        SharedStore.writeArenas(shared)
    }

    private func consumePendingIntent() {
        guard let pending = SharedStore.readPendingIntent() else { return }
        SharedStore.clearPendingIntent()
        guard store.activeSession == nil else { return }
        guard let arena = store.letteredArenas.first(where: { $0.id == pending.arenaId }) else { return }
        store.startSession(arena: arena, durationMins: pending.duration, note: pending.note)
        let endTime = Date().addingTimeInterval(TimeInterval(pending.duration * 60))
        SharedStore.writeActiveSession(arenaName: arena.label, arenaColor: arena.color, endsAt: endTime)
        WidgetCenter.shared.reloadAllTimelines()
        scheduleNotification(id: "session_1", title: "\(arena.label) session complete",
                             body: "Your focus block has ended.",
                             secondsFromNow: TimeInterval(pending.duration * 60))
    }

    private func consumePendingChecklistTask() {
        guard let text = SharedStore.readPendingChecklistTask() else { return }
        SharedStore.clearPendingChecklistTask()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let key = Checklist.periodKey(for: .day)
        if var existing = store.checklist(for: .day, sessionId: nil) {
            existing.items.append(ChecklistItem(text: trimmed))
            store.upsertChecklist(existing)
        } else {
            let cl = Checklist(scope: .day, periodKey: key,
                               items: [ChecklistItem(text: trimmed)],
                               createdAt: Date().timeIntervalSince1970 * 1000)
            store.upsertChecklist(cl)
        }
    }

    private static func registerNotificationCategories() {
        let startAction = UNNotificationAction(
            identifier: "START_SESSION",
            title: "Start Session",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: "CALENDAR_SESSION",
            actions: [startAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

// MARK: - Notification Delegate

/// Handles taps on calendar session notifications to auto-start arena sessions.
final class CalendarNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    var store: DataStore?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let content = response.notification.request.content
        guard content.categoryIdentifier == "CALENDAR_SESSION" else { return }

        let userInfo = content.userInfo
        guard let arenaId = userInfo["arenaId"] as? String,
              let durationMins = userInfo["durationMins"] as? Int,
              let eventId = userInfo["eventId"] as? String else { return }
        let note = userInfo["note"] as? String ?? ""

        // Mark as processed regardless of action
        await MainActor.run {
            CalendarSyncManager.shared.markProcessed(eventId)
        }

        // Only start session on default tap or explicit START action
        let actionId = response.actionIdentifier
        guard actionId == UNNotificationDefaultActionIdentifier
           || actionId == "START_SESSION" else { return }

        await MainActor.run {
            guard let store = self.store else { return }
            // Don't auto-start if a session is already running
            guard store.activeSession == nil else {
                store.pendingCalSession = nil
                return
            }
            guard let arena = store.letteredArenas.first(where: { $0.id == arenaId })
                              ?? (store.socialArena.id == arenaId ? store.socialArena : nil)
            else { return }

            // Start the session using the same flow as HomeView.launchSession
            scheduleNotification(id: "session_1", title: "\(arena.label) session complete",
                                 body: "Your focus block has ended.",
                                 secondsFromNow: TimeInterval(durationMins * 60))
            #if canImport(ActivityKit)
            store.endIdleActivity()
            #endif
            store.startSession(arena: arena, durationMins: durationMins, note: note)

            let endTime = Date().addingTimeInterval(TimeInterval(durationMins * 60))
            SharedStore.writeActiveSession(arenaName: arena.label, arenaColor: arena.color, endsAt: endTime)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Show notifications even when app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
