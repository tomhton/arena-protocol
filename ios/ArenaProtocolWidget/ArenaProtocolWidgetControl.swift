// ArenaProtocolWidgetControl.swift — Arena Protocol
// Control Center widget — quick-start your most recent arena session.

import AppIntents
import SwiftUI
import WidgetKit

struct ArenaProtocolWidgetControl: ControlWidget {
    static let kind = "com.arenaprotocol.app.ArenaControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: ArenaControlProvider()
        ) { value in
            ControlWidgetToggle(
                value.isRunning ? value.arenaName : "Start Arena",
                isOn: value.isRunning,
                action: ToggleArenaIntent(arenaName: value.arenaName)
            ) { isRunning in
                Label(isRunning ? value.arenaName : "Arena", systemImage: isRunning ? "flame.fill" : "flame")
                    .tint(isRunning ? .orange : .gray)
            }
        }
        .displayName("Arena Session")
        .description("Quick-start your last arena from Control Center.")
    }
}

// MARK: - Control Value

extension ArenaProtocolWidgetControl {
    struct Value {
        var isRunning: Bool
        var arenaName: String
    }
}

struct ArenaControlProvider: AppIntentControlValueProvider {
    func previewValue(configuration: ArenaControlConfiguration) -> ArenaProtocolWidgetControl.Value {
        .init(isRunning: false, arenaName: configuration.arenaName)
    }

    func currentValue(configuration: ArenaControlConfiguration) async throws -> ArenaProtocolWidgetControl.Value {
        let state = SharedStore.readWidgetState()
        let isRunning = state.activeArenaName != nil && state.timerEndsAt.map { $0 > Date() } ?? false
        let name = state.activeArenaName ?? configuration.arenaName
        return .init(isRunning: isRunning, arenaName: name)
    }
}

// MARK: - Configuration

struct ArenaControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Arena Selection"

    @Parameter(title: "Arena Name", default: "Focus")
    var arenaName: String
}

// MARK: - Toggle Intent

struct ToggleArenaIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Toggle Arena Session"

    @Parameter(title: "Arena Name")
    var arenaName: String

    @Parameter(title: "Session active")
    var value: Bool

    init() {
        self.arenaName = "Focus"
        self.value = false
    }

    init(arenaName: String) {
        self.arenaName = arenaName
        self.value = false
    }

    func perform() async throws -> some IntentResult {
        if value {
            // Starting — find arena by name, write pending intent for app to consume
            let arenas = SharedStore.readArenas()
            if let match = arenas.first(where: { $0.label.localizedCaseInsensitiveContains(arenaName) })
                ?? arenas.first {
                SharedStore.writePendingIntent(arenaId: match.id, duration: 30, note: "")
            }
        } else {
            // Stopping — clear active session in widget state
            SharedStore.clearActiveSession()
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
