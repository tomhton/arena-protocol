// AppShortcutsBar.swift — Arena Protocol
// Quick-launch bar for Spotify, Audible, Health, YouTube, Notes, Calendar

import SwiftUI

struct AppShortcut {
    let id: String
    let label: String
    let color: String
    let deepLink: String
    let fallback: String
    let sfSymbol: String
}

let APP_SHORTCUTS: [AppShortcut] = [
    AppShortcut(id: "spotify",  label: "Spotify",  color: "#1DB954", deepLink: "spotify://",         fallback: "https://open.spotify.com",         sfSymbol: "music.note"),
    AppShortcut(id: "audible",  label: "Audible",  color: "#F47920", deepLink: "audible://",         fallback: "https://www.audible.com",           sfSymbol: "headphones"),
    AppShortcut(id: "health",   label: "Health",   color: "#FF2D55", deepLink: "x-apple-health://",  fallback: "https://www.apple.com/ios/health/", sfSymbol: "heart.fill"),
    AppShortcut(id: "youtube",  label: "YouTube",  color: "#FF0000", deepLink: "youtube://",         fallback: "https://youtube.com",               sfSymbol: "play.rectangle.fill"),
    AppShortcut(id: "notes",    label: "Notes",    color: "#FFD60A", deepLink: "mobilenotes://",     fallback: "https://icloud.com/notes",          sfSymbol: "note.text"),
    AppShortcut(id: "calendar", label: "Cal",      color: "#1C7ED6", deepLink: "calshow://",         fallback: "https://calendar.google.com",       sfSymbol: "calendar")
]

struct AppShortcutsBar: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(APP_SHORTCUTS, id: \.id) { app in
                ShortcutButton(app: app)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct ShortcutButton: View {
    let app: AppShortcut
    @State private var isPressed = false

    var body: some View {
        Button(action: launchApp) {
            VStack(spacing: 3) {
                Image(systemName: app.sfSymbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: app.color))
                    .shadow(color: Color(hex: app.color).opacity(0.5), radius: 4)
                Text(app.label.prefix(6).uppercased())
                    .font(.system(size: 6, design: .monospaced))
                    .foregroundStyle(Color(hex: app.color).opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Color(hex: app.color).opacity(isPressed ? 0.22 : 0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(hex: app.color).opacity(isPressed ? 0.55 : 0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }

    private func launchApp() {
        guard let deepURL = URL(string: app.deepLink),
              let fallbackURL = URL(string: app.fallback) else { return }
        if UIApplication.shared.canOpenURL(deepURL) {
            UIApplication.shared.open(deepURL)
        } else {
            UIApplication.shared.open(fallbackURL)
        }
    }
}
