// ArenaWidgetView.swift — Arena Protocol
// Widget UI for all three supported families.
// No DataStore, no @Observable — reads only from ArenaEntry / WidgetState.

import WidgetKit
import SwiftUI

// MARK: - Root View (dispatches by family)

struct ArenaWidgetView: View {
    let entry: ArenaEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            AccessoryCircularView(state: entry.widgetState)
        case .accessoryRectangular:
            AccessoryRectangularView(state: entry.widgetState)
        case .systemSmall:
            SystemSmallView(state: entry.widgetState)
        default:
            SystemSmallView(state: entry.widgetState)
        }
    }
}

// MARK: - Lock Screen: Circular (.accessoryCircular)

private struct AccessoryCircularView: View {
    let state: WidgetState

    private var progress: Double {
        guard let endsAt = state.timerEndsAt else { return 0 }
        // Approximate 25-minute session as the full arc when no total is known.
        let total: Double = 25 * 60
        let remaining = max(0, endsAt.timeIntervalSinceNow)
        return 1 - (remaining / total)
    }

    var body: some View {
        if let endsAt = state.timerEndsAt, endsAt > Date() {
            Gauge(value: progress, in: 0...1) {
                EmptyView()
            } currentValueLabel: {
                Text(String(state.activeArenaName?.prefix(1) ?? "◉"))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(accentColor)
            .widgetBackground(Color.black)
        } else {
            // Idle state
            Gauge(value: 0, in: 0...1) {
                EmptyView()
            } currentValueLabel: {
                Text("·")
                    .font(.system(size: 18, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.white.opacity(0.25))
            .widgetBackground(Color.black)
        }
    }

    private var accentColor: Color {
        Color(hex: state.activeArenaColor ?? "#E8C547")
    }
}

// MARK: - Lock Screen: Rectangular (.accessoryRectangular)

private struct AccessoryRectangularView: View {
    let state: WidgetState

    var body: some View {
        if let name = state.activeArenaName, let endsAt = state.timerEndsAt, endsAt > Date() {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                Text(endsAt, style: .timer)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetBackground(Color.black)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("NO ARENA")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text("—")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetBackground(Color.black)
        }
    }
}

// MARK: - Home Screen Small (.systemSmall)

private struct SystemSmallView: View {
    let state: WidgetState

    var body: some View {
        if let name = state.activeArenaName,
           let colorHex = state.activeArenaColor,
           let endsAt = state.timerEndsAt, endsAt > Date() {
            // Active session
            ZStack(alignment: .topLeading) {
                Color(hex: "#0A0A0A").ignoresSafeArea()

                // 4pt accent strip along the top
                Color(hex: colorHex)
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity, alignment: .top)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 12) // clear the accent strip

                    Text(name)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.top, 6)

                    Spacer()

                    Text(endsAt, style: .timer)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: "#E8C547"))

                    Spacer()

                    HStack {
                        Spacer()
                        Text("\(state.todaySessionCount) TODAY")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                            .kerning(2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        } else {
            // Idle state
            ZStack {
                Color(hex: "#0A0A0A").ignoresSafeArea()

                VStack(spacing: 6) {
                    Text("◉")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("ARENA\nPROTOCOL")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                        .multilineTextAlignment(.center)
                        .kerning(2)
                }
            }
        }
    }
}

// MARK: - Color helper (widget target has no RootView extension)

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Widget background helper (iOS 17 API)

extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(color, for: .widget)
        } else {
            return background(color)
        }
    }
}
