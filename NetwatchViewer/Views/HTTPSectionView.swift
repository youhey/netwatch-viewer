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
        SectionCard(title: "Services", subtitle: "HTTP probe status and latency") {
            if samples.isEmpty {
                Text("No HTTP samples.")
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    ForEach(sortedSamples, id: \HTTPSample.name) { sample in
                        HTTPRowView(sample: sample, severity: evaluator.severityForHTTP(sample))
                    }
                }
                .font(.system(.body, design: .monospaced))
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
            Text("ttfb \(formatMilliseconds(sample.ttfbMs))")
                .foregroundStyle(.secondary)
        }
    }

    private var valueColor: Color {
        severity == .ok ? .primary : severity.dashboardAccentColor
    }
}
