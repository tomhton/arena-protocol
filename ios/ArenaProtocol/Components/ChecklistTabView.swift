// ChecklistTabView.swift — Arena Protocol
// Persistent checklist sliding panel + draggable tab handle

import SwiftUI
import TipKit

struct ChecklistTabView: View {
    @Environment(DataStore.self) private var store

    @State private var checklistExpanded = false
    @State private var checklistDragOffset: CGFloat = 0

    // Repositioning state
    @State private var isRepositioning = false
    @State private var repositionDrag: CGSize = .zero

    private let checklistPanelWidth: CGFloat = 320

    private var isLeading: Bool {
        store.settings.checklistTabEdge != "trailing"
    }

    private var hasUnfinishedTasks: Bool {
        let sessionCl = store.checklist(for: .session, sessionId: store.activeSession?.arena.id)
        let dayCl = store.checklist(for: .day, sessionId: nil)
        let sessionHas = sessionCl.map { cl in cl.isLocked && cl.items.contains { !$0.isCompleted } } ?? false
        let dayHas = dayCl.map { cl in cl.isLocked && cl.items.contains { !$0.isCompleted } } ?? false
        return sessionHas || dayHas
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tip (only when collapsed)
                VStack {
                    Spacer()
                    if !checklistExpanded {
                        TipView(ChecklistTabTip(), arrowEdge: isLeading ? .leading : .trailing)
                            .tipBackground(Color(hex: "#0C0C18"))
                            .frame(width: 220)
                            .padding(isLeading ? .leading : .trailing, 44)
                            .padding(.bottom, 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .trailing)
                .padding(.bottom, 100)
                .allowsHitTesting(!checklistExpanded)
                .zIndex(49)

                // Panel
                checklistSlidingPanel(screenSize: geo.size)
                    .zIndex(50)
            }
        }
    }

    // MARK: - Sliding Panel

