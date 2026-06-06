//
//  DownloadSectionView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct DownloadSectionView: View {
    let samples: [DownloadSample]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Download")
                .font(.headline)

            if samples.isEmpty {
                Text("No download samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    ForEach(samples, id: \DownloadSample.name) { sample in
                        DownloadRowView(sample: sample)
                    }
                }
                .font(.system(.body, design: .monospaced))
            }
        }
    }
}

private struct DownloadRowView: View {
    let sample: DownloadSample

    var body: some View {
        GridRow {
            StatusDot(ok: sample.ok)
            Text(sample.name)
                .fontWeight(.medium)
            Text(formatMbps(sample.mbps))
                .foregroundStyle(sample.ok ? Color.primary : Color.red)
            Text(formatMilliseconds(sample.durationMs))
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
}
