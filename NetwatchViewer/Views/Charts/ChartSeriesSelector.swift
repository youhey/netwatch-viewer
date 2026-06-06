//
//  ChartSeriesSelector.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct ChartSelectableItem: Identifiable {
    let id: String
    let title: String
    let color: Color
}

struct ChartSeriesSelector: View {
    let items: [ChartSelectableItem]
    @Binding var selectedIDs: Set<String>

    var body: some View {
        if items.count > 1 {
            FlowLayout(spacing: 8) {
                ForEach(items) { item in
                    Button {
                        toggle(item)
                    } label: {
                        Label(item.title, systemImage: isSelected(item) ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(isSelected(item) ? item.color : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected(item) ? item.color.opacity(0.14) : Color.secondary.opacity(0.08))
                    )
                }
            }
        }
    }

    private func isSelected(_ item: ChartSelectableItem) -> Bool {
        selectedIDs.isEmpty || selectedIDs.contains(item.id)
    }

    private func toggle(_ item: ChartSelectableItem) {
        if selectedIDs.isEmpty {
            selectedIDs = [item.id]
            return
        }

        var nextSelection = selectedIDs
        if nextSelection.contains(item.id) {
            nextSelection.remove(item.id)
        } else {
            nextSelection.insert(item.id)
        }

        selectedIDs = nextSelection.isEmpty || nextSelection.count >= items.count ? [] : nextSelection
    }
}

enum ChartSeriesPalette {
    private static let colors: [Color] = [
        .blue,
        .green,
        .orange,
        .purple,
        .pink,
        .teal,
        .indigo,
        .mint,
        .brown,
        .cyan
    ]

    static func color(at index: Int) -> Color {
        colors[index % colors.count]
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? rows.map(\.width).max() ?? 0,
            height: rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY

        for row in rows(for: proposal, subviews: subviews) {
            var x = bounds.minX

            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }

            y += row.height + spacing
        }
    }

    private func rows(for proposal: ProposedViewSize, subviews: Subviews) -> [FlowLayoutRow] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [FlowLayoutRow] = []
        var currentItems: [FlowLayoutItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = currentItems.isEmpty ? size.width : currentWidth + spacing + size.width

            if nextWidth > maxWidth, !currentItems.isEmpty {
                rows.append(FlowLayoutRow(items: currentItems, width: currentWidth, height: currentHeight))
                currentItems = []
                currentWidth = 0
                currentHeight = 0
            }

            currentItems.append(FlowLayoutItem(subview: subview, size: size))
            currentWidth = currentItems.count == 1 ? size.width : currentWidth + spacing + size.width
            currentHeight = max(currentHeight, size.height)
        }

        if !currentItems.isEmpty {
            rows.append(FlowLayoutRow(items: currentItems, width: currentWidth, height: currentHeight))
        }

        return rows
    }
}

private struct FlowLayoutRow {
    let items: [FlowLayoutItem]
    let width: CGFloat
    let height: CGFloat
}

private struct FlowLayoutItem {
    let subview: LayoutSubview
    let size: CGSize
}
