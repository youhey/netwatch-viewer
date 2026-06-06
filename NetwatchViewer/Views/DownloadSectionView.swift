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
        SectionCard(title: "Download", subtitle: "Latest throughput probes") {
            if samples.isEmpty {
                Text("No download samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    ForEach(sortedSamples, id: \DownloadSample.name) { sample in
                        DownloadRowView(sample: sample, severity: evaluator.severityForDownload(sample))
                    }
                }
                .font(.system(.body, design: .monospaced))
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
            Text("\(formatBytes(sample.downloadedBytes)) / \(formatBytes(sample.expectedBytes))")
                .foregroundStyle(.secondary)
            Text(sample.ts.formatted(date: .omitted, time: .standard))
                .foregroundStyle(.secondary)
        }

        if let error = sample.error, !error.isEmpty {
            GridRow {
                Text("")
                Text(error)
                    .foregroundStyle(.red)
                    .gridCellColumns(5)
            }
        }
    }

    private var valueColor: Color {
        severity == .ok ? .primary : severity.dashboardAccentColor
    }
}
