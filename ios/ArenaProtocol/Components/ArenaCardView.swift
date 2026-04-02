// ArenaCardView.swift — Arena Protocol
// Native SwiftUI arena card with illustrations and forge marks

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ArenaCardView: View {
    @Environment(DataStore.self) private var store
    let arena: Arena
    let sessCount: Int          // sessions today for this arena
    let streak: Int             // consecutive day streak
    let rankTier: ArenaRankTier // locked-in rank from peak streak
    let editMode: Bool
    var onTap: () -> Void
    var sessions: [Session] = []

    @State private var isPressed = false
    @State private var glowPhase: CGFloat = 0
    @State private var borderRotation: Double = 0

    private var forge: ForgeMark? { getForgeMarkForArena(arenaId: arena.id, sessions: sessions) }
    private var arenaColor: Color { Color(hex: arena.color) }
    private var equippedSkin: ButtonSkin? { store.equippedSkin(for: arena.id) }

    // Today's session intensity (0.0–1.0) drives under-glow strength
    private var todayIntensity: Double {
        switch sessCount {
        case 0:  return 0
        case 1:  return 0.35
        case 2:  return 0.6
        case 3:  return 0.8
        default: return 1.0
        }
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                // Background fill — skin material or default
                if let skin = equippedSkin {
                    SkinMaterialView(skin: skin, arenaColor: arenaColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .allowsHitTesting(false)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBackground)
                        .overlay(
                            Group {
                                if let bgName = arena.backgroundImageName {
                                    ArenaBackgroundImage(name: bgName)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .allowsHitTesting(false)
                                }
                            }
                        )
                }

                // Rank border overlay
                rankBorderOverlay

                // Top accent bar — thicker at higher ranks
                VStack {
                    Rectangle()
                        .fill(arenaColor.opacity(rankTier >= .burning ? 1.0 : 0.85))
                        .frame(height: rankTier >= .inferno ? 3 : 2)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
                    Spacer()
                }

                // Illustration watermark
                ArenaIllustration(arenaId: arena.id, color: arenaColor)
                    .frame(width: 110, height: 126)
                    .opacity(0.13)
                    .blendMode(.screen)
                    .offset(x: 10, y: 10)
                    .allowsHitTesting(false)

                // Forge mark (bottom-left)
                if let forge {
                    Text(forge.mark)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(arenaColor)
                        .shadow(color: arenaColor, radius: 4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(10)
                }

                // Bottom-right: rank label or session count
                if !editMode {
                    VStack(alignment: .trailing, spacing: 2) {
                        if rankTier >= .sparked {
                            Text(rankTier.label)
                                .font(.system(size: 6, weight: .bold, design: .monospaced))
                                .foregroundStyle(arenaColor.opacity(0.5))
                                .kerning(2)
                        }
                        if sessCount > 0 {
                            Text("●\(sessCount)")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(arenaColor.opacity(0.7))
                        }
                    }
                    .padding(10)
                }

                // Edit pencil (top-right)
                if editMode {
                    Text("✎")
                        .font(.system(size: 12))
                        .foregroundStyle(arenaColor.opacity(0.7))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(10)
                }

                // Content
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        if equippedSkin != nil {
                            Text(arena.icon)
                                .font(.system(size: 18))
                                .engraved(color: arenaColor, depth: 1.5)
                        } else {
                            Text(arena.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(arenaColor)
                        }
                        Text(arena.letter)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.18))
                            .kerning(3)
                    }

                    if equippedSkin != nil {
                        Text(arena.label)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .kerning(3)
                            .engraved(color: Color(hex: "#ECECEC"), depth: 1.2)
                    } else {
                        Text(arena.label)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#ECECEC"))
                            .kerning(3)
                    }

                    if !arena.subtitle.isEmpty {
                        Text(arena.subtitle)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(arenaColor.opacity(0.6))
                            .kerning(1)
                    }

                    if streak > 1 && !editMode {
                        Text("🔥 \(streak)d")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(arenaColor)
                            .opacity(0.8)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(minHeight: 150)
        }
        .buttonStyle(.plain)
        // Under-glow: vibrant arena-colored light underneath, driven by today's sessions
        .background(
            Group {
                if todayIntensity > 0 {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(arenaColor)
                        .blur(radius: 18 + todayIntensity * 8)
                        .opacity(todayIntensity * 0.35 * (1.0 + Double(glowPhase) * 0.15))
                        .scaleEffect(x: 0.85, y: 0.7)
                        .offset(y: 8)
                }
            }
        )
        // Press shadow
        .shadow(color: isPressed ? arenaColor.opacity(0.22) : .clear, radius: 12, y: 4)
        .scaleEffect(isPressed ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Animate glow pulse for active cards
            if todayIntensity > 0 || rankTier >= .blazing {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
            }
            if rankTier >= .transcendent {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    borderRotation = 360
                }
            }
        }
    }

    // MARK: - Rank Border Overlay

    @ViewBuilder
    private var rankBorderOverlay: some View {
        let shape = RoundedRectangle(cornerRadius: 16)
        let pressBoost: Double = isPressed ? 0.15 : 0
        let baseOpacity = rankTier.borderOpacity + pressBoost
        let width = rankTier.borderWidth

        switch rankTier {
        case .dormant:
            // Minimal static border
            shape.strokeBorder(arenaColor.opacity(0.18 + pressBoost), lineWidth: 1)

        case .sparked:
            // Solid brighter border
            shape.strokeBorder(arenaColor.opacity(baseOpacity), lineWidth: width)

        case .kindling:
            // Brighter border + corner accent glow
            ZStack {
                shape.strokeBorder(arenaColor.opacity(baseOpacity), lineWidth: width)
                // Subtle corner glow dots
                cornerGlows(opacity: 0.25)
            }

        case .burning:
            // Angular gradient border
            ZStack {
                shape.strokeBorder(
                    AngularGradient(
                        colors: [arenaColor.opacity(baseOpacity * 0.4),
                                 arenaColor.opacity(baseOpacity),
                                 arenaColor.opacity(baseOpacity * 0.4)],
                        center: .center
                    ),
                    lineWidth: width
                )
                cornerGlows(opacity: 0.4)
            }

        case .blazing:
            // Pulsing angular gradient + outer glow halo
            ZStack {
                // Outer glow halo
                shape.strokeBorder(arenaColor.opacity(0.08 + glowPhase * 0.06), lineWidth: 6)
                    .blur(radius: 3)
                // Main gradient border
                shape.strokeBorder(
                    AngularGradient(
                        colors: [arenaColor.opacity(baseOpacity * 0.3),
                                 arenaColor.opacity(baseOpacity),
                                 arenaColor.opacity(baseOpacity * 0.5),
                                 arenaColor.opacity(baseOpacity),
                                 arenaColor.opacity(baseOpacity * 0.3)],
                        center: .center
                    ),
                    lineWidth: width
                )
                cornerGlows(opacity: 0.55)
            }

        case .inferno:
            // Double border + strong glow
            ZStack {
                // Outer diffuse glow
                shape.strokeBorder(arenaColor.opacity(0.12 + glowPhase * 0.08), lineWidth: 8)
                    .blur(radius: 4)
                // Outer border
                shape.strokeBorder(arenaColor.opacity(baseOpacity * 0.4), lineWidth: 1)
                    .padding(-2)
                // Inner gradient border
                shape.strokeBorder(
                    AngularGradient(
                        colors: [arenaColor.opacity(baseOpacity * 0.4),
                                 arenaColor.opacity(baseOpacity),
                                 Color.white.opacity(baseOpacity * 0.6),
                                 arenaColor.opacity(baseOpacity),
                                 arenaColor.opacity(baseOpacity * 0.4)],
                        center: .center
                    ),
                    lineWidth: width
                )
                cornerGlows(opacity: 0.7)
            }

        case .transcendent:
            // Rotating gradient border + layered glow
            ZStack {
                // Outermost glow
                shape.strokeBorder(arenaColor.opacity(0.15 + glowPhase * 0.1), lineWidth: 10)
                    .blur(radius: 5)
                // Rotating gradient
                shape.strokeBorder(
                    AngularGradient(
                        colors: [arenaColor.opacity(0.2),
                                 arenaColor.opacity(baseOpacity),
                                 Color.white.opacity(0.5),
                                 arenaColor.opacity(baseOpacity),
                                 arenaColor.opacity(0.2)],
                        center: .center,
                        angle: .degrees(borderRotation)
                    ),
                    lineWidth: width
                )
                // Inner accent
                shape.strokeBorder(arenaColor.opacity(0.15), lineWidth: 0.5)
                    .padding(3)
                cornerGlows(opacity: 0.85)
            }

        case .eternalFlame:
            // Full ornate — triple layer + rotating + intense glow
            ZStack {
                // Deep outer glow
                shape.strokeBorder(arenaColor.opacity(0.2 + glowPhase * 0.12), lineWidth: 14)
                    .blur(radius: 7)
                // Outer thin border
                shape.strokeBorder(arenaColor.opacity(0.3), lineWidth: 0.8)
                    .padding(-3)
                // Main rotating gradient
                shape.strokeBorder(
                    AngularGradient(
                        colors: [arenaColor.opacity(0.3),
                                 arenaColor,
                                 Color.white.opacity(0.7),
                                 arenaColor,
                                 Color.white.opacity(0.4),
                                 arenaColor,
                                 arenaColor.opacity(0.3)],
                        center: .center,
                        angle: .degrees(borderRotation)
                    ),
                    lineWidth: width
                )
                // Inner accent ring
                shape.strokeBorder(
                    AngularGradient(
                        colors: [arenaColor.opacity(0.1),
                                 arenaColor.opacity(0.3),
                                 arenaColor.opacity(0.1)],
                        center: .center,
                        angle: .degrees(-borderRotation * 0.5)
                    ),
                    lineWidth: 0.6
                )
                .padding(3)
                cornerGlows(opacity: 1.0)
            }
        }
    }

    // MARK: - Corner Glows

    private func cornerGlows(opacity: Double) -> some View {
        GeometryReader { geo in
            let r: CGFloat = 4
            let inset: CGFloat = 14
            ZStack {
                // Top-left
                Circle().fill(arenaColor).frame(width: r, height: r)
                    .blur(radius: 3)
                    .position(x: inset, y: inset)
                // Top-right
                Circle().fill(arenaColor).frame(width: r, height: r)
                    .blur(radius: 3)
                    .position(x: geo.size.width - inset, y: inset)
                // Bottom-left
                Circle().fill(arenaColor).frame(width: r, height: r)
                    .blur(radius: 3)
                    .position(x: inset, y: geo.size.height - inset)
                // Bottom-right
                Circle().fill(arenaColor).frame(width: r, height: r)
                    .blur(radius: 3)
                    .position(x: geo.size.width - inset, y: geo.size.height - inset)
            }
            .opacity(opacity)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Card Background

    private var cardBackground: some ShapeStyle {
        switch arena.id {
        case "body":
            return AnyShapeStyle(RadialGradient(
                colors: [Color(hex: "#1a0a08"), Color(hex: "#0d0505")],
                center: UnitPoint(x: 0.6, y: 0.3), startRadius: 0, endRadius: 200))
        case "spirit":
            return AnyShapeStyle(RadialGradient(
                colors: [Color(hex: "#1a1408"), Color(hex: "#0d0b06")],
                center: UnitPoint(x: 0.6, y: 0.3), startRadius: 0, endRadius: 200))
        case "tribe":
            return AnyShapeStyle(RadialGradient(
                colors: [Color(hex: "#150f09"), Color(hex: "#0e0a07")],
                center: UnitPoint(x: 0.4, y: 0.7), startRadius: 0, endRadius: 200))
        case "craft":
            return AnyShapeStyle(RadialGradient(
                colors: [Color(hex: "#141416"), Color(hex: "#0a0a0c")],
                center: .center, startRadius: 0, endRadius: 200))
        default:
            return AnyShapeStyle(Color.white.opacity(0.03))
        }
    }
}

struct AddArenaCardView: View {
    var onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text("+")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.white.opacity(0.2))
                Text("NEW")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .kerning(3)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.white.opacity(0.02))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .foregroundStyle(Color.white.opacity(0.15))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Background image loader (asset catalog → Documents directory fallback)

