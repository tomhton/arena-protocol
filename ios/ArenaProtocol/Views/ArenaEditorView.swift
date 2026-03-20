// ArenaEditorView.swift — Arena Protocol
// Create and edit arenas: name, subtitle, icon, color, description, examples, sub-arenas

import SwiftUI
import PhotosUI

struct ArenaListEditorView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var dragTarget: String? = nil

    private func moveArena(from dragId: String, to dropId: String) {
        guard dragId != dropId,
              let fromIdx = store.arenas.firstIndex(where: { $0.id == dragId }),
              let toIdx   = store.arenas.firstIndex(where: { $0.id == dropId })
        else { return }
        store.arenas.move(fromOffsets: IndexSet(integer: fromIdx),
                          toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx)
        store.saveArenas()
    }

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
                        .draggable(arena.id)
                        .dropDestination(for: String.self) { items, _ in
                            guard let id = items.first else { return false }
                            withAnimation { moveArena(from: id, to: arena.id) }
                            return true
                        } isTargeted: { over in
                            dragTarget = over ? arena.id : nil
                        }
                        .opacity(dragTarget == arena.id ? 0.6 : 1.0)
                    }
                    AddArenaCardView { navigate(.newArena) }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Sub-arena row model (local to editor)

private struct SubArenaRow: Identifiable {
    let id = UUID()
    var name: String
    var examples: String   // newline-separated
}

// MARK: - Arena Editor

