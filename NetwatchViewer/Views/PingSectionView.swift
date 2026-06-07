//
//  PingSectionView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct PingSectionView: View {
    let samples: [PingSample]
    let evaluator: SeverityEvaluator

    private var sortedSamples: [PingSample] {
        samples.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    var body: some View {
        SectionCard(title: "Ping", subtitle: "Latest RTT and packet loss", systemImage: "network") {
            if samples.isEmpty {
                Text("No ping samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 9) {
                    GridRow {
                        tableHeader("Status")
                        tableHeader("Target")
                        tableHeader("RTT Avg")
                        tableHeader("Loss")
                    }

                    Divider()
                        .gridCellColumns(4)

                    ForEach(sortedSamples, id: \PingSample.name) { sample in
                        PingRowView(sample: sample, severity: evaluator.severityForPing(sample))
                    }
                }
                .font(.system(.callout, design: .monospaced))
            }
        }
    }
}

private struct PingRowView: View {
    let sample: PingSample
    let severity: MonitoringLevel

    var body: some View {
        GridRow {
            SeverityChip(level: severity)
            Text(sample.displayName ?? sample.name)
                .fontWeight(.medium)
            Text(formatMilliseconds(sample.rttAvgMs))
                .foregroundStyle(valueColor)
            Text(formatPercent(sample.lossPercent))
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