struct ArenaBackgroundImage: View {
    let name: String

    var body: some View {
#if canImport(UIKit)
        if let img = uiImage {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 4)
                .overlay(Color.black.opacity(0.6))
        }
#endif
    }

#if canImport(UIKit)
    private var uiImage: UIImage? {
        if let img = UIImage(named: name) { return img }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let data = try? Data(contentsOf: docs.appendingPathComponent(name)) {
            return UIImage(data: data)
        }
        return nil
    }
#endif
}

// MARK: - Arena Illustrations (SwiftUI vector)

struct ArenaIllustration: View {
    let arenaId: String
    let color: Color

    var body: some View {
        switch arenaId {
        case "body":   BodyIllustration(color: color)
        case "spirit": SpiritIllustration(color: color)
        case "tribe":  TribeIllustration(color: color)
        case "craft":  CraftIllustration(color: color)
        default:       EmptyView()
        }
    }
}

struct BodyIllustration: View {
    let color: Color
    var body: some View {
        Canvas { ctx, size in
            let s = size
            // Torso
            var p = Path()
            p.move(to: CGPoint(x: s.width*0.5, y: s.height*0.06))
            p.addCurve(to: CGPoint(x: s.width*0.4, y: s.height*0.32),
                       control1: CGPoint(x: s.width*0.43, y: s.height*0.07),
                       control2: CGPoint(x: s.width*0.37, y: s.height*0.21))
            p.addLine(to: CGPoint(x: s.width*0.32, y: s.height*0.36))
            p.addCurve(to: CGPoint(x: s.width*0.17, y: s.height*0.52),
                       control1: CGPoint(x: s.width*0.25, y: s.height*0.39),
                       control2: CGPoint(x: s.width*0.19, y: s.height*0.45))
            p.addLine(to: CGPoint(x: s.width*0.17, y: s.height*0.94))
            p.addLine(to: CGPoint(x: s.width*0.37, y: s.height*0.94))
            p.addLine(to: CGPoint(x: s.width*0.37, y: s.height*0.77))
            p.addCurve(to: CGPoint(x: s.width*0.5, y: s.height*0.68),
                       control1: CGPoint(x: s.width*0.37, y: s.height*0.74),
                       control2: CGPoint(x: s.width*0.43, y: s.height*0.69))
            p.addCurve(to: CGPoint(x: s.width*0.63, y: s.height*0.77),
                       control1: CGPoint(x: s.width*0.57, y: s.height*0.69),
                       control2: CGPoint(x: s.width*0.63, y: s.height*0.74))
            p.addLine(to: CGPoint(x: s.width*0.63, y: s.height*0.94))
            p.addLine(to: CGPoint(x: s.width*0.83, y: s.height*0.94))
            p.addLine(to: CGPoint(x: s.width*0.83, y: s.height*0.52))
            p.addCurve(to: CGPoint(x: s.width*0.68, y: s.height*0.36),
                       control1: CGPoint(x: s.width*0.81, y: s.height*0.45),
                       control2: CGPoint(x: s.width*0.75, y: s.height*0.39))
            p.addLine(to: CGPoint(x: s.width*0.6, y: s.height*0.32))
            p.addCurve(to: CGPoint(x: s.width*0.5, y: s.height*0.06),
                       control1: CGPoint(x: s.width*0.63, y: s.height*0.21),
                       control2: CGPoint(x: s.width*0.57, y: s.height*0.07))
            p.closeSubpath()
            ctx.fill(p, with: .color(color.opacity(0.18)))
            ctx.stroke(p, with: .color(color.opacity(0.35)), lineWidth: 0.8)
            // Spine
            var spine = Path()
            spine.move(to: CGPoint(x: s.width*0.5, y: s.height*0.33))
            spine.addLine(to: CGPoint(x: s.width*0.5, y: s.height*0.68))
            ctx.stroke(spine, with: .color(color.opacity(0.2)),
                       style: StrokeStyle(lineWidth: 0.7, dash: [2, 3]))
            // Chest dot
            ctx.fill(Path(ellipseIn: CGRect(x: s.width*0.47, y: s.height*0.38, width: 6, height: 6)),
                     with: .color(color.opacity(0.15)))
        }
    }
}

