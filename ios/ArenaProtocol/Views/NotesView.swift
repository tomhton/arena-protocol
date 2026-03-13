// NotesView.swift — Arena Protocol
// Quick idea capture — raw thoughts, no filter

import SwiftUI

struct NotesView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var input = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button { navigate(.home) } label: {
                Text("← BACK")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .kerning(4)
            }
            .buttonStyle(.plain)
            .padding(.top, 52)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)

            HStack(spacing: 4) {
                Text("CAPTURE")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)

            HStack(spacing: 4) {
                Text("IDEA")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .kerning(3)
                Text("!")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#E8C547"))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)

            Text("Raw thoughts. No filter. Capture now, refine later.")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.3))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

            // Input area
            HStack(spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if input.isEmpty {
                        Text("What just hit you?")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.2))
                            .padding(14)
                    }
                    TextEditor(text: $input)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 50)
                        .padding(10)
                        .focused($inputFocused)
                }
                .background(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button { addNote() } label: {
                    Text("+")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "#080810"))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "#E8C547"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            // Notes list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if store.ideas.isEmpty {
                        Text("NO IDEAS YET")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.18))
                            .kerning(3)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    }
                    ForEach(store.ideas) { note in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.text)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.white.opacity(0.8))
                                    .lineSpacing(4)
                                Text(note.ts)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.2))
                                    .kerning(2)
                            }
                            Spacer()
                            Button { deleteNote(note.id) } label: {
                                Text("×")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.2))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.07), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .onAppear { inputFocused = true }
    }

    private func addNote() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let fmt = DateFormatter(); fmt.dateStyle = .short
        let note = IdeaNote(id: Date().timeIntervalSince1970, text: text, ts: fmt.string(from: Date()))
        store.ideas.insert(note, at: 0)
        store.saveIdeas()
        input = ""
    }

    private func deleteNote(_ id: Double) {
        store.ideas.removeAll { $0.id == id }
        store.saveIdeas()
    }
}