    @ViewBuilder
    private func checklistSlidingPanel(screenSize: CGSize) -> some View {
        let defaultY = screenSize.height - 100 - 72 / 2 // bottom padding minus half tab height
        let tabY = defaultY + store.settings.checklistTabY

        VStack {
            Spacer()
            HStack(spacing: 0) {
                if isLeading {
                    panelContent(screenSize: screenSize)
                    Spacer()
                } else {
                    Spacer()
                    panelContent(screenSize: screenSize)
                }
            }
            .padding(.bottom, 100)
        }
        .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .trailing)
        // Apply vertical offset from settings
        .offset(y: store.settings.checklistTabY)
    }

    @ViewBuilder
    private func panelContent(screenSize: CGSize) -> some View {
        if checklistExpanded {
            expandedPanel(screenSize: screenSize)
        } else {
            collapsedTab(screenSize: screenSize)
        }
    }

    @ViewBuilder
    private func expandedPanel(screenSize: CGSize) -> some View {
        let panelAndTab: some View = Group {
            if isLeading {
                HStack(spacing: 0) {
                    panelView
                    checklistTabHandle
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                checklistExpanded = false
                            }
                        }
                }
            } else {
                HStack(spacing: 0) {
                    checklistTabHandle
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                checklistExpanded = false
                            }
                        }
                    panelView
                }
            }
        }

        panelAndTab
            .transition(.move(edge: isLeading ? .leading : .trailing).combined(with: .opacity))
            .gesture(
                DragGesture()
                    .onChanged { value in checklistDragOffset = value.translation.width }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            let threshold: CGFloat = 60
                            if isLeading && value.translation.width < -threshold {
                                checklistExpanded = false
                            } else if !isLeading && value.translation.width > threshold {
                                checklistExpanded = false
                            }
                            checklistDragOffset = 0
                        }
                    }
            )
    }

    @ViewBuilder
    private func collapsedTab(screenSize: CGSize) -> some View {
        checklistTabHandle
            .onTapGesture {
                guard !isRepositioning else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    checklistExpanded = true
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        guard !isRepositioning else { return }
                        checklistDragOffset = value.translation.width
                    }
                    .onEnded { value in
                        guard !isRepositioning else { return }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            let threshold: CGFloat = 60
                            if isLeading && value.translation.width > threshold {
                                checklistExpanded = true
                            } else if !isLeading && value.translation.width < -threshold {
                                checklistExpanded = true
                            }
                            checklistDragOffset = 0
                        }
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isRepositioning = true
                        }
                    }
                    .sequenced(before:
                        DragGesture()
                            .onChanged { value in
                                repositionDrag = value.translation
                            }
                            .onEnded { value in
                                commitReposition(drag: value.translation, screenSize: screenSize)
                            }
                    )
            )
            .transition(.move(edge: isLeading ? .leading : .trailing))
            // Repositioning visual offset
            .offset(repositionDrag)
            .scaleEffect(isRepositioning ? 1.1 : 1.0)
            .overlay(
                Group {
                    if isRepositioning {
                        tabShape
                            .strokeBorder(Color(hex: "#E8C547").opacity(0.5), lineWidth: 1.5)
                    }
                }
            )
    }

    // MARK: - Panel View

    private var panelView: some View {
        ChecklistPanelView(sessionId: store.activeSession?.arena.id)
            .frame(width: checklistPanelWidth, height: 380)
            .background(Color(hex: "#080810"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(hex: "#E8C547").opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 20, x: isLeading ? 4 : -4)
    }

    // MARK: - Tab Handle

    private var tabShape: UnevenRoundedRectangle {
        if isLeading {
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 0,
                bottomTrailingRadius: 12, topTrailingRadius: 12
            )
        } else {
            UnevenRoundedRectangle(
                topLeadingRadius: 12, bottomLeadingRadius: 12,
                bottomTrailingRadius: 0, topTrailingRadius: 0
            )
        }
    }

    private var checklistTabHandle: some View {
        VStack(spacing: 4) {
            if hasUnfinishedTasks {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(Color(hex: "#E8C547"))
                    .symbolEffect(.pulse, options: .repeating, value: hasUnfinishedTasks)
                    .shadow(color: Color(hex: "#E8C547").opacity(0.6), radius: 4)
            }
            Text("TO-DO")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .kerning(2)
                .foregroundStyle(
                    hasUnfinishedTasks
                        ? Color(hex: "#E8C547")
                        : Color.white.opacity(0.2)
                )
                .shadow(
                    color: hasUnfinishedTasks ? Color(hex: "#E8C547").opacity(0.5) : .clear,
                    radius: hasUnfinishedTasks ? 6 : 0
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 32, height: 72)
        .background(Color(hex: "#0C0C18").opacity(0.95))
        .clipShape(tabShape)
        .overlay(
            tabShape
                .strokeBorder(Color(hex: "#E8C547").opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Reposition Logic

    private func commitReposition(drag: CGSize, screenSize: CGSize) {
        let midX = screenSize.width / 2
        // Determine if we should flip edges
        let currentTabX: CGFloat = isLeading ? 16 : screenSize.width - 16
        let draggedX = currentTabX + drag.width

        var newEdge = store.settings.checklistTabEdge
        if isLeading && draggedX > midX {
            newEdge = "trailing"
        } else if !isLeading && draggedX < midX {
            newEdge = "leading"
        }

        // Calculate new Y offset, clamped to keep tab on screen
        let newYOffset = store.settings.checklistTabY + drag.height
        let maxY = screenSize.height * 0.3 // allow moving up quite a bit
        let minY = -(screenSize.height * 0.4)
        let clampedY = min(maxY, max(minY, newYOffset))

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            store.settings.checklistTabEdge = newEdge
            store.settings.checklistTabY = clampedY
            repositionDrag = .zero
            isRepositioning = false
        }
        store.saveSettings()
    }
}
