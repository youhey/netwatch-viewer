//
//  DNSSectionView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct DNSSectionView: View {
    let samples: [DNSSample]
    let evaluator: SeverityEvaluator

    private var sortedSamples: [DNSSample] {
        samples.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    var body: some View {
        SectionCard(title: "DNS", subtitle: "Resolver latency", systemImage: "globe") {
            if samples.isEmpty {
                Text("No DNS samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 9) {
                    GridRow {
                        tableHeader("Status")
                        tableHeader("Name")
                        tableHeader("Duration")
                    }

                    Divider()
                        .gridCellColumns(3)

                    ForEach(sortedSamples, id: \DNSSample.name) { sample in
                        DNSRowView(sample: sample, severity: evaluator.severityForDNS(sample))
                    }
                }
                .font(.system(.callout, design: .monospaced))
            }
        }
    }
}

private struct DNSRowView: View {
    let sample: DNSSample
    let severity: MonitoringLevel

    var body: some View {
        GridRow {
            SeverityChip(level: severity)
            Text(sample.displayName ?? sample.name)
                .fontWeight(.medium)
            Text(formatMilliseconds(sample.durationMs))
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
        .foregroundStyle(Color.white.opacity(0.72))
}