struct SpiritIllustration: View {
    let color: Color
    var body: some View {
        Canvas { ctx, size in
            let s = size
            var p = Path()
            p.move(to: CGPoint(x: s.width*0.5, y: s.height*0.09))
            p.addCurve(to: CGPoint(x: s.width*0.35, y: s.height*0.33),
                       control1: CGPoint(x: s.width*0.5, y: s.height*0.09),
                       control2: CGPoint(x: s.width*0.32, y: s.height*0.2))
            p.addCurve(to: CGPoint(x: s.width*0.37, y: s.height*0.57),
                       control1: CGPoint(x: s.width*0.32, y: s.height*0.44),
                       control2: CGPoint(x: s.width*0.34, y: s.height*0.52))
            p.addCurve(to: CGPoint(x: s.width*0.5, y: s.height*0.66),
                       control1: CGPoint(x: s.width*0.4, y: s.height*0.63),
                       control2: CGPoint(x: s.width*0.5, y: s.height*0.66))
            p.addCurve(to: CGPoint(x: s.width*0.63, y: s.height*0.57),
                       control1: CGPoint(x: s.width*0.5, y: s.height*0.66),
                       control2: CGPoint(x: s.width*0.6, y: s.height*0.63))
            p.addCurve(to: CGPoint(x: s.width*0.65, y: s.height*0.33),
                       control1: CGPoint(x: s.width*0.66, y: s.height*0.52),
                       control2: CGPoint(x: s.width*0.68, y: s.height*0.44))
            p.addCurve(to: CGPoint(x: s.width*0.5, y: s.height*0.09),
                       control1: CGPoint(x: s.width*0.68, y: s.height*0.2),
                       control2: CGPoint(x: s.width*0.5, y: s.height*0.09))
            p.closeSubpath()
            ctx.fill(p, with: .color(color.opacity(0.3)))
            ctx.stroke(p, with: .color(color.opacity(0.3)), lineWidth: 0.7)
            // Base glow
            ctx.fill(Path(ellipseIn: CGRect(x: s.width*0.32, y: s.height*0.89, width: s.width*0.36, height: 10)),
                     with: .color(color.opacity(0.1)))
        }
    }
}

