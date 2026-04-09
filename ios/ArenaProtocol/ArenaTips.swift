// ArenaTips.swift — Arena Protocol
// TipKit tips for discoverable hidden features.

import TipKit

struct ProtocolReorderTip: Tip {
    var title: Text { Text("Reorder Protocols") }
    var message: Text? { Text("Press and hold any protocol to activate drag-and-drop reordering.") }
    var image: Image? { Image(systemName: "arrow.up.arrow.down") }
}

struct ChecklistTabTip: Tip {
    var title: Text { Text("Checklist") }
    var message: Text? { Text("Tap or drag the tab to open your task checklist. Scope tasks by session, day, week, month, or year.") }
    var image: Image? { Image(systemName: "checklist") }
}

struct SiriShortcutsTip: Tip {
    var title: Text { Text("Siri & Shortcuts") }
    var message: Text? { Text("Say \"Start [Arena] in Arena Protocol\" or add arena actions to your Shortcuts.") }
    var image: Image? { Image(systemName: "wand.and.stars") }

    var rules: [Rule] {
        #Rule(Self.$hasCompletedSession) { $0 == true }
    }

    @Parameter
    static var hasCompletedSession: Bool = false
}
