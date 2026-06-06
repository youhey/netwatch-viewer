//
//  DNSSectionView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct DNSSectionView: View {
    let samples: [DNSSample]

    private var sortedSamples: [DNSSample] {
        samples.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DNS")
                .font(.headline)

            if samples.isEmpty {
                Text("No DNS samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    ForEach(sortedSamples, id: \DNSSample.name) { sample in
                        DNSRowView(sample: sample)
                    }
                }
            }
        }
    }
}

private struct DNSRowView: View {
    let sample: DNSSample

    var body: some View {
        GridRow {
            StatusDot(ok: sample.ok)
            VStack(alignment: .leading, spacing: 2) {
                Text(sample.displayName ?? sample.name)
                    .fontWeight(.medium)
                Text(sample.hostname ?? "-")
                    .foregroundStyle(.secondary)
            }
            Text(formatMilliseconds(sample.durationMs))
        }
    }
}
