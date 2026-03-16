// MorningCheckinView.swift — Arena Protocol
// Daily 15-min morning ritual: Reading, Goals, Movement

import SwiftUI

struct MorningCheckinView: View {
    @Environment(DataStore.self) private var store
    var onComplete: (Int) -> Void
    var onSkip:     () -> Void

    private var checkin: MorningCheckin {
        get { store.checkin }
    }
    private var allDone: Bool { store.checkin.completed.count == MORNING_HABITS_STATIC.count }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("MORNING PROTOCOL")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(7)
                    HStack(spacing: 0) {
                        Text("IGNITE THE")
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .kerning(2)
                    }
                    HStack(spacing: 6) {
                        Text("DAY")
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#E8C547"))
                            .kerning(2)
                    }
                    Text("15 minutes. 3 habits. Non-negotiable.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .padding(.top, 4)
                }
                .padding(.top, 52)
                .padding(.bottom, 32)

                // Habit checkboxes
                VStack(spacing: 14) {
                    ForEach(MORNING_HABITS_STATIC, id: \.id) { habit in
                        let done = store.checkin.completed.contains(habit.id)
                        let habitColor = Color(hex: habit.color)
                        Button { toggle(habit.id) } label: {
                            HStack(spacing: 16) {
                                // Checkbox
                                ZStack {
                                    Circle()
                                        .strokeBorder(done ? habitColor : Color.white.opacity(0.15), lineWidth: 2)
                                        .frame(width: 28, height: 28)
                                    if done {
                                        Circle().fill(habitColor).frame(width: 28, height: 28)
                                        Text("✓")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Color(hex: "#080810"))
                                    }
                                }

                                // Content
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(habit.label)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundStyle(done ? habitColor : Color(hex: "#E8E8E8"))
                                            .kerning(3)
                                        Text(habit.duration)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundStyle(done ? habitColor.opacity(0.8) : Color.white.opacity(0.2))
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .overlay(Capsule().strokeBorder(done ? habitColor.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                                            .clipShape(Capsule())
                                            .kerning(2)
                                    }
                                    Text(habit.description)
                                        .font(.system(size: 11))
                                        .foregroundStyle(done ? habitColor.opacity(0.7) : Color.white.opacity(0.35))
                                        .lineSpacing(3)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(done ? habitColor.opacity(0.1) : Color.white.opacity(0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(done ? habitColor.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.3), value: done)
                    }
                }
                .padding(.bottom, 32)

                // Progress
                VStack(spacing: 8) {
                    HStack {
                        Text("MORNING PROGRESS")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .kerning(4)
                        Spacer()
                        Text("\(store.checkin.completed.count)/\(MORNING_HABITS_STATIC.count)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color(hex: "#E8C547"))
                            .kerning(2)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "#E8C547"))
                                .frame(width: geo.size.width * CGFloat(store.checkin.completed.count) / CGFloat(MORNING_HABITS_STATIC.count), height: 3)
                                .shadow(color: Color(hex: "#E8C547").opacity(0.5), radius: 8)
                                .animation(.easeInOut, value: store.checkin.completed.count)
                        }
                    }
                    .frame(height: 3)
                }
                .padding(.bottom, 28)

                // CTA button
                Button { onComplete(store.checkin.completed.count) } label: {
                    Text(allDone ? "ENTER THE ARENA →" : "CONTINUE →")
                        .font(.system(size: 13, weight: allDone ? .bold : .regular, design: .monospaced))
                        .foregroundStyle(allDone ? Color(hex: "#080810") : Color.white.opacity(0.4))
                        .kerning(5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(allDone ? Color(hex: "#E8C547") : Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(allDone ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: allDone ? Color(hex: "#E8C547").opacity(0.3) : .clear, radius: 24)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.3), value: allDone)
                .padding(.bottom, 20)

                AppShortcutsBar()

                Button { onSkip() } label: {
                    Text("SKIP MORNING PROTOCOL")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .kerning(3)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 22)
        }
    }

    private func toggle(_ id: String) {
        if store.checkin.completed.contains(id) {
            store.checkin.completed.removeAll { $0 == id }
        } else {
            store.checkin.completed.append(id)
        }
        store.saveCheckin()
    }
}
