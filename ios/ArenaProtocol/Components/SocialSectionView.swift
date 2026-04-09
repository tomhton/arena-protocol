// SocialSectionView.swift — Arena Protocol
// Social toggle + social-only session button + edit access, extracted from HomeView

import SwiftUI

struct SocialSectionView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void
    @Binding var socialActive: Bool
    @Binding var hapticLight: Int

    private let socialColor = Color(hex: "#B794F4")

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                // Toggle row
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { socialActive.toggle() }
                    hapticLight += 1
                } label: {
                    HStack(spacing: 10) {
                        Text(store.socialArena.icon.isEmpty ? "🤝" : store.socialArena.icon)
                            .font(.system(size: 14))
                        Text(store.socialArena.label.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(socialActive ? socialColor : Color.white.opacity(0.35))
                            .kerning(4)
                        Spacer()
                        ZStack {
                            Capsule()
                                .fill(socialActive ? socialColor.opacity(0.6) : Color.white.opacity(0.06))
                                .frame(width: 36, height: 20)
                            Circle().fill(socialActive ? .white : Color.white.opacity(0.3))
                                .frame(width: 14, height: 14)
                                .offset(x: socialActive ? 8 : -8)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                // Edit button
                Button { navigate(.editArena(store.socialArena)) } label: {
                    Text("EDIT")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(socialColor.opacity(0.55))
                        .kerning(2)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(socialColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 14)
            }
            .background(socialActive ? socialColor.opacity(0.06) : Color.white.opacity(0.02))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(socialActive ? socialColor.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if socialActive {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        store.expandedArenaId = store.socialArena.id
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("SOCIAL ONLY SESSION →")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(socialColor).kerning(2)
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(socialColor.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(socialColor.opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .padding(.horizontal, 12)
    }
}
