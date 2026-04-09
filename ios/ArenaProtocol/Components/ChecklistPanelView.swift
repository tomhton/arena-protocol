// ChecklistPanelView.swift — Arena Protocol
// Retractable checklist panel — scoped to session/day/week/month/year.
// Progressive disclosure: add items one at a time, lock in, then check off.

import SwiftUI

struct ChecklistPanelView: View {
    @Environment(DataStore.self) private var store
    let sessionId: String?

    @State private var activeScope: ChecklistScope = .day
    @State private var draftItems: [ChecklistItem] = [ChecklistItem(text: "")]
    @State private var isEditing: Bool = true
    @State private var currentChecklistId: String? = nil
    @State private var hapticToggleTrigger: Int = 0
    @State private var hapticLockTrigger: Int = 0
    @FocusState private var focusedItemId: String?

    private let gold = Color(hex: "#E8C547")

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            scopeTabBar
            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if isEditing {
                        draftMode
                    } else {
                        lockedMode
                    }
                }
                .padding(.top, 8)
                .onChange(of: draftItems.count) { _, _ in
                    if let lastId = draftItems.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color(hex: "#080810"))
        .sensoryFeedback(.selection, trigger: hapticToggleTrigger)
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticLockTrigger)
        .onAppear { loadChecklist() }
        .onChange(of: activeScope) { _, _ in loadChecklist() }
    }

    // MARK: - Panel Header

    private var panelHeader: some View {
        Text("CHECKLIST")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(gold.opacity(0.55))
            .kerning(5)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }

    // MARK: - Scope Tabs

    private var scopeTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ChecklistScope.allCases, id: \.self) { scope in
                    if scope == .session && sessionId == nil { EmptyView() } else {
                        let active = activeScope == scope
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { activeScope = scope }
                        } label: {
                            Text(scope.displayName)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(active ? gold : Color.white.opacity(0.25))
                                .kerning(2)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(active ? gold.opacity(0.1) : Color.white.opacity(0.03))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(active ? gold.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Draft Mode (Adding Items)

    private var draftMode: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(draftItems.enumerated()), id: \.element.id) { idx, item in
                HStack(spacing: 10) {
                    // Number badge
                    Text("\(idx + 1)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(gold.opacity(0.3))
                        .frame(width: 18, height: 18)
                        .background(gold.opacity(0.06))
                        .clipShape(Circle())

                    TextField("", text: bindingForDraft(id: item.id), prompt:
                        Text("Enter task...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.12))
                    )
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .focused($focusedItemId, equals: item.id)
                    .submitLabel(.next)
                    .onSubmit {
                        if !item.text.trimmingCharacters(in: .whitespaces).isEmpty {
                            addDraftItem()
                        }
                    }

                    // Remove button (only if more than 1 item)
                    if draftItems.count > 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                draftItems.removeAll { $0.id == item.id }
                            }
                        } label: {
                            Text("×")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.15))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .id(item.id)

                if idx < draftItems.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.03))
                        .frame(height: 1)
                        .padding(.leading, 44)
                        .padding(.trailing, 16)
                }
            }

            // Add button
            let lastHasText = !(draftItems.last?.text.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            Button { addDraftItem() } label: {
                HStack(spacing: 8) {
                    Text("+")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    Text("ADD TASK")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .kerning(2)
                }
                .foregroundStyle(lastHasText ? gold.opacity(0.6) : Color.white.opacity(0.12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(lastHasText ? gold.opacity(0.04) : Color.white.opacity(0.01))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(lastHasText ? gold.opacity(0.15) : Color.white.opacity(0.04), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!lastHasText)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Lock In button
            let hasAnyText = draftItems.contains { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
            Button { lockIn() } label: {
                Text("LOCK IN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(hasAnyText ? Color(hex: "#080810") : Color.white.opacity(0.15))
                    .kerning(3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(hasAnyText ? gold : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!hasAnyText)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Locked Mode (Checklist)

    private var lockedMode: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Progress header
            if let cl = currentChecklist {
                let done = cl.items.filter(\.isCompleted).count
                let total = cl.items.count
                HStack {
                    Text("\(done)/\(total) COMPLETE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(done == total ? Color(hex: "#34D399") : gold.opacity(0.6))
                        .kerning(2)
                    Spacer()
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.06))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(done == total ? Color(hex: "#34D399").opacity(0.6) : gold.opacity(0.4))
                                .frame(width: geo.size.width * (total > 0 ? CGFloat(done) / CGFloat(total) : 0))
                                .animation(.easeInOut(duration: 0.3), value: done)
                        }
                    }
                    .frame(width: 80, height: 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Items
                ForEach(cl.items) { item in
                    Button {
                        hapticToggleTrigger += 1
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.toggleChecklistItem(checklistId: cl.id, itemId: item.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            // Gold left accent bar
                            RoundedRectangle(cornerRadius: 2)
                                .fill(item.isCompleted ? Color(hex: "#34D399").opacity(0.4) : gold.opacity(0.25))
                                .frame(width: 3, height: 28)

                            // Checkbox
                            ZStack {
                                Circle()
                                    .strokeBorder(item.isCompleted ? Color(hex: "#34D399").opacity(0.6) : Color.white.opacity(0.15), lineWidth: 1.5)
                                    .frame(width: 20, height: 20)
                                if item.isCompleted {
                                    Text("✓")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color(hex: "#34D399"))
                                }
                            }

                            // Text
                            Text(item.text)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(item.isCompleted ? Color.white.opacity(0.15) : Color.white.opacity(0.85))
                                .strikethrough(item.isCompleted, color: Color.white.opacity(0.15))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)

                    if item.id != cl.items.last?.id {
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(height: 1)
                            .padding(.leading, 52)
                            .padding(.trailing, 16)
                    }
                }

                // Unlock button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        draftItems = cl.items.isEmpty ? [ChecklistItem(text: "")] : cl.items
                        isEditing = true
                    }
                } label: {
                    Text("UNLOCK")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .kerning(2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            } else {
                ContentUnavailableView {
                    Label("No Tasks", systemImage: "checklist")
                        .foregroundStyle(Color.white.opacity(0.2))
                } description: {
                    Text("Switch to draft mode to add tasks.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.12))
                }
                .padding(.top, 32)
            }
        }
    }

    // MARK: - Helpers

    private var currentChecklist: Checklist? {
        store.checklist(for: activeScope, sessionId: sessionId)
    }

    private func bindingForDraft(id: String) -> Binding<String> {
        Binding(
            get: { draftItems.first(where: { $0.id == id })?.text ?? "" },
            set: { newValue in
                if let idx = draftItems.firstIndex(where: { $0.id == id }) {
                    draftItems[idx].text = newValue
                }
            }
        )
    }

    private func addDraftItem() {
        let new = ChecklistItem(text: "")
        withAnimation(.easeInOut(duration: 0.2)) {
            draftItems.append(new)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedItemId = new.id
        }
    }

    private func lockIn() {
        hapticLockTrigger += 1

        let validItems = draftItems.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !validItems.isEmpty else { return }

        var cl = currentChecklist ?? Checklist(
            scope: activeScope,
            periodKey: Checklist.periodKey(for: activeScope, sessionId: sessionId),
            items: [],
            createdAt: Date().timeIntervalSince1970 * 1000
        )
        cl.items = validItems
        cl.isLocked = true
        currentChecklistId = cl.id
        store.upsertChecklist(cl)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isEditing = false
        }
    }

    private func loadChecklist() {
        if let existing = store.checklist(for: activeScope, sessionId: sessionId) {
            currentChecklistId = existing.id
            if existing.isLocked {
                isEditing = false
            } else {
                draftItems = existing.items.isEmpty ? [ChecklistItem(text: "")] : existing.items
                isEditing = true
            }
        } else {
            currentChecklistId = nil
            draftItems = [ChecklistItem(text: "")]
            isEditing = true
        }
    }
}
