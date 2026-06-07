//
//  DownloadSectionView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct DownloadSectionView: View {
    let samples: [DownloadSample]
    let evaluator: SeverityEvaluator

    private var sortedSamples: [DownloadSample] {
        samples.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    var body: some View {
        SectionCard(title: "Download", subtitle: "Latest throughput probes", systemImage: "arrow.down.circle") {
            if samples.isEmpty {
                Text("No download samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 9) {
                    GridRow {
                        tableHeader("Status")
                        tableHeader("Target")
                        tableHeader("Speed")
                        tableHeader("Duration")
                    }

                    Divider()
                        .gridCellColumns(4)

                    ForEach(sortedSamples, id: \DownloadSample.name) { sample in
                        DownloadRowView(sample: sample, severity: evaluator.severityForDownload(sample))
                    }
                }
                .font(.system(.callout, design: .monospaced))
            }
        }
    }
}

private struct DownloadRowView: View {
    let sample: DownloadSample
    let severity: MonitoringLevel

    var body: some View {
        GridRow {
            SeverityChip(level: severity)
            Text(sample.displayName ?? sample.name)
                .fontWeight(.medium)
            Text(formatMbps(sample.mbps))
                .foregroundStyle(valueColor)
            Text(formatMilliseconds(sample.durationMs))
                .foregroundStyle(valueColor)
        }

        if let error = sample.error, !error.isEmpty {
            GridRow {
                Text("")
                Text(error)
                    .foregroundStyle(.red)
                    .gridCellColumns(3)
            }
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
