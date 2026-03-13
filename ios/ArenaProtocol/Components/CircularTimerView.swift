// CircularTimerView.swift — Arena Protocol
// Reusable circular progress timer

import SwiftUI

struct CircularTimerView: View {
    let timeLeft: Int
    let totalTime: Int
    let color: Color
    let size: CGFloat

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - Double(timeLeft) / Double(totalTime)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 6)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .shadow(color: color.opacity(0.6), radius: 8)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Time label
            VStack(spacing: 4) {
                Text(formatTime(timeLeft))
                    .font(.system(size: size * 0.21, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .monospacedDigit()

                Text("REMAINING")
                    .font(.system(size: size * 0.04, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(3)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    CircularTimerView(timeLeft: 1234, totalTime: 1500, color: .red, size: 220)
        .preferredColorScheme(.dark)
}
