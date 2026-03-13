// WindDownView.swift — Arena Protocol
// Evening wind-down: journal entry + habit check-in

import SwiftUI

struct WindDownView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var step = 0
    @State private var journal = ""
    @State private var habitAnswers: [String: Bool] = [:]

    private var habits: [Habit] { store.habits }
    private var totalSteps: Int { 1 + habits.count }
    private var isJournal: Bool { step == 0 }
    private var currentHabit: Habit? { step > 0 && step <= habits.count ? habits[step - 1] : nil }
    private var progress: Double { Double(step) / Double(max(totalSteps - 1, 1)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { navigate(.home) } label: {
                Text("← BACK")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .kerning(4)
            }
            .buttonStyle(.plain)
            .padding(.top, 52)
            .padding(.horizontal, 22)
            .padding(.bottom, 28)

            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("WIND DOWN")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                HStack(spacing: 6) {
                    Text("CLOSE")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .kerning(2)
                }
                HStack {
                    Text("THE")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .kerning(2)
                    Text("DAY")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#B794F4"))
                        .kerning(2)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)

            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("\(step + 1) OF \(totalSteps)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .kerning(4)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(hex: "#B794F4"))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.06)).frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#B794F4"))
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.easeInOut, value: step)
                    }
                }
                .frame(height: 3)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 32)

            // Step content
            if isJournal {
                journalStep
            } else if let habit = currentHabit {
                habitStep(habit)
            }
        }
    }

    // MARK: - Journal Step

    private var journalStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How did today go?")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.7))
                .lineSpacing(4)
                .padding(.bottom, 8)
                .padding(.horizontal, 22)
            Text("One sentence is enough. More is welcome.")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.3))
                .padding(.bottom, 20)
                .padding(.horizontal, 22)

            ZStack(alignment: .topLeading) {
                if journal.isEmpty {
                    Text("Today I...")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .padding(14)
                }
                TextEditor(text: $journal)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 100)
                    .padding(10)
            }
            .background(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 22)
            .padding(.bottom, 20)

            Button { nextStep() } label: {
                Text(journal.trimmingCharacters(in: .whitespaces).isEmpty ? "SKIP →" : "NEXT →")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#080810"))
                    .kerning(5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#B794F4"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
        }
    }

    // MARK: - Habit Step

    private func habitStep(_ habit: Habit) -> some View {
        let hColor = Color(hex: habit.color)
        return VStack(spacing: 0) {
            // Habit card
            VStack(spacing: 8) {
                Text("HABIT CHECK")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(hColor.opacity(0.8))
                    .kerning(3)
                Text(habit.name)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(hColor)
                    .kerning(2)
                if !habit.goal.isEmpty {
                    Text("Goal: \(habit.goal)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .italic()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(hColor.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(hColor.opacity(0.3), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 22)
            .padding(.bottom, 28)

            Text("Did you complete this today?")
                .font(.system(size: 16))
                .foregroundStyle(Color.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 32)

            // Yes / No
            HStack(spacing: 12) {
                Button { answerHabit(habit, value: true) } label: {
                    Text("✓")
                        .font(.system(size: 20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(habitAnswers[habit.id] == true ? hColor : hColor.opacity(0.18))
                        .foregroundStyle(habitAnswers[habit.id] == true ? Color(hex: "#080810") : hColor)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(hColor, lineWidth: 2))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: habitAnswers[habit.id])

                Button { answerHabit(habit, value: false) } label: {
                    Text("✗")
                        .font(.system(size: 20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(habitAnswers[habit.id] == false ? Color.red.opacity(0.3) : Color.red.opacity(0.08))
                        .foregroundStyle(habitAnswers[habit.id] == false ? .white : Color.red.opacity(0.6))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.red.opacity(0.3), lineWidth: 2))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: habitAnswers[habit.id])
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 16)

            Button { nextStep() } label: {
                Text("SKIP")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .kerning(3)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Logic

    private func answerHabit(_ habit: Habit, value: Bool) {
        habitAnswers[habit.id] = value
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { nextStep() }
    }

    private func nextStep() {
        if step < totalSteps - 1 {
            withAnimation { step += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        // Save journal
        let text = journal.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty {
            store.journals.append(JournalEntry(date: todayString(), text: text, ts: Date().timeIntervalSince1970 * 1000))
            store.saveJournals()
        }
        // Save habit logs
        for (habitId, value) in habitAnswers {
            if let idx = store.habitLogs.firstIndex(where: { $0.habitId == habitId && $0.date == todayString() }) {
                store.habitLogs[idx].value = value
            } else {
                store.habitLogs.append(HabitLog(habitId: habitId, date: todayString(), value: value, ts: Date().timeIntervalSince1970 * 1000))
            }
        }
        store.saveHabitLogs()
        navigate(.home)
    }
}
