// ArenaProtocolApp.swift — Arena Protocol
// App entry point — iOS 26 / Swift 6

import SwiftUI

@main
struct ArenaProtocolApp: App {
    @State private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}
