// ArenaEditorView.swift — Arena Protocol
// Create and edit arenas: name, subtitle, icon, color, description, examples

import SwiftUI

struct ArenaListEditorView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button { navigate(.home) } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 52)
                .padding(.bottom, 28)

                Text("CUSTOMIZE")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 4)
                HStack(spacing: 6) {
                    Text("YOUR")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .kerning(2)
                    Text("ARENAS")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#E8C547"))
                        .kerning(2)
                }
                .padding(.bottom, 20)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                    ForEach(store.letteredArenas) { arena in
                        ArenaCardView(
                            arena: arena, sessCount: 0, streak: 0, editMode: true,
                            onTap: { navigate(.editArena(arena)) },
                            sessions: store.sessions
                        )
                    }
                    AddArenaCardView { navigate(.newArena) }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ArenaEditorView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var arena: Arena?   // nil = new arena

    @State private var label       = ""
    @State private var subtitle    = ""
    @State private var icon        = "◈"
    @State private var color       = "#E8C547"
    @State private var description = ""
    @State private var examples    = ""

    private var isNew: Bool { arena == nil }
    private var selectedColor: Color { Color(hex: color) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 52)
                .padding(.bottom, 28)

                Text(isNew ? "NEW ARENA" : "EDIT ARENA")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 4)

                // Live preview
                VStack(alignment: .leading, spacing: 4) {
                    Text(label.isEmpty ? "UNTITLED" : label.uppercased())
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(selectedColor)
                        .kerning(2)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(selectedColor.opacity(0.6))
                            .kerning(1)
                    }
                }
                .padding(.bottom, 28)

                // Name
                fieldSection("NAME") {
                    TextField("ARENA NAME", text: $label)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(selectedColor)
                        .textInputAutocapitalization(.characters)
                        .padding(12)
                        .background(selectedColor.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selectedColor.opacity(0.5), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Subtitle
                fieldSection("SUBTITLE", optional: true) {
                    TextField("e.g. move · fuel · rest", text: $subtitle)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(selectedColor.opacity(0.8))
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text("SHOWS AS A HINT LINE BELOW THE ARENA NAME ON THE CARD")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .kerning(2)
                        .padding(.top, 6)
                }

                // Icon
                fieldSection("ICON") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                        ForEach(ARENA_ICONS, id: \.self) { ic in
                            Button { icon = ic } label: {
                                Text(ic)
                                    .font(.system(size: 18))
                                    .foregroundStyle(icon == ic ? selectedColor : Color.white.opacity(0.4))
                                    .frame(width: 40, height: 40)
                                    .background(icon == ic ? selectedColor.opacity(0.2) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(icon == ic ? selectedColor : Color.white.opacity(0.1), lineWidth: icon == ic ? 2 : 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: icon)
                        }
                    }
                }

                // Color
                fieldSection("COLOR") {
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

                // Description
                fieldSection("DESCRIPTION", optional: true) {
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("What does this arena represent?")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.2))
                                .padding(14)
                        }
                        TextEditor(text: $description)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .scrollDisabled(true)
                            .frame(minHeight: 60)
                            .padding(10)
                    }
                    .background(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Examples
                fieldSection("EXAMPLES", subLabel: "— ONE PER LINE") {
                    ZStack(alignment: .topLeading) {
                        if examples.isEmpty {
                            Text("Example task 1\nExample task 2")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.2))
                                .padding(14)
                        }
                        TextEditor(text: $examples)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .scrollDisabled(true)
                            .frame(minHeight: 90)
                            .padding(10)
                    }
                    .background(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Save button
                Button { handleSave() } label: {
                    Text(isNew ? "CREATE ARENA" : "SAVE CHANGES")
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

                // Delete button (edit only)
                if !isNew {
                    Button { handleDelete() } label: {
                        Text("DELETE ARENA")
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
        .onAppear { populate() }
    }

    private func fieldSection<Content: View>(_ label: String, subLabel: String = "", optional: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .kerning(5)
                if optional || !subLabel.isEmpty {
                    Text(optional ? "— OPTIONAL" : subLabel)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.2))
                }
            }
            content()
        }
        .padding(.bottom, 20)
    }

    private func populate() {
        guard let a = arena else { return }
        label       = a.label
        subtitle    = a.subtitle
        icon        = a.icon
        color       = a.color
        description = a.description
        examples    = a.examples.joined(separator: "\n")
    }

    private func handleSave() {
        guard !label.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let examplesList = examples.split(separator: "\n").map { String($0.trimmingCharacters(in: .whitespaces)) }.filter { !$0.isEmpty }
        let updated = Arena(
            id: arena?.id ?? uid(),
            label: label.trimmingCharacters(in: .whitespaces).uppercased(),
            letter: arena?.letter ?? "?",
            color: color,
            subtitle: subtitle.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            icon: icon,
            examples: examplesList,
            subArenas: arena?.subArenas ?? [:]
        )
        if let existing = arena, let idx = store.arenas.firstIndex(where: { $0.id == existing.id }) {
            store.arenas[idx] = updated
        } else {
            store.arenas.append(updated)
        }
        store.saveArenas()
        dismiss()
    }

    private func handleDelete() {
        guard let a = arena else { return }
        store.arenas.removeAll { $0.id == a.id }
        store.saveArenas()
        dismiss()
    }
}
