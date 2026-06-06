//
//  PingSectionView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct PingSectionView: View {
    let samples: [PingSample]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ping")
                .font(.headline)

            if samples.isEmpty {
                Text("No ping samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    ForEach(samples, id: \PingSample.name) { sample in
                        PingRowView(sample: sample)
                    }
                }
                .font(.system(.body, design: .monospaced))
            }
        }
    }
}

private struct PingRowView: View {
    let sample: PingSample

    var body: some View {
        GridRow {
            StatusDot(ok: sample.ok)
            Text(sample.name)
                .fontWeight(.medium)
            Text(sample.target ?? "-")
                .foregroundStyle(.secondary)
            Text(formatMilliseconds(sample.rttAvgMs))
            Text("loss \(formatPercent(sample.lossPercent))")
                .foregroundStyle(.secondary)
            Text("min \(formatMilliseconds(sample.rttMinMs))")
                .foregroundStyle(.secondary)
            Text("max \(formatMilliseconds(sample.rttMaxMs))")
                .foregroundStyle(.secondary)
        }
    }
}
