// ArenaAppIntents.swift — Arena Protocol
// App Intents for Siri and Shortcuts integration.

import AppIntents
import Foundation
import WidgetKit

// MARK: - Arena Entity (for Shortcuts parameter picker)

struct ArenaEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Arena")
    static let defaultQuery = ArenaEntityQuery()

    var id: String
    var label: String
    var icon: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(label)", subtitle: "\(icon)")
    }
}

struct ArenaEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ArenaEntity] {
        SharedStore.readArenas().filter { identifiers.contains($0.id) }
            .map { ArenaEntity(id: $0.id, label: $0.label, icon: $0.icon) }
    }

    func suggestedEntities() async throws -> [ArenaEntity] {
        SharedStore.readArenas()
            .map { ArenaEntity(id: $0.id, label: $0.label, icon: $0.icon) }
    }
}

// MARK: - Start Arena Intent

struct StartArenaIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Arena Session"
    static let description = IntentDescription("Start a timed focus session for an arena.")
    static let openAppWhenRun = true

    @Parameter(title: "Arena")
    var arena: ArenaEntity

    @Parameter(title: "Duration (minutes)", default: 30)
    var durationMinutes: Int

    @Parameter(title: "Note", default: "")
    var note: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Write pending intent to shared store so the app picks it up on launch
        SharedStore.writePendingIntent(arenaId: arena.id, duration: durationMinutes, note: note)
        return .result(dialog: "Starting \(arena.label) for \(durationMinutes) minutes.")
    }
}

// MARK: - Add Checklist Task Intent

struct AddChecklistTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Checklist Task"
    static let description = IntentDescription("Add a task to your daily Arena checklist.")
    static let openAppWhenRun = false

    @Parameter(title: "Task")
    var taskText: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SharedStore.writePendingChecklistTask(taskText)
        return .result(dialog: "Added \"\(taskText)\" to today's checklist.")
    }
}

// MARK: - Shortcuts Provider

struct ArenaShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartArenaIntent(),
            phrases: [
                "Start \(\.$arena) in \(.applicationName)",
                "Start \(\.$arena) session in \(.applicationName)",
                "Begin \(\.$arena) focus in \(.applicationName)"
            ],
            shortTitle: "Start Arena",
            systemImageName: "flame.fill"
        )
        AppShortcut(
            intent: AddChecklistTaskIntent(),
            phrases: [
                "Add a task to my \(.applicationName) checklist",
                "New checklist task in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "checklist"
        )
    }
}
