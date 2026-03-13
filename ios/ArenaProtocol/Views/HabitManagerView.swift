// HabitManagerView.swift — Arena Protocol
// Create, edit, delete daily habits

import SwiftUI

struct HabitManagerView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var editing: Habit? = nil
    @State private var isNew   = false
    @State private var name    = ""
    @State private var goal    = ""
    @State private var color   = "#E8C547"

    private var habits: [Habit] { store.habits }

    var body: some View {
        if editing != nil || isNew {
            editorView
        } else {
            listView
        }
    }

    // MARK: - List

    private var listView: some View {
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

            Text("TRACKING")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.25))
                .kerning(7)
                .padding(.horizontal, 22)
                .padding(.bottom, 4)
            Text("HABITS")
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .kerning(2)
                .padding(.horizontal, 22)
                .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if habits.isEmpty {
                        Text("NO HABITS YET")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.18))
                            .kerning(3)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    }
                    ForEach(habits) { h in
                        Button {
                            editing = h
                            name = h.name; goal = h.goal; color = h.color
                        } label: {
                            HStack(spacing: 12) {
                                Circle().fill(Color(hex: h.color)).frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(h.name)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.white.opacity(0.8))
                                    if !h.goal.isEmpty {
                                        Text(h.goal)
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.white.opacity(0.3))
                                            .italic()
                                    }
                                }
                                Spacer()
                                Text("›").font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.2))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.02))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: h.color).opacity(0.3), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 20)
            }

            Button {
                name = ""; goal = ""; color = "#E8C547"; isNew = true
            } label: {
                Text("+ ADD HABIT")
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
            .padding(.bottom, 32)
        }
    }

    // MARK: - Editor

    private var editorView: some View {
        let selectedColor = Color(hex: color)

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button { editing = nil; isNew = false } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 52)
                .padding(.bottom, 28)

                Text(editing != nil ? "EDIT HABIT" : "NEW HABIT")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 4)
                Text(name.isEmpty ? "UNTITLED" : name.uppercased())
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(selectedColor)
                    .kerning(2)
                    .padding(.bottom, 28)

                fieldSection("HABIT NAME") {
                    styledInput($name)
                }
                fieldSection("GOAL DESCRIPTION", optional: true) {
                    styledInput($goal, placeholder: "Consistent sleep schedule")
                }
                fieldSection("COLOR") {
                    colorPicker
                }
                .padding(.bottom, 8)

                Button { saveHabit() } label: {
                    Text(editing != nil ? "SAVE CHANGES" : "CREATE HABIT")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#080810"))
                        .kerning(5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)

                if let h = editing {
                    Button { deleteHabit(h.id) } label: {
                        Text("DELETE HABIT")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.red.opacity(0.6))
                            .kerning(4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.red.opacity(0.3), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 32)
                }
            }
            .padding(.horizontal, 22)
        }
    }

    private func fieldSection<Content: View>(_ label: String, optional: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(5)
                if optional {
                    Text("— OPTIONAL")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.2))
                }
            }
            content()
        }
        .padding(.bottom, 20)
    }

    private func styledInput(_ binding: Binding<String>, placeholder: String = "") -> some View {
        TextField(placeholder, text: binding)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.8))
            .padding(12)
            .background(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var colorPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(ARENA_COLORS, id: \.self) { c in
                Button { color = c } label: {
                    Circle()
                        .fill(Color(hex: c))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().strokeBorder(color == c ? Color.white : Color.clear, lineWidth: 3))
                        .shadow(color: color == c ? Color(hex: c) : .clear, radius: 8)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: color)
            }
        }
    }

    // MARK: - Actions

    private func saveHabit() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        if let h = editing, let idx = store.habits.firstIndex(where: { $0.id == h.id }) {
            store.habits[idx] = Habit(id: h.id, name: name.trimmingCharacters(in: .whitespaces),
                                      goal: goal.trimmingCharacters(in: .whitespaces),
                                      color: color, createdAt: h.createdAt)
        } else {
            store.habits.append(Habit(id: uid(), name: name.trimmingCharacters(in: .whitespaces),
                                       goal: goal.trimmingCharacters(in: .whitespaces),
                                       color: color, createdAt: todayString()))
        }
        store.saveHabits()
        editing = nil; isNew = false
    }

    private func deleteHabit(_ id: String) {
        store.habits.removeAll { $0.id == id }
        store.saveHabits()
        editing = nil
    }
}
