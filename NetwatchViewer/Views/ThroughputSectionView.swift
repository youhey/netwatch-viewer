//
//  ThroughputSectionView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/12.
//

import SwiftUI

struct ThroughputSectionView: View {
    let throughputStatus: ThroughputStatus?
    let fallbackSamples: [DownloadSample]
    let evaluator: SeverityEvaluator

    private var sortedFallbackSamples: [DownloadSample] {
        fallbackSamples.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    private var sortedSources: [ThroughputSource] {
        (throughputStatus?.sources ?? []).sorted { lhs, rhs in
            (lhs.level.sortPriority, lhs.displayLabel, lhs.name) < (rhs.level.sortPriority, rhs.displayLabel, rhs.name)
        }
    }

    private var sortedProbes: [ThroughputProbe] {
        (throughputStatus?.allProbes ?? []).sorted { lhs, rhs in
            (lhs.level.sortPriority, lhs.displayLabel, lhs.name) < (rhs.level.sortPriority, rhs.displayLabel, rhs.name)
        }
    }

    var body: some View {
        SectionCard(title: "Throughput Status", subtitle: "Download and speedprobe health", systemImage: "arrow.down.circle") {
            if let throughputStatus {
                throughputStatusContent(throughputStatus)
            } else {
                fallbackContent
            }
        }
    }

    @ViewBuilder
    private func throughputStatusContent(_ status: ThroughputStatus) -> some View {
        if status.sources.isEmpty {
            Text("No throughput sources configured.")
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                sourceSummary

                if sortedProbes.isEmpty {
                    Text("No throughput probe results.")
                        .foregroundStyle(.secondary)
                } else {
                    probeTable
                }

                if status.issueProbes.isEmpty {
                    HStack(spacing: 8) {
                        SeverityChip(level: .ok)
                        Text("All throughput probes are healthy")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.72))
                    }
                } else {
                    issueSummary
                }
            }
        }
    }

    private var sourceSummary: some View {
        LazyVGrid(columns: [GridItem(.flexible(minimum: 0)), GridItem(.flexible(minimum: 0))], alignment: .leading, spacing: 8) {
            ForEach(sortedSources) { source in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(source.displayLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        SeverityChip(level: source.level)
                    }

                    if let observerText = observerText(source.observer) {
                        Text(observerText)
                            .font(.caption2)
                            .foregroundStyle(Color.white.opacity(0.58))
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(source.level.dashboardAccentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(source.level.dashboardAccentColor.opacity(0.20), lineWidth: 1)
                )
            }
        }
    }

    private var probeTable: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 9) {
            GridRow {
                tableHeader("Status")
                tableHeader("Probe")
                tableHeader("Speed")
                tableHeader("Duration")
            }

            Divider()
                .gridCellColumns(4)

            ForEach(Array(sortedProbes.enumerated()), id: \.offset) { _, probe in
                ThroughputProbeRowView(probe: probe)
            }
        }
        .font(.system(.callout, design: .monospaced))
    }

    private var issueSummary: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Issues")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.72))

            ForEach(Array(sortedProbes.filter(\.isIssue).enumerated()), id: \.offset) { _, probe in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    SeverityChip(level: probe.level)

                    Text(probe.displayLabel)
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text(probe.reason ?? probe.status ?? "Throughput issue")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.68))
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var fallbackContent: some View {
        if fallbackSamples.isEmpty {
            Text("Throughput status unavailable.")
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

                ForEach(sortedFallbackSamples, id: \.name) { sample in
                    DownloadRowView(sample: sample, severity: evaluator.severityForDownload(sample))
                }
            }
            .font(.system(.callout, design: .monospaced))
        }
    }

    private func observerText(_ observer: ThroughputObserver?) -> String? {
        guard let observer else {
            return nil
        }

        let parts = [observer.hostname, observer.interface, observer.linkSpeed, observer.operstate]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else {
                    return nil
                }
                return value
            }

        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }
}

private struct ThroughputProbeRowView: View {
    let probe: ThroughputProbe

    var body: some View {
        GridRow {
            SeverityChip(level: probe.level)
            Text(probe.displayLabel)
                .fontWeight(.medium)
            Text(formatMbps(probe.mbps))
                .foregroundStyle(valueColor)
            Text(formatMilliseconds(probe.durationMs))
                .foregroundStyle(valueColor)
        }

        if let reason = probe.reason, !reason.isEmpty {
            GridRow {
                Text("")
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(probe.level.dashboardAccentColor)
                    .gridCellColumns(3)
            }
        }
    }

    private var valueColor: Color {
        probe.level == .ok ? .primary : probe.level.dashboardAccentColor
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
