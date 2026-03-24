// CompletionOverlay.swift — Arena Protocol
// Full-screen session completion overlay (ZStack, not navigation push)

import SwiftUI

struct CompletionOverlay: View {
    let arena: Arena
    let duration: Int
    let note: String
    var onDone: () -> Void

    private var arenaColor: Color { Color(hex: arena.color) }

    var body: some View {
        ZStack {
            Color(hex: "#080810").ignoresSafeArea()

            RadialGradient(
                colors: [arenaColor.opacity(0.15), Color.clear],
                center: .top, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text(arena.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(arenaColor)
                    .shadow(color: arenaColor, radius: 20)
                    .transition(.scale)

                VStack(spacing: 8) {
                    Text("SESSION COMPLETE")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(7)
                    Text(arena.label)
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .foregroundStyle(arenaColor)
                        .kerning(3)
                    Text("\(duration) MINUTES")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .kerning(3)
                    if !note.isEmpty {
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .italic()
                    }
                }

                Button(action: onDone) {
                    Text("DONE")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(5)
                        .frame(maxWidth: 320)
                        .padding(.vertical, 18)
                        .background(arenaColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: arenaColor.opacity(0.4), radius: 20)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear { cancelNotification(id: "session_1") }
    }
}
