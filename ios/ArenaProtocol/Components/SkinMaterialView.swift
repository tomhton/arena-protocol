// SkinMaterialView.swift — Arena Protocol
// Pure SwiftUI material renderer for button skins.
// Each material is a layered Canvas: base texture → engrave inner shadow → bevel edges → directional light.

import SwiftUI

/// Renders a full-card material texture for a given skin.
struct SkinMaterialView: View {
    let skin: ButtonSkin
    let arenaColor: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Base texture layer
                baseTexture(skin.material, size: geo.size)

                // Bevel edge highlight (top-left light source)
                bevelEdges(w: w, h: h)

                // Directional light sweep
                directionalLight(w: w, h: h)
            }
        }
    }

    // MARK: - Base Textures

    @ViewBuilder
    private func baseTexture(_ material: String, size: CGSize) -> some View {
        switch material {
        case "slate":
            slateTexture(size: size)
        case "leather":
            leatherTexture(size: size)
        case "obsidian":
            obsidianTexture(size: size)
        case "bronze":
            bronzeTexture(size: size)
        case "marble":
            marbleTexture(size: size)
        case "ironwood":
            ironwoodTexture(size: size)
        case "volcanic":
            volcanicTexture(size: size)
        case "frosted_glass":
            frostedGlassTexture(size: size)
        case "celestial":
            celestialTexture(size: size)
        case "void":
            voidTexture(size: size)
        default:
            Color.white.opacity(0.03)
        }
    }

    // MARK: - Slate (cold grey stone, subtle horizontal grain)
    private func slateTexture(size: CGSize) -> some View {
        Canvas { ctx, sz in
            // Base fill
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "#1a1c20"), Color(hex: "#14161a"), Color(hex: "#1a1c20")]),
                        startPoint: .zero, endPoint: CGPoint(x: 0, y: sz.height)))
            // Horizontal grain lines
            for i in stride(from: 0, to: sz.height, by: 4.5) {
                let opacity = Double.random(in: 0.02...0.06)
                var line = Path()
                line.move(to: CGPoint(x: 0, y: i))
                line.addLine(to: CGPoint(x: sz.width, y: i + Double.random(in: -0.5...0.5)))
                ctx.stroke(line, with: .color(Color.white.opacity(opacity)), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Leather (warm brown, cracked surface)
    private func leatherTexture(size: CGSize) -> some View {
        Canvas { ctx, sz in
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "#1f1610"), Color(hex: "#17100b"), Color(hex: "#1a130d")]),
                        startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: sz.width, y: sz.height)))
            // Crack pattern
            for _ in 0..<18 {
                let startX = Double.random(in: 0...sz.width)
                let startY = Double.random(in: 0...sz.height)
                var crack = Path()
                crack.move(to: CGPoint(x: startX, y: startY))
                crack.addLine(to: CGPoint(x: startX + Double.random(in: -20...20),
                                          y: startY + Double.random(in: -15...15)))
                ctx.stroke(crack, with: .color(Color(hex: "#0a0704").opacity(0.5)),
                           lineWidth: Double.random(in: 0.3...0.8))
            }
            // Warm surface sheen
            ctx.fill(Path(ellipseIn: CGRect(x: sz.width * 0.2, y: sz.height * 0.15,
                                            width: sz.width * 0.5, height: sz.height * 0.4)),
                     with: .color(Color(hex: "#3a2a1a").opacity(0.12)))
        }
    }

    // MARK: - Obsidian (deep black mirror, sharp reflections)
    private func obsidianTexture(size: CGSize) -> some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0a0a0e"), Color(hex: "#050508"), Color(hex: "#08080c")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            // Mirror reflection streak
            LinearGradient(colors: [.clear, Color.white.opacity(0.04), Color.white.opacity(0.08),
                                    Color.white.opacity(0.04), .clear],
                           startPoint: UnitPoint(x: 0.2, y: 0), endPoint: UnitPoint(x: 0.8, y: 1))
            // Arena color tint in reflection
            RadialGradient(colors: [arenaColor.opacity(0.06), .clear],
                           center: UnitPoint(x: 0.3, y: 0.3), startRadius: 0, endRadius: 120)
        }
    }

    // MARK: - Bronze (hammered warm metal)
    private func bronzeTexture(size: CGSize) -> some View {
        Canvas { ctx, sz in
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "#1f1a10"), Color(hex: "#2a1f12"), Color(hex: "#1a1508")]),
                        startPoint: .topLeading, endPoint: .bottomTrailing))
            // Hammered dimples
            for _ in 0..<30 {
                let x = Double.random(in: 0...sz.width)
                let y = Double.random(in: 0...sz.height)
                let r = Double.random(in: 3...8)
                ctx.fill(Path(ellipseIn: CGRect(x: x - r/2, y: y - r/2, width: r, height: r * 0.7)),
                         with: .color(Color(hex: "#0e0a04").opacity(Double.random(in: 0.08...0.18))))
                // Highlight on top edge of dimple
                ctx.fill(Path(ellipseIn: CGRect(x: x - r/2 + 0.5, y: y - r/2 - 0.3, width: r * 0.6, height: r * 0.25)),
                         with: .color(Color(hex: "#d4a84a").opacity(Double.random(in: 0.03...0.08))))
            }
        }
    }

    // MARK: - Marble (white-veined stone)
    private func marbleTexture(size: CGSize) -> some View {
        Canvas { ctx, sz in
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "#181a1e"), Color(hex: "#1c1e22"), Color(hex: "#16181c")]),
                        startPoint: .top, endPoint: .bottom))
            // Veins
            for _ in 0..<8 {
                var vein = Path()
                let startX = Double.random(in: -10...sz.width)
                let startY = Double.random(in: 0...sz.height)
                vein.move(to: CGPoint(x: startX, y: startY))
                var cx = startX
                for _ in 0..<5 {
                    cx += Double.random(in: 10...40)
                    let cy = startY + Double.random(in: -30...30)
                    vein.addLine(to: CGPoint(x: cx, y: cy))
                }
                ctx.stroke(vein, with: .color(Color.white.opacity(Double.random(in: 0.04...0.1))),
                           lineWidth: Double.random(in: 0.3...1.2))
            }
        }
    }

    // MARK: - Ironwood (dark petrified grain)
    private func ironwoodTexture(size: CGSize) -> some View {
        Canvas { ctx, sz in
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "#12100e"), Color(hex: "#181412"), Color(hex: "#100e0c")]),
                        startPoint: .top, endPoint: .bottom))
            // Wood grain — vertical wavy lines
            for i in stride(from: 0, to: sz.width, by: 3.2) {
                var grain = Path()
                grain.move(to: CGPoint(x: i, y: 0))
                for y in stride(from: 0, to: sz.height, by: 6) {
                    let waveX = i + sin(y * 0.08 + Double(i) * 0.3) * 2.5
                    grain.addLine(to: CGPoint(x: waveX, y: y))
                }
                ctx.stroke(grain, with: .color(Color(hex: "#2a2018").opacity(Double.random(in: 0.06...0.14))),
                           lineWidth: 0.6)
            }
            // Knot
            ctx.fill(Path(ellipseIn: CGRect(x: sz.width * 0.65, y: sz.height * 0.55,
                                            width: 14, height: 10)),
                     with: .color(Color(hex: "#0e0a06").opacity(0.25)))
        }
    }

    // MARK: - Volcanic (cooling magma, glowing cracks)
    private func volcanicTexture(size: CGSize) -> some View {
        Canvas { ctx, sz in
            ctx.fill(Path(CGRect(origin: .zero, size: sz)),
                     with: .linearGradient(
                        Gradient(colors: [Color(hex: "#120808"), Color(hex: "#0e0505"), Color(hex: "#140a0a")]),
                        startPoint: .topLeading, endPoint: .bottomTrailing))
            // Glowing cracks
            for _ in 0..<12 {
                var crack = Path()
                var x = Double.random(in: 0...sz.width)
                var y = Double.random(in: 0...sz.height)
                crack.move(to: CGPoint(x: x, y: y))
                for _ in 0..<4 {
                    x += Double.random(in: -18...18)
                    y += Double.random(in: -12...12)
                    crack.addLine(to: CGPoint(x: x, y: y))
                }
                // Outer glow
                ctx.stroke(crack, with: .color(Color(hex: "#FF4500").opacity(0.08)), lineWidth: 3)
                // Core
                ctx.stroke(crack, with: .color(Color(hex: "#FF6B35").opacity(0.2)), lineWidth: 0.8)
            }
            // Ember glow spots
            for _ in 0..<5 {
                let gx = Double.random(in: 0...sz.width)
                let gy = Double.random(in: 0...sz.height)
                ctx.fill(Path(ellipseIn: CGRect(x: gx - 4, y: gy - 4, width: 8, height: 8)),
                         with: .color(Color(hex: "#FF4500").opacity(Double.random(in: 0.03...0.08))))
            }
        }
    }

    // MARK: - Frosted Glass (translucent ice, light bends)
    private func frostedGlassTexture(size: CGSize) -> some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0e1218"), Color(hex: "#101620"), Color(hex: "#0c1016")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            // Frost noise
            Canvas { ctx, sz in
                for _ in 0..<60 {
                    let x = Double.random(in: 0...sz.width)
                    let y = Double.random(in: 0...sz.height)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y,
                                                    width: Double.random(in: 1...4),
                                                    height: Double.random(in: 1...4))),
                             with: .color(Color.white.opacity(Double.random(in: 0.01...0.05))))
                }
            }
            // Light refraction bands
            LinearGradient(colors: [.clear, Color(hex: "#60A5FA").opacity(0.04),
                                    Color.white.opacity(0.03), .clear],
                           startPoint: UnitPoint(x: 0.1, y: 0.3), endPoint: UnitPoint(x: 0.9, y: 0.7))
            // Arena color diffusion
            RadialGradient(colors: [arenaColor.opacity(0.05), .clear],
                           center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 100)
        }
    }

    // MARK: - Celestial (night sky, drifting stars)
    private func celestialTexture(size: CGSize) -> some View {
        ZStack {
            RadialGradient(colors: [Color(hex: "#0c0e1a"), Color(hex: "#060810"), Color(hex: "#04050a")],
                           center: UnitPoint(x: 0.4, y: 0.3), startRadius: 0, endRadius: 250)
            // Stars
            Canvas { ctx, sz in
                for _ in 0..<40 {
                    let x = Double.random(in: 0...sz.width)
                    let y = Double.random(in: 0...sz.height)
                    let r = Double.random(in: 0.4...1.8)
                    let brightness = Double.random(in: 0.15...0.55)
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(Color.white.opacity(brightness)))
                    // Star glow
                    if r > 1.2 {
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r * 2, y: y - r * 2, width: r * 4, height: r * 4)),
                                 with: .color(Color(hex: "#8B9FFF").opacity(brightness * 0.15)))
                    }
                }
            }
            // Nebula wash
            RadialGradient(colors: [Color(hex: "#2a1a4a").opacity(0.08), .clear],
                           center: UnitPoint(x: 0.7, y: 0.6), startRadius: 10, endRadius: 100)
        }
    }

    // MARK: - Void (pure black, gravitational pull)
    private func voidTexture(size: CGSize) -> some View {
        ZStack {
            Color(hex: "#030304")
            // Central singularity
            RadialGradient(colors: [Color(hex: "#0a0a0f").opacity(0.5), Color(hex: "#020203"), Color.black],
                           center: UnitPoint(x: 0.5, y: 0.5), startRadius: 0, endRadius: 140)
            // Event horizon ring
            Canvas { ctx, sz in
                let cx = sz.width * 0.5
                let cy = sz.height * 0.5
                for i in 0..<3 {
                    let r = 30.0 + Double(i) * 15
                    let path = Path(ellipseIn: CGRect(x: cx - r, y: cy - r * 0.6,
                                                      width: r * 2, height: r * 1.2))
                    ctx.stroke(path, with: .color(arenaColor.opacity(0.04 - Double(i) * 0.01)),
                               lineWidth: 0.5)
                }
            }
            // Faint particle trails being pulled in
            Canvas { ctx, sz in
                let cx = sz.width * 0.5
                let cy = sz.height * 0.5
                for _ in 0..<12 {
                    let angle = Double.random(in: 0...(2 * .pi))
                    let dist = Double.random(in: 30...80)
                    var trail = Path()
                    trail.move(to: CGPoint(x: cx + cos(angle) * dist,
                                           y: cy + sin(angle) * dist * 0.6))
                    trail.addLine(to: CGPoint(x: cx + cos(angle) * dist * 0.4,
                                              y: cy + sin(angle) * dist * 0.4 * 0.6))
                    ctx.stroke(trail, with: .color(Color.white.opacity(Double.random(in: 0.02...0.06))),
                               lineWidth: 0.4)
                }
            }
        }
    }

    // MARK: - Bevel Edges

    private func bevelEdges(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Top edge highlight
            LinearGradient(colors: [Color.white.opacity(0.06), .clear],
                           startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.08))
            // Bottom edge shadow
            LinearGradient(colors: [.clear, Color.black.opacity(0.12)],
                           startPoint: UnitPoint(x: 0.5, y: 0.92), endPoint: .bottom)
            // Left edge highlight
            LinearGradient(colors: [Color.white.opacity(0.03), .clear],
                           startPoint: .leading, endPoint: UnitPoint(x: 0.05, y: 0.5))
        }
    }

    // MARK: - Directional Light

    private func directionalLight(w: CGFloat, h: CGFloat) -> some View {
        RadialGradient(
            colors: [Color.white.opacity(0.04), .clear],
            center: UnitPoint(x: 0.25, y: 0.15),
            startRadius: 0,
            endRadius: max(w, h) * 0.7
        )
    }
}

// MARK: - Engrave Effect Modifier

/// Applies an engraved (inner shadow) appearance to text or shapes.
struct EngraveModifier: ViewModifier {
    let color: Color
    let depth: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundStyle(color.opacity(0.7))
            .shadow(color: Color.black.opacity(0.6), radius: depth * 0.5, x: 0, y: depth)
            .shadow(color: Color.white.opacity(0.08), radius: depth * 0.3, x: 0, y: -depth * 0.5)
    }
}

extension View {
    func engraved(color: Color = .white, depth: CGFloat = 1.5) -> some View {
        modifier(EngraveModifier(color: color, depth: depth))
    }
}