struct ArenaEditorView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var arena: Arena?   // nil = new arena

    @State private var label        = ""
    @State private var subtitle     = ""
    @State private var icon         = "◈"
    @State private var customIcon   = ""          // free-text override
    @State private var color        = "#E8C547"
    @State private var description  = ""
    @State private var examples     = ""
    @State private var pickerColor: Color = Color(hex: "#E8C547")
    @State private var subArenaRows: [SubArenaRow] = []
    @State private var persistedId: String? = nil
    @State private var backgroundImageName: String? = nil
    @State private var showPhotoPicker = false

    private var isNew: Bool { arena == nil }
    private var selectedColor: Color { Color(hex: color) }
    private var displayIcon: String { customIcon.isEmpty ? icon : customIcon }

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
                HStack(spacing: 12) {
                    Text(displayIcon)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label.isEmpty ? "UNTITLED" : label.uppercased())
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(selectedColor)
                            .kerning(2)
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(selectedColor.opacity(0.6))
                                .kerning(1)
                        }
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
                    TextField("e.g. vision · build · restore", text: $subtitle)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(selectedColor.opacity(0.8))
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Icon
                fieldSection("ICON") {
                    VStack(spacing: 12) {
                        // Free-text / emoji input
                        HStack(spacing: 10) {
                            Text("CUSTOM")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.3))
                                .kerning(4)
                            TextField("any emoji or symbol", text: $customIcon)
                                .font(.system(size: 22))
                                .multilineTextAlignment(.center)
                                .frame(width: 52, height: 44)
                                .background(customIcon.isEmpty ? Color.white.opacity(0.04) : selectedColor.opacity(0.15))
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(
                                    customIcon.isEmpty ? Color.white.opacity(0.1) : selectedColor, lineWidth: customIcon.isEmpty ? 1 : 2))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onChange(of: customIcon) { _, v in
                                    // Keep only the last character/emoji entered
                                    if v.count > 2 { customIcon = String(v.suffix(1)) }
                                }
                            if !customIcon.isEmpty {
                                Button {
                                    customIcon = ""
                                } label: {
                                    Text("CLEAR")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.3))
                                        .kerning(3)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }

                        // Preset grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                            ForEach(ARENA_ICONS, id: \.self) { ic in
                                Button {
                                    icon = ic
                                    customIcon = ""
                                } label: {
                                    Text(ic)
                                        .font(.system(size: 18))
                                        .foregroundStyle(icon == ic && customIcon.isEmpty ? selectedColor : Color.white.opacity(0.4))
                                        .frame(width: 36, height: 36)
                                        .background(icon == ic && customIcon.isEmpty ? selectedColor.opacity(0.2) : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(icon == ic && customIcon.isEmpty ? selectedColor : Color.white.opacity(0.1),
                                                              lineWidth: icon == ic && customIcon.isEmpty ? 2 : 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.15), value: icon)
                            }
                        }
                    }
                }

                // Color
                fieldSection("COLOR") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("CUSTOM")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.3))
                                .kerning(4)
                            Spacer()
                            ColorPicker("", selection: $pickerColor, supportsOpacity: false)
                                .labelsHidden()
                                .frame(width: 36, height: 36)
                                .onChange(of: pickerColor) { _, c in
                                    color = c.toHex()
                                }
                        }
                        .padding(.horizontal, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(ARENA_COLORS, id: \.self) { c in
                                Button {
                                    color = c
                                    pickerColor = Color(hex: c)
                                } label: {
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
                fieldSection("QUICK EXAMPLES", subLabel: "— ONE PER LINE") {
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

                // Sub-arenas
                fieldSection("SUB-ARENAS", optional: true) {
                    VStack(spacing: 10) {
                        Text("CATEGORIES THAT APPEAR IN THE SESSION QUEST PICKER")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.18))
                            .kerning(2)

                        ForEach($subArenaRows) { $row in
                            SubArenaRowView(row: $row, accentColor: selectedColor) {
                                subArenaRows.removeAll { $0.id == row.id }
                            }
                        }

                        Button {
                            subArenaRows.append(SubArenaRow(name: "", examples: ""))
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("ADD CATEGORY")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .kerning(3)
                            }
                            .foregroundStyle(selectedColor.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selectedColor.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Background Image
                fieldSection("BACKGROUND IMAGE", optional: true) {
                    VStack(spacing: 12) {
                        // Current selection status
                        HStack(spacing: 10) {
                            if let name = backgroundImageName {
                                if let img = loadPreviewImage(name) {
                                    Image(uiImage: img)
                                        .resizable().aspectRatio(contentMode: .fill)
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.06))
                                        .frame(width: 44, height: 44)
                                        .overlay(Text("◈").font(.system(size: 16)).foregroundStyle(Color.white.opacity(0.25)))
                                }
                                Text(name)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(selectedColor.opacity(0.8))
                                    .kerning(1)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button { backgroundImageName = nil } label: {
                                    Text("REMOVE")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(Color.red.opacity(0.55))
                                        .kerning(3)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("NONE")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.22))
                                    .kerning(3)
                                Spacer()
                            }
                        }

                        // Bundled presets
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(BUNDLED_BG_IMAGES, id: \.name) { preset in
                                    Button { backgroundImageName = preset.name } label: {
                                        VStack(spacing: 4) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(backgroundImageName == preset.name
                                                          ? selectedColor.opacity(0.18)
                                                          : Color.white.opacity(0.05))
                                                    .frame(width: 54, height: 54)
                                                if let img = loadPreviewImage(preset.name) {
                                                    Image(uiImage: img)
                                                        .resizable().aspectRatio(contentMode: .fill)
                                                        .frame(width: 54, height: 54)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                } else {
                                                    Text("◈")
                                                        .font(.system(size: 16))
                                                        .foregroundStyle(Color.white.opacity(0.18))
                                                }
                                            }
                                            .overlay(RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(backgroundImageName == preset.name
                                                              ? selectedColor : Color.white.opacity(0.1),
                                                              lineWidth: backgroundImageName == preset.name ? 2 : 1))
                                            Text(preset.label)
                                                .font(.system(size: 7, design: .monospaced))
                                                .foregroundStyle(backgroundImageName == preset.name
                                                                 ? selectedColor : Color.white.opacity(0.28))
                                                .kerning(2)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeInOut(duration: 0.15), value: backgroundImageName)
                                }
                            }
                        }

                        // Photo library picker
                        Button { showPhotoPicker = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 12))
                                Text("CHOOSE FROM PHOTOS")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .kerning(3)
                            }
                            .foregroundStyle(selectedColor.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(selectedColor.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
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
        .onDisappear { persist() }
        .sheet(isPresented: $showPhotoPicker) {
            PHImagePicker { image in
                guard let img = image,
                      let filename = saveImageToDocuments(img) else { return }
                backgroundImageName = filename
            }
        }
    }

    // MARK: - Helpers

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
        label        = a.label
        subtitle     = a.subtitle
        icon         = a.icon
        color        = a.color
        pickerColor  = Color(hex: a.color)
        description  = a.description
        examples     = a.examples.joined(separator: "\n")
        subArenaRows = a.subArenas.map { key, vals in
            SubArenaRow(name: key, examples: vals.joined(separator: "\n"))
        }.sorted { $0.name < $1.name }
        backgroundImageName = a.backgroundImageName
        // If icon isn't in presets, treat it as custom
        if !ARENA_ICONS.contains(a.icon) {
            customIcon = a.icon
        }
    }

    private func persist() {
        guard !label.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let resolvedId = arena?.id ?? persistedId ?? uid()
        persistedId = resolvedId
        let resolvedIcon = customIcon.isEmpty ? icon : customIcon
        let examplesList = examples.split(separator: "\n")
            .map { String($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }
        var builtSubArenas: [String: [String]] = [:]
        for row in subArenaRows {
            let name = row.name.trimmingCharacters(in: .whitespaces).uppercased()
            guard !name.isEmpty else { continue }
            let rowExamples = row.examples.split(separator: "\n")
                .map { String($0.trimmingCharacters(in: .whitespaces)) }
                .filter { !$0.isEmpty }
            builtSubArenas[name] = rowExamples
        }
        let updated = Arena(
            id: resolvedId,
            label: label.trimmingCharacters(in: .whitespaces).uppercased(),
            letter: arena?.letter ?? "?",
            color: color,
            subtitle: subtitle.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            icon: resolvedIcon,
            examples: examplesList,
            subArenas: builtSubArenas,
            backgroundImageName: backgroundImageName
        )
        if let idx = store.arenas.firstIndex(where: { $0.id == resolvedId }) {
            store.arenas[idx] = updated
        } else {
            store.arenas.append(updated)
        }
        store.saveArenas()
    }

    private func handleSave() {
        persist()
        dismiss()
    }

    private func handleDelete() {
        guard let a = arena else { return }
        store.arenas.removeAll { $0.id == a.id }
        store.saveArenas()
        label = "" // prevent onDisappear persist() from re-adding
        dismiss()
    }
}

