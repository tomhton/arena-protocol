// AppShortcutsBar.swift — Arena Protocol
// Scrollable dock of quick-launch app shortcuts with long-press edit mode

import SwiftUI

// MARK: - Curated catalog

let CURATED_DOCK_APPS: [DockApp] = [
    DockApp(id: "spotify",    name: "Spotify",     urlScheme: "spotify://",             sfSymbol: "music.note",              brandColor: "#1DB954"),
    DockApp(id: "applemusic", name: "Apple Music", urlScheme: "music://",               sfSymbol: "music.note.list",         brandColor: "#FA2D48"),
    DockApp(id: "audible",    name: "Audible",     urlScheme: "audible://",             sfSymbol: "headphones",              brandColor: "#F47920"),
    DockApp(id: "youtube",    name: "YouTube",     urlScheme: "youtube://",             sfSymbol: "play.rectangle.fill",     brandColor: "#FF0000"),
    DockApp(id: "health",     name: "Health",      urlScheme: "x-apple-health://",      sfSymbol: "heart.fill",              brandColor: "#FF2D55"),
    DockApp(id: "gcalendar",  name: "Calendar",    urlScheme: "googlecalendar://",      sfSymbol: "calendar",                brandColor: "#1A73E8"),
    DockApp(id: "notion",     name: "Notion",      urlScheme: "notion://",              sfSymbol: "doc.text.fill",           brandColor: "#E8E8E8"),
    DockApp(id: "headspace",  name: "Headspace",   urlScheme: "headspace://",           sfSymbol: "brain.head.profile",      brandColor: "#FF9800"),
    DockApp(id: "nikerun",    name: "Nike Run",    urlScheme: "nikerunclub://",         sfSymbol: "figure.run",              brandColor: "#FA5400"),
    DockApp(id: "strava",     name: "Strava",      urlScheme: "strava://",              sfSymbol: "figure.outdoor.cycle",    brandColor: "#FC4C02"),
    DockApp(id: "whatsapp",   name: "WhatsApp",    urlScheme: "whatsapp://",            sfSymbol: "message.fill",            brandColor: "#25D366"),
    DockApp(id: "messages",   name: "Messages",    urlScheme: "sms://",                 sfSymbol: "bubble.left.fill",        brandColor: "#34C759"),
    DockApp(id: "phone",      name: "Phone",       urlScheme: "tel://",                 sfSymbol: "phone.fill",              brandColor: "#4CD964"),
    DockApp(id: "safari",     name: "Safari",      urlScheme: "https://",               sfSymbol: "safari",                  brandColor: "#006CFF"),
    DockApp(id: "instagram",  name: "Instagram",   urlScheme: "instagram://",           sfSymbol: "camera.fill",             brandColor: "#E1306C"),
    DockApp(id: "twitter",    name: "X",           urlScheme: "twitter://",             sfSymbol: "xmark",                   brandColor: "#E8E8E8"),
    DockApp(id: "linkedin",   name: "LinkedIn",    urlScheme: "linkedin://",            sfSymbol: "person.crop.square.fill", brandColor: "#0A66C2"),
    DockApp(id: "notes",      name: "Notes",       urlScheme: "mobilenotes://",         sfSymbol: "note.text",               brandColor: "#FFD60A"),
    DockApp(id: "reminders",  name: "Reminders",   urlScheme: "x-apple-reminderkit://", sfSymbol: "checkmark.circle.fill",   brandColor: "#FF3B30"),
    DockApp(id: "calm",       name: "Calm",        urlScheme: "calm://",                sfSymbol: "moon.fill",               brandColor: "#4A90D9"),
]

// MARK: - App Shortcuts Bar