struct TribeIllustration: View {
    let color: Color
    var body: some View {
        Canvas { ctx, size in
            let s = size
            // Left hand palm
            var lp = Path()
            lp.addEllipse(in: CGRect(x: s.width*0.07, y: s.height*0.46, width: s.width*0.13, height: s.height*0.19))
            ctx.fill(lp, with: .color(color.opacity(0.12)))
            ctx.stroke(lp, with: .color(color.opacity(0.35)), lineWidth: 0.8)
            // Left fingers
            for (dx, dy) in [(0.15,0.41),(0.17,0.34),(0.19,0.41),(0.21,0.46)] {
                var f = Path()
                f.move(to: CGPoint(x: s.width*dx, y: s.height*0.5))
                f.addLine(to: CGPoint(x: s.width*dx, y: s.height*dy))
                ctx.stroke(f, with: .color(color.opacity(0.35)), lineWidth: 1.1)
            }
            // Right hand palm (mirror)
            var rp = Path()
            rp.addEllipse(in: CGRect(x: s.width*0.8, y: s.height*0.46, width: s.width*0.13, height: s.height*0.19))
            ctx.fill(rp, with: .color(color.opacity(0.12)))
            ctx.stroke(rp, with: .color(color.opacity(0.35)), lineWidth: 0.8)
            for (dx, dy) in [(0.85,0.41),(0.83,0.34),(0.81,0.41),(0.79,0.46)] {
                var f = Path()
                f.move(to: CGPoint(x: s.width*dx, y: s.height*0.5))
                f.addLine(to: CGPoint(x: s.width*dx, y: s.height*dy))
                ctx.stroke(f, with: .color(color.opacity(0.35)), lineWidth: 1.1)
            }
            // Center glow
            ctx.fill(Path(ellipseIn: CGRect(x: s.width*0.43, y: s.height*0.37, width: s.width*0.14, height: s.width*0.14)),
                     with: .color(color.opacity(0.2)))
        }
    }
}

