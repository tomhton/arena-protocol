// ProtocolsInlineView.swift — Arena Protocol
// Horizontal protocol cards + vertical drag-to-reorder, extracted from HomeView

import SwiftUI
import TipKit

struct ProtocolsInlineView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void
    @Binding var hapticMedium: Int

    @State private var protocolReorderMode = false
    @State private var draggingProtocolId: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PROTOCOLS")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.18))
                    .kerning(5)
                Spacer()
                if protocolReorderMode {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { protocolReorderMode = false }
                    } label: {
                        Text("DONE")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#4ECDC4").opacity(0.7))
                            .kerning(2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#4ECDC4").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { navigate(.protocols) } label: {
                        Text("ALL →")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .kerning(2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            TipView(ProtocolReorderTip(), arrowEdge: .bottom)
                .tipBackground(Color(hex: "#0C0C18"))
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            if protocolReorderMode {
                // Vertical drag-to-reorder list
                VStack(spacing: 4) {
                    ForEach(Array(store.protocols.enumerated()), id: \.element.id) { idx, proto in
                        let c = Color(hex: proto.color)
                        let isDragging = draggingProtocolId == proto.id

                        HStack(spacing: 10) {
                            Text("≡")
                                .font(.system(size: 16, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.2))
                            Text(proto.glyph)
                                .font(.system(size: 13))
                                .foregroundStyle(c.opacity(0.7))
                            Text(proto.name)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(c.opacity(0.8))
                                .kerning(1)
                                .lineLimit(1)
                            Spacer()
                            Text("\(proto.blocks.count) blocks")
                                .font(.system(size: 7, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.2))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(isDragging ? c.opacity(0.08) : c.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isDragging ? c.opacity(0.25) : c.opacity(0.08), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .opacity(isDragging ? 0.7 : 1)
                        .scaleEffect(isDragging ? 1.03 : 1)
                        .animation(.easeInOut(duration: 0.15), value: isDragging)
                        .draggable(proto.id) {
                            HStack(spacing: 6) {
                                Text(proto.glyph).font(.system(size: 12))
                                Text(proto.name)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(c)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onAppear { draggingProtocolId = proto.id }
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let draggedId = items.first,
                                  let fromIdx = store.protocols.firstIndex(where: { $0.id == draggedId }),
                                  let toIdx = store.protocols.firstIndex(where: { $0.id == proto.id }),
                                  fromIdx != toIdx else { return false }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.protocols.move(fromOffsets: IndexSet(integer: fromIdx),
                                                     toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx)
                                store.saveProtocols()
                            }
                            draggingProtocolId = nil
                            return true
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            } else {
                // Normal horizontal scroll — long press activates reorder
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(store.protocols) { proto in
                            let c = Color(hex: proto.color)
                            Button { navigate(.activeProtocol(proto)) } label: {
                                HStack(spacing: 8) {
                                    Text(proto.glyph)
                                        .font(.system(size: 13))
                                        .foregroundStyle(c.opacity(0.7))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(proto.name)
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundStyle(c.opacity(0.8))
                                            .kerning(1)
                                            .lineLimit(1)
                                        Text("\(proto.blocks.count) blocks · \(proto.blocks.reduce(0) { $0 + $1.duration })m")
                                            .font(.system(size: 7, design: .monospaced))
                                            .foregroundStyle(Color.white.opacity(0.2))
                                            .kerning(1)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(c.opacity(0.04))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(c.opacity(0.1), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                                hapticMedium += 1
                                withAnimation(.easeInOut(duration: 0.25)) { protocolReorderMode = true }
                            })
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 14)
            }
        }
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color.white.opacity(0.03), lineWidth: 1))
        .padding(.horizontal, 12)
    }
}
