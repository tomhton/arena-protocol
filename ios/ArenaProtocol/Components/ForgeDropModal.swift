// ForgeDropModal.swift — Arena Protocol
// Multi-phase reward modal: narrative → egg drop → hatch reveal
// Designed for high action-to-stimulus ratio: every tap advances, nothing blocks.

import SwiftUI

struct ForgeDropModal: View {
    let result: ForgeDropResult
    var onDismiss: () -> Void

    @State private var phase: DropPhase = .narrative
    @State private var phaseAppeared = false
    @State private var glyphScale: CGFloat = 0.3
    @State private var glyphOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var particlePhase: Int = 0

    private enum DropPhase: Int, CaseIterable {
        case narrative   // forge narrative / legacy drop
        case eggDrop     // new egg incubating
        case hatchReveal // auto-hatched item reveal
    }

    // Determine the starting phase based on what's in the result
    private var startPhase: DropPhase {
        if result.narrative != nil { return .narrative }
        if result.eggDrop != nil { return .eggDrop }
        if !result.hatchedItems.isEmpty { return .hatchReveal }
        return .narrative
    }

    // Can we advance to the next phase?
    private var nextPhase: DropPhase? {
        switch phase {
        case .narrative:
            if result.eggDrop != nil { return .eggDrop }
            if !result.hatchedItems.isEmpty { return .hatchReveal }
            return nil
        case .eggDrop:
            if !result.hatchedItems.isEmpty { return .hatchReveal }
            return nil
        case .hatchReveal:
            return nil
        }
    }

    private var currentColor: Color {
        switch phase {
        case .narrative:
            return Color(hex: "#E8C547")
        case .eggDrop:
            if let egg = result.eggDrop {
                return Color(hex: egg.rarity.hexColor)
            }
            return Color(hex: "#E8C547")
        case .hatchReveal:
            if let item = currentHatchItem {
                return Color(hex: item.rarity.hexColor)
            }
            return Color(hex: "#E8C547")
        }
    }

    @State private var hatchIndex: Int = 0
    private var currentHatchItem: InventoryItem? {
        guard !result.hatchedItems.isEmpty, hatchIndex < result.hatchedItems.count else { return nil }
        return result.hatchedItems[hatchIndex]
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(bgOpacity)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            // Shimmer line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, currentColor.opacity(0.15), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .offset(y: shimmerOffset)
                .blur(radius: 1)

            // Content card
            VStack(spacing: 0) {
                switch phase {
                case .narrative:
                    narrativeContent
                case .eggDrop:
                    eggDropContent
                case .hatchReveal:
                    hatchContent
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 36)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#0f0d0a"), Color(hex: "#080810")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(currentColor.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: currentColor.opacity(0.1), radius: 40)
            .padding(24)
            .scaleEffect(glyphScale)
            .opacity(contentOpacity)
        }
        .onTapGesture { advance() }
        .onAppear {
            phase = startPhase
            enterPhase()
        }
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var narrativeContent: some View {
        if let drop = result.narrative {
            VStack(spacing: 0) {
                // Glyph
                Text(drop.glyph)
                    .font(.system(size: 56))
                    .foregroundStyle(currentColor)
                    .shadow(color: currentColor.opacity(0.6), radius: 20)
                    .scaleEffect(phaseAppeared ? 1.0 : 0.5)
                    .opacity(phaseAppeared ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: phaseAppeared)
                    .padding(.bottom, 14)

                // Category label
                Text("FORGE DROP")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(currentColor.opacity(0.5))
                    .kerning(6)
                    .opacity(phaseAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: phaseAppeared)
                    .padding(.bottom, 10)

                // Message
                Text(drop.message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .italic()
                    .opacity(phaseAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: phaseAppeared)
                    .padding(.bottom, 20)

                // Continuation hint
                advanceHint
            }
        }
    }

    @ViewBuilder
    private var eggDropContent: some View {
        if let egg = result.eggDrop {
            let color = Color(hex: egg.rarity.hexColor)
            VStack(spacing: 0) {
                // Egg glyph with pulse
                ZStack {
                    // Pulse ring
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(phaseAppeared ? 1.3 : 0.8)
                        .opacity(phaseAppeared ? 0 : 0.6)
                        .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: phaseAppeared)

                    Text(egg.rarity.glyph)
                        .font(.system(size: 48))
                        .foregroundStyle(color)
                        .shadow(color: color.opacity(0.7), radius: 16)
                        .scaleEffect(phaseAppeared ? 1.0 : 0.4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.55), value: phaseAppeared)
                }
                .padding(.bottom, 14)

                Text("EGG DROP")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(color.opacity(0.6))
                    .kerning(6)
                    .opacity(phaseAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: phaseAppeared)
                    .padding(.bottom, 6)

                Text(egg.rarity.displayName)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .kerning(4)
                    .opacity(phaseAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: phaseAppeared)
                    .padding(.bottom, 8)

                Text("Incubating — \(egg.hatchThreshold) sessions to hatch")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .opacity(phaseAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: phaseAppeared)
                    .padding(.bottom, 20)

                advanceHint
            }
        }
    }