struct AppShortcutsBar: View {
    @Environment(DataStore.self) private var store
    @State private var editMode = false
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.dockApps) { app in
                        DockIconView(
                            app: app,
                            editMode: editMode,
                            onDelete: {
                                store.dockApps.removeAll { $0.id == app.id }
                                store.saveDockApps()
                            }
                        )
                    }
                    if editMode {
                        AddDockButton { showPicker = true }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3)) { editMode = true }
                    }
            )

            if editMode {
                Button("DONE") {
                    withAnimation(.spring(response: 0.3)) { editMode = false }
                }
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.bottom, 6)
            }
        }
        .sheet(isPresented: $showPicker) {
            DockAppPickerSheet(
                existing: store.dockApps.map(\.id),
                onAdd: { app in
                    store.dockApps.append(app)
                    store.saveDockApps()
                }
            )
        }
    }
}

// MARK: - Dock Icon

struct DockIconView: View {
    let app: DockApp
    let editMode: Bool
    let onDelete: () -> Void

    @State private var shakeAngle: Double = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: launchApp) {
                VStack(spacing: 5) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: app.brandColor).opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: app.sfSymbol)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color(hex: app.brandColor))
                    }
                    Text(app.name.uppercased())
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(Color(hex: app.brandColor).opacity(0.8))
                        .lineLimit(1)
                        .frame(width: 56)
                }
            }
            .buttonStyle(.plain)
            .disabled(editMode)
            .rotationEffect(.degrees(shakeAngle))
            .onChange(of: editMode) { _, new in
                if new {
                    withAnimation(.easeInOut(duration: 0.13).repeatForever(autoreverses: true)) {
                        shakeAngle = 2.5
                    }
                } else {
                    withAnimation(.spring(response: 0.2)) {
                        shakeAngle = 0
                    }
                }
            }
            .onAppear {
                if editMode {
                    withAnimation(.easeInOut(duration: 0.13).repeatForever(autoreverses: true)) {
                        shakeAngle = 2.5
                    }
                }
            }

            if editMode {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .background(Circle().fill(Color.black.opacity(0.6)).padding(2))
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
            }
        }
    }

    private func launchApp() {
        guard let url = URL(string: app.urlScheme) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Add Button

struct AddDockButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
                Text("ADD")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Picker Sheet

struct DockAppPickerSheet: View {
    let existing: [String]
    let onAdd: (DockApp) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showCustomForm = false
    @State private var customName = ""
    @State private var customScheme = ""
    @State private var customSymbol = "app.fill"

    private var available: [DockApp] {
        CURATED_DOCK_APPS.filter { !existing.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if showCustomForm {
                    customForm
                } else {
                    curatedList
                }
            }
            .navigationTitle(showCustomForm ? "Custom App" : "Add App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if showCustomForm { showCustomForm = false } else { dismiss() }
                    }
                    .foregroundStyle(Color(hex: "#E8C547"))
                }
                if showCustomForm {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addCustom() }
                            .foregroundStyle(Color(hex: "#E8C547"))
                            .disabled(customName.isEmpty || customScheme.isEmpty)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var curatedList: some View {
        List {
            ForEach(available) { app in
                Button {
                    onAdd(app)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: app.brandColor).opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: app.sfSymbol)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(hex: app.brandColor))
                        }
                        Text(app.name)
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                .listRowBackground(Color.white.opacity(0.04))
            }

            Button {
                showCustomForm = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 36, height: 36)
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Text("Custom…")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                }
            }
            .listRowBackground(Color.white.opacity(0.04))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }

    private var customForm: some View {
        Form {
            Section("App Name") {
                TextField("e.g. Bear", text: $customName)
                    .autocorrectionDisabled()
            }
            Section("URL Scheme") {
                TextField("e.g. bear://", text: $customScheme)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            Section {
                TextField("e.g. doc.text", text: $customSymbol)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                HStack(spacing: 10) {
                    Image(systemName: customSymbol.isEmpty ? "app.fill" : customSymbol)
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: "#E8C547"))
                        .frame(width: 36)
                    Text("Preview")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("SF Symbol")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }

    private func addCustom() {
        let id = "custom_\(UUID().uuidString.prefix(8))"
        let app = DockApp(
            id: id,
            name: customName,
            urlScheme: customScheme,
            sfSymbol: customSymbol.isEmpty ? "app.fill" : customSymbol,
            brandColor: "#E8C547"
        )
        onAdd(app)
        dismiss()
    }
}
