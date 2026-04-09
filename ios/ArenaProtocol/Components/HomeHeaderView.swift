// HomeHeaderView.swift — Arena Protocol
// Header section extracted from HomeView: hero title + subtitle row

import SwiftUI

struct HomeHeaderView: View {
    @Environment(DataStore.self) private var store
    let hasSession: Bool

    private var arenas: [Arena] { store.letteredArenas }
    private var sessions: [Session] { store.sessions }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        fmt.timeZone = TimeZone(identifier: store.settings.clockTimezone) ?? .current
        return fmt.string(from: Date()).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !hasSession {
                // Date line
                Text(formattedDate)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .kerning(4)
                    .padding(.bottom, 4)
                // Hero title
                Text("ENTER THE")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(hex: "#E8C547").opacity(0.65))
                    .kerning(8)
                    .padding(.bottom, 4)
                Text("ARENA")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#E8C547"), Color(hex: "#F0D96B")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .kerning(6)
                    .shadow(color: Color(hex: "#E8C547").opacity(0.3), radius: 20, y: 4)
                    .padding(.bottom, 6)
                // Rotating motivational quote
                Text(todayQuote(sessionCount: store.todaySessions).text)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .italic()
                    .foregroundStyle(Color.white.opacity(0.55))
                    .padding(.bottom, 10)
            } else {
                Text("ARENA PROTOCOL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.15))
                    .kerning(6)
                    .padding(.bottom, 6)
            }

            // Subtitle row — title + session count
            HStack(spacing: 12) {
                if let title = getActiveTitle(sessions: sessions) {
                    let titleColor = title.arenaId != nil
                        ? Color(hex: arenas.first { $0.id == title.arenaId }?.color ?? "#E8C547")
                        : Color(hex: "#E8C547")
                    Text(title.label)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(titleColor.opacity(0.75))
                        .kerning(4)
                }
                if store.todaySessions > 0 {
                    Text("● \(store.todaySessions) SESSION\(store.todaySessions != 1 ? "S" : "") TODAY")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(3)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
