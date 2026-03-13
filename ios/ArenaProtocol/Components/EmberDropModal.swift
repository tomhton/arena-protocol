// EmberDropModal.swift — Arena Protocol
// Achievement/reward popup overlay

import SwiftUI

struct EmberDropModal: View {
    let drop: EmberDrop
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Text(drop.glyph)
                    .font(.system(size: 64))
                    .foregroundStyle(Color(hex: "#E8C547"))
                    .shadow(color: Color(hex: "#E8C547").opacity(0.5), radius: 24)
                    .padding(.bottom, 16)

                Text("EMBER DROP")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color(hex: "#E8C547").opacity(0.6))
                    .kerning(6)
                    .padding(.bottom, 10)

                Text(drop.message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .italic()
                    .padding(.bottom, 28)

                Text("TAP TO CONTINUE")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .kerning(3)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 40)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#0f0d0a"), Color(hex: "#080810")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color(hex: "#E8C547").opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color(hex: "#E8C547").opacity(0.12), radius: 60)
            .padding(24)
            .transition(.scale.combined(with: .opacity))
        }
        .onTapGesture { onDismiss() }
    }
}
