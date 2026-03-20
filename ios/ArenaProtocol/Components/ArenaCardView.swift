// ArenaCardView.swift — Arena Protocol
// Native SwiftUI arena card with illustrations and forge marks

import SwiftUI
import UIKit

struct ArenaCardView: View {
    let arena: Arena
    let sessCount: Int
    let streak: Int
    let editMode: Bool
    var onTap: () -> Void
    var sessions: [Session] = []

    @State private var isPressed = false

    private var forge: ForgeMark? { getForgeMarkForArena(arenaId: arena.id, sessions: sessions) }
    private var arenaColor: Color { Color(hex: arena.color) }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(isPressed ? arenaColor.opacity(0.45) : arenaColor.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: isPressed ? arenaColor.opacity(0.22) : .clear, radius: 12, y: 4)

                // Custom background image (when set)
                if let bgName = arena.backgroundImageName {
                    ArenaBackgroundImage(name: bgName)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .allowsHitTesting(false)
                }

                // Top accent bar
                VStack {
                    Rectangle()
                        .fill(arenaColor.opacity(0.85))
                        .frame(height: 2)
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

                // Session count (bottom-right, when no forge and streak ≤ 1)
                if !editMode, sessCount > 0, streak <= 1, forge == nil {
                    Text("●\(sessCount)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(arenaColor)
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
                        Text(arena.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(arenaColor)
                        Text(arena.letter)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.18))
                            .kerning(3)
                    }

                    Text(arena.label)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#ECECEC"))
                        .kerning(3)

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
        .scaleEffect(isPressed ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }

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

    private var uiImage: UIImage? {
        if let img = UIImage(named: name) { return img }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let data = try? Data(contentsOf: docs.appendingPathComponent(name)) {
            return UIImage(data: data)
        }
        return nil
    }

    var body: some View {
        if let img = uiImage {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 4)
                .overlay(Color.black.opacity(0.6))
        }
    }
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
