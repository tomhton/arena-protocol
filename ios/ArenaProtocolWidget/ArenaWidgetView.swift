import WidgetKit
import SwiftUI

// MARK: - Color helper
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard !h.isEmpty else {
            self.init(red: 0.75, green: 0.22, blue: 0.17) // fallback: #C0392B
            return
        }
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Widget View
struct ArenaWidgetView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var arenaColor: Color {
        Color(hex: entry.widgetState.activeArenaColor ?? "#708090")
    }

    var arenaName: String {
        entry.widgetState.activeArenaName ?? ""
    }

    var isActive: Bool {
        entry.widgetState.activeArenaName != nil
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .systemSmall:
            smallView
        default:
            smallView
        }
    }

    // MARK: Lock screen circular
    var circularView: some View {
        ZStack {
            if isActive, let endsAt = entry.widgetState.timerEndsAt {
                Gauge(value: max(0, endsAt.timeIntervalSinceNow),
                      in: 0...(25 * 60)) {
                    Text(String(arenaName.prefix(1)))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(arenaColor)
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(arenaColor)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.15))
                Text("◉")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: Lock screen rectangular
    var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isActive, let endsAt = entry.widgetState.timerEndsAt {
                Text(arenaName)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(endsAt, style: .timer)
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .foregroundStyle(arenaColor)
            } else {
                Text("NO ARENA")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                Text("—")
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Home screen small
    var smallView: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "#0A0A0A")

            if isActive, let endsAt = entry.widgetState.timerEndsAt {
                // Accent strip
                Rectangle()
                    .fill(arenaColor)
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    Text(arenaName)
                        .font(.system(size: 22, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(endsAt, style: .timer)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#E8C547"))
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(entry.widgetState.todaySessionCount) TODAY")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .padding(.leading, 12)
                .padding([.top, .bottom, .trailing], 12)

            } else {
                VStack {
                    Spacer()
                    Text("◉")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("ARENA\nPROTOCOL")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.25))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .widgetBackground()
    }
}

// MARK: - containerBackground compat
extension View {
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return AnyView(self.containerBackground(Color(hex: "#0A0A0A"), for: .widget))
        } else {
            return AnyView(self.background(Color(hex: "#0A0A0A")))
        }
    }
}