struct CraftIllustration: View {
    let color: Color
    var body: some View {
        Canvas { ctx, size in
            let s = size
            // Hammer head
            var hh = Path()
            hh.addRoundedRect(in: CGRect(x: s.width*0.42, y: s.height*0.2, width: s.width*0.22, height: s.height*0.11),
                               cornerSize: CGSize(width: 2, height: 2))
            let rot = CGAffineTransform(translationX: s.width*0.5, y: s.height*0.22)
                .rotated(by: -.pi/4)
                .translatedBy(x: -s.width*0.5, y: -s.height*0.22)
            ctx.fill(hh.applying(rot), with: .color(color.opacity(0.22)))
            ctx.stroke(hh.applying(rot), with: .color(color.opacity(0.45)), lineWidth: 0.9)
            // Handle
            var handle = Path()
            handle.move(to: CGPoint(x: s.width*0.58, y: s.height*0.33))
            handle.addLine(to: CGPoint(x: s.width*0.32, y: s.height*0.66))
            ctx.stroke(handle, with: .color(color.opacity(0.3)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            // Anvil body
            var anvil = Path()
            anvil.move(to: CGPoint(x: s.width*0.18, y: s.height*0.7))
            anvil.addLine(to: CGPoint(x: s.width*0.82, y: s.height*0.7))
            anvil.addLine(to: CGPoint(x: s.width*0.82, y: s.height*0.67))
            anvil.addCurve(to: CGPoint(x: s.width*0.63, y: s.height*0.6),
                           control1: CGPoint(x: s.width*0.82, y: s.height*0.64),
                           control2: CGPoint(x: s.width*0.73, y: s.height*0.61))
            anvil.addLine(to: CGPoint(x: s.width*0.63, y: s.height*0.55))
            anvil.addLine(to: CGPoint(x: s.width*0.37, y: s.height*0.55))
            anvil.addLine(to: CGPoint(x: s.width*0.37, y: s.height*0.6))
            anvil.addCurve(to: CGPoint(x: s.width*0.18, y: s.height*0.67),
                           control1: CGPoint(x: s.width*0.27, y: s.height*0.61),
                           control2: CGPoint(x: s.width*0.18, y: s.height*0.64))
            anvil.closeSubpath()
            ctx.fill(anvil, with: .color(color.opacity(0.16)))
            ctx.stroke(anvil, with: .color(color.opacity(0.4)), lineWidth: 0.9)
            // Base
            let base = Path(roundedRect: CGRect(x: s.width*0.23, y: s.height*0.7, width: s.width*0.54, height: s.height*0.06),
                            cornerRadius: 2)
            ctx.fill(base, with: .color(color.opacity(0.14)))
        }
    }
}