    @ViewBuilder
    private var hatchContent: some View {
        if let item = currentHatchItem {
            let color = Color(hex: item.rarity.hexColor)
            VStack(spacing: 0) {
                // Reveal glyph
                Text(item.glyph)
                    .font(.system(size: 56))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.8), radius: 24)
                    .scaleEffect(phaseAppeared ? 1.0 : 0.2)
                    .rotationEffect(.degrees(phaseAppeared ? 0 : -15))
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: phaseAppeared)
                    .padding(.bottom, 14)

                Text("EGG HATCHED")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(color.opacity(0.6))
                    .kerning(7)
                    .opacity(phaseAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: phaseAppeared)
                    .padding(.bottom, 8)

                Text(item.name)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .kerning(3)
                    .opacity(phaseAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: phaseAppeared)
                    .padding(.bottom, 4)

                Text(item.rarity.displayName)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(color.opacity(0.5))
                    .kerning(4)
                    .opacity(phaseAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.25), value: phaseAppeared)
                    .padding(.bottom, 10)

                Text(item.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .opacity(phaseAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: phaseAppeared)
                    .padding(.bottom, 20)

                // Equip hint for equippable items
                if item.type == .title || item.type == .aura {
                    Text("Equip in Inventory →")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(color.opacity(0.4))
                        .kerning(2)
                        .opacity(phaseAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.4), value: phaseAppeared)
                        .padding(.bottom, 14)
                }

                advanceHint
            }
        }
    }

    // MARK: - Shared Components

    private var advanceHint: some View {
        Group {
            if nextPhase != nil || (phase == .hatchReveal && hatchIndex + 1 < result.hatchedItems.count) {
                Text("TAP TO CONTINUE")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .kerning(3)
            } else {
                Text("TAP TO CLOSE")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.15))
                    .kerning(3)
            }
        }
        .opacity(phaseAppeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.5), value: phaseAppeared)
    }

    // MARK: - Phase transitions

    private func advance() {
        // Multiple hatch items: cycle through them first
        if phase == .hatchReveal && hatchIndex + 1 < result.hatchedItems.count {
            phaseAppeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                hatchIndex += 1
                enterPhase()
            }
            return
        }

        // Advance to next phase
        if let next = nextPhase {
            phaseAppeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                phase = next
                enterPhase()
            }
        } else {
            // Dismiss
            withAnimation(.easeOut(duration: 0.2)) {
                glyphScale = 0.95
                contentOpacity = 0
                bgOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDismiss()
            }
        }
    }

    private func enterPhase() {
        glyphScale = 0.92
        contentOpacity = 0
        phaseAppeared = false

        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            bgOpacity = 0.88
            glyphScale = 1.0
            contentOpacity = 1.0
        }

        // Shimmer sweep
        shimmerOffset = -200
        withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
            shimmerOffset = 200
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            phaseAppeared = true
        }
    }
}
