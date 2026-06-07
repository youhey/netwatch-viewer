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
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 9) {
                    GridRow {
                        tableHeader("Status")
                        tableHeader("Service")
                        tableHeader("Group")
                        tableHeader("Category")
                        tableHeader("HTTP Status")
                        tableHeader("Total")
                        tableHeader("TTFB")
                    }

                    Divider()
                        .gridCellColumns(7)

                    ForEach(sortedSamples, id: \HTTPSample.name) { sample in
                        HTTPRowView(sample: sample, severity: evaluator.severityForHTTP(sample))
                    }
                }
                .font(.system(.callout, design: .monospaced))
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
            Text(sample.displayName ?? sample.name)
                .fontWeight(.medium)
            Text(sample.group ?? "-")
                .foregroundStyle(.secondary)
            Text(sample.category ?? "-")
                .foregroundStyle(.secondary)
            Text(formatHTTPStatus(sample.httpStatus))
                .foregroundStyle(sample.ok ? Color.secondary : Color.red)
            Text(formatMilliseconds(sample.totalMs))
                .foregroundStyle(valueColor)
            Text(formatMilliseconds(sample.ttfbMs))
                .foregroundStyle(valueColor)
        }
    }

    private var valueColor: Color {
        severity == .ok ? .primary : severity.dashboardAccentColor
    }
}

private func tableHeader(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
}