// MARK: - Background image helpers (ArenaEditorView)

private let BUNDLED_BG_IMAGES: [(name: String, label: String)] = [
    ("bg_alignment", "ALIGN"),
    ("bg_labor",     "LABOR"),
    ("bg_recharge",  "CHARGE"),
    ("bg_movement",  "MOVE"),
    ("bg_social",    "SOCIAL"),
]

private func loadPreviewImage(_ name: String) -> UIImage? {
    if let img = UIImage(named: name) { return img }
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    if let data = try? Data(contentsOf: docs.appendingPathComponent(name)) {
        return UIImage(data: data)
    }
    return nil
}

private func saveImageToDocuments(_ image: UIImage) -> String? {
    let filename = "arena_bg_\(UUID().uuidString).png"
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    guard let data = image.pngData() else { return nil }
    try? data.write(to: docs.appendingPathComponent(filename))
    return filename
}

// MARK: - PHPicker wrapper

private struct PHImagePicker: UIViewControllerRepresentable {
    var onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate, @unchecked Sendable {
        let onPick: (UIImage?) -> Void
        init(onPick: @escaping (UIImage?) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else { onPick(nil); return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                let img = obj as? UIImage
                DispatchQueue.main.async { self.onPick(img) }
            }
        }
    }
}

// MARK: - Sub-arena row view

private struct SubArenaRowView: View {
    @Binding var row: SubArenaRow
    let accentColor: Color
    let onDelete: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField("CATEGORY NAME", text: $row.name)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(accentColor)
                    .textInputAutocapitalization(.characters)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                Button { onDelete() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.red.opacity(0.5))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if expanded {
                Divider().background(Color.white.opacity(0.06))
                ZStack(alignment: .topLeading) {
                    if row.examples.isEmpty {
                        Text("Example task 1\nExample task 2")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.18))
                            .padding(12)
                    }
                    TextEditor(text: $row.examples)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .scrollDisabled(true)
                        .frame(minHeight: 70)
                        .padding(8)
                }
            }
        }
        .background(Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accentColor.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
