//
//  HTTPSectionView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct HTTPSectionView: View {
    let samples: [HTTPSample]
    let evaluator: SeverityEvaluator

    private var sortedSamples: [HTTPSample] {
        samples.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    var body: some View {
        SectionCard(title: "Service", subtitle: "HTTP probe status and latency", systemImage: "server.rack") {
            if samples.isEmpty {
                Text("No HTTP samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 11) {
                    GridRow {
                        tableHeader("Status")
                        tableHeader("Service")
                        tableHeader("Group")
                        tableHeader("Category")
                        tableHeader("HTTP")
                        tableHeader("Total")
                        tableHeader("TTFB")
                    }

                    Divider()
                        .gridCellColumns(7)

                    ForEach(sortedSamples, id: \HTTPSample.name) { sample in
                        HTTPRowView(sample: sample, severity: evaluator.severityForHTTP(sample))
                    }
                }
                .font(.system(size: 13, design: .monospaced))
            }
        }
    }
}

private struct HTTPRowView: View {
    let sample: HTTPSample
    let severity: MonitoringLevel

    var body: some View {
        GridRow {
            SeverityChip(level: severity)
                .padding(.vertical, 3)
            Text(sample.displayName ?? sample.name)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .padding(.vertical, 3)
            Text(sample.group ?? "-")
                .foregroundStyle(tableSecondary)
                .padding(.vertical, 3)
            Text(sample.category ?? "-")
                .foregroundStyle(tableSecondary)
                .padding(.vertical, 3)
            Text(formatHTTPStatus(sample.httpStatus))
                .foregroundStyle(sample.ok ? tableSecondary : Color.red)
                .padding(.vertical, 3)
            Text(formatMilliseconds(sample.totalMs))
                .foregroundStyle(valueColor)
                .padding(.vertical, 3)
            Text(formatMilliseconds(sample.ttfbMs))
                .foregroundStyle(valueColor)
                .padding(.vertical, 3)
        }
    }

    private var valueColor: Color {
        severity == .ok ? .primary : severity.dashboardAccentColor
    }

    private var tableSecondary: Color {
        Color.white.opacity(0.68)
    }
}

private func tableHeader(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(Color.white.opacity(0.72))
}
