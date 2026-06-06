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
        SectionCard(title: "Ping", subtitle: "Latest RTT and packet loss") {
            if samples.isEmpty {
                Text("No ping samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    ForEach(sortedSamples, id: \PingSample.name) { sample in
                        PingRowView(sample: sample, severity: evaluator.severityForPing(sample))
                    }
                }
                .font(.system(.body, design: .monospaced))
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
            Text(sample.target ?? "-")
                .foregroundStyle(.secondary)
            Text(formatMilliseconds(sample.rttAvgMs))
                .foregroundStyle(valueColor)
            Text("loss \(formatPercent(sample.lossPercent))")
                .foregroundStyle(valueColor)
            Text("min \(formatMilliseconds(sample.rttMinMs))")
                .foregroundStyle(.secondary)
            Text("max \(formatMilliseconds(sample.rttMaxMs))")
                .foregroundStyle(.secondary)
        }
    }

    private var valueColor: Color {
        severity == .ok ? .primary : severity.dashboardAccentColor
    }
}
