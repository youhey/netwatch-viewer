//
//  OverviewView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct OverviewView: View {
    let status: MonitoringStatus?
    let latest: LatestResponse?
    let thresholds: MonitoringThresholds?
    let lastUpdated: Date?
    let alertState: AlertState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            statusOverview

            LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 12) {
                ForEach(metrics) { metric in
                    MetricCard(
                        title: metric.title,
                        value: metric.value,
                        unit: metric.unit,
                        subtitle: metric.subtitle,
                        severity: metric.severity
                    )
                }
            }

            activeIssues
            alertStateDetails

            if let latest {
                PingSectionView(samples: latest.ping, evaluator: evaluator)
                DNSSectionView(samples: latest.dns, evaluator: evaluator)
                HTTPSectionView(samples: latest.http, evaluator: evaluator)
                DownloadSectionView(samples: latest.download, evaluator: evaluator)
            } else {
                SectionCard(title: "Latest Data") {
                    Text("No latest data loaded.")
                        .foregroundStyle(.secondary)
                }
            }

            thresholdsSummary
        }
    }

    private var evaluator: SeverityEvaluator {
        SeverityEvaluator(thresholds: thresholds)
    }

    private var metricColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 155), spacing: 12)
        ]
    }

    @ViewBuilder
    private var statusOverview: some View {
        if let status {
            StatusSummaryCard(status: status, updatedAt: lastUpdated)
        } else {
            SectionCard(title: "Status") {
                Text("No status loaded.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var activeIssues: some View {
        SectionCard(title: "Active Issues", subtitle: "Current monitoring reasons") {
            if let status {
                if status.reasons.isEmpty {
                    HStack(spacing: 8) {
                        SeverityChip(level: .ok)
                        Text("No active issues")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(sortedReasons(status.reasons)) { reason in
                            ActiveIssueRow(reason: reason, isPrimary: reason == status.primaryReason)
                        }
                    }
                }
            } else {
                Text("No status loaded.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var alertStateDetails: some View {
        SectionCard(title: "Alert State", subtitle: "Notification tracking") {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                overviewRow(label: "Observed ID", value: alertState.lastObservedStatusId ?? "-")
                overviewRow(label: "Observed", value: alertState.lastObservedLevel?.rawValue ?? "-")
                overviewRow(label: "Notified ID", value: alertState.lastNotifiedStatusId ?? "-")
                overviewRow(label: "Notified", value: formatOptionalDate(alertState.lastNotifiedAt))
                overviewRow(label: "Ack ID", value: alertState.acknowledgedStatusId ?? "-")
                overviewRow(label: "Muted", value: formatOptionalDate(alertState.mutedUntil))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var thresholdsSummary: some View {
        SectionCard(title: "Thresholds", subtitle: "Warning and critical bands") {
            if let thresholds {
                VStack(alignment: .leading, spacing: 6) {
                    thresholdText("Gateway RTT", band: thresholds.ping?.gatewayRttAvgMs, unit: "ms", mode: .high)
                    thresholdText("Gateway Loss", band: thresholds.ping?.gatewayLossPercent, unit: "%", mode: .high)
                    thresholdText("External RTT", band: thresholds.ping?.externalRttAvgMs, unit: "ms", mode: .high)
                    thresholdText("Packet Loss", band: thresholds.ping?.externalLossPercent, unit: "%", mode: .high)
                    thresholdText("DNS Duration", band: thresholds.dns?.durationMs, unit: "ms", mode: .high)
                    thresholdText("HTTP Total", band: thresholds.http?.totalMs, unit: "ms", mode: .high)

                    ForEach(downloadThresholdRows(thresholds), id: \.label) { row in
                        thresholdText(row.label, band: row.band, unit: "Mbps", mode: .low)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Text("Thresholds unavailable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var metrics: [DashboardMetric] {
        guard let latest else {
            return [
                DashboardMetric(title: "Gateway", value: "-", unit: "ms", subtitle: "No ping data", severity: .unknown),
                DashboardMetric(title: "External RTT", value: "-", unit: "ms", subtitle: "No ping data", severity: .unknown),
                DashboardMetric(title: "Packet Loss", value: "-", unit: "%", subtitle: "No ping data", severity: .unknown),
                DashboardMetric(title: "Services", value: "-", unit: "OK", subtitle: "No service data", severity: .unknown),
                DashboardMetric(title: "Download", value: "-", unit: "Mbps", subtitle: "No download data", severity: .unknown)
            ]
        }

        return [
            gatewayMetric(latest),
            externalRTTMetric(latest),
            packetLossMetric(latest),
            servicesMetric(latest),
            downloadMetric(latest)
        ]
    }

    private func gatewayMetric(_ latest: LatestResponse) -> DashboardMetric {
        let sample = sortedPingSamples(latest.ping).first { $0.name.caseInsensitiveCompare("gateway") == .orderedSame }

        guard let sample else {
            return DashboardMetric(title: "Gateway", value: "-", unit: "ms", subtitle: "Not reported", severity: .unknown)
        }

        return DashboardMetric(
            title: "Gateway",
            value: formatMetricValue(sample.rttAvgMs),
            unit: "ms",
            subtitle: sample.ok ? "Gateway RTT" : "Probe failed",
            severity: evaluator.severityForGatewayPing(sample)
        )
    }

    private func externalRTTMetric(_ latest: LatestResponse) -> DashboardMetric {
        let sample = sortedPingSamples(latest.ping).first { $0.name.caseInsensitiveCompare("gateway") != .orderedSame }

        guard let sample else {
            return DashboardMetric(title: "External RTT", value: "-", unit: "ms", subtitle: "Not reported", severity: .unknown)
        }

        return DashboardMetric(
            title: "External RTT",
            value: formatMetricValue(sample.rttAvgMs),
            unit: "ms",
            subtitle: sample.displayName ?? sample.name,
            severity: evaluator.severityForExternalPing(sample)
        )
    }

    private func packetLossMetric(_ latest: LatestResponse) -> DashboardMetric {
        let samples = sortedPingSamples(latest.ping)
        let maxLoss = samples.compactMap(\.lossPercent).max()

        guard !samples.isEmpty else {
            return DashboardMetric(title: "Packet Loss", value: "-", unit: "%", subtitle: "No ping probes", severity: .unknown)
        }

        return DashboardMetric(
            title: "Packet Loss",
            value: formatMetricValue(maxLoss),
            unit: "%",
            subtitle: "Max across ping probes",
            severity: evaluator.severityForPacketLossSummary(samples)
        )
    }

    private func servicesMetric(_ latest: LatestResponse) -> DashboardMetric {
        let total = latest.http.count
        let okCount = latest.http.filter(\.ok).count

        guard total > 0 else {
            return DashboardMetric(title: "Services", value: "-", unit: "OK", subtitle: "No service probes", severity: .unknown)
        }

        return DashboardMetric(
            title: "Services",
            value: "\(okCount)/\(total)",
            unit: "OK",
            subtitle: "HTTP probes healthy",
            severity: evaluator.severityForServiceSummary(latest.http)
        )
    }

    private func downloadMetric(_ latest: LatestResponse) -> DashboardMetric {
        let sample = sortedDownloadSamples(latest.download).first

        guard let sample else {
            return DashboardMetric(title: "Download", value: "-", unit: "Mbps", subtitle: "No download probes", severity: .unknown)
        }

        return DashboardMetric(
            title: "Download",
            value: formatMetricValue(sample.mbps),
            unit: "Mbps",
            subtitle: sample.displayName ?? sample.name,
            severity: evaluator.severityForDownload(sample)
        )
    }

    private func sortedPingSamples(_ samples: [PingSample]) -> [PingSample] {
        samples.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    private func sortedDownloadSamples(_ samples: [DownloadSample]) -> [DownloadSample] {
        samples.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    private func sortedReasons(_ reasons: [MonitoringReason]) -> [MonitoringReason] {
        reasons.sorted { lhs, rhs in
            (lhs.level.sortPriority, lhs.code, lhs.target ?? "", lhs.metric ?? "") < (rhs.level.sortPriority, rhs.code, rhs.target ?? "", rhs.metric ?? "")
        }
    }

    private func formatMetricValue(_ value: Double?) -> String {
        guard let value else {
            return "-"
        }

        return value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private func formatOptionalDate(_ date: Date?) -> String {
        guard let date else {
            return "-"
        }

        return date.formatted(date: .omitted, time: .standard)
    }

    private func overviewRow(label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func thresholdText(_ label: String, band: ThresholdBand?, unit: String, mode: ThresholdMode) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: 104, alignment: .leading)
            Text(formatThresholdBand(band, unit: unit, mode: mode))
                .monospacedDigit()
        }
    }

    private func formatThresholdBand(_ band: ThresholdBand?, unit: String, mode: ThresholdMode) -> String {
        guard let band else {
            return "-"
        }

        let direction = mode == .high ? ">=" : "<"
        return "warn \(direction) \(formatThresholdValue(band.warning, unit: unit)) / crit \(direction) \(formatThresholdValue(band.critical, unit: unit))"
    }

    private func formatThresholdValue(_ value: Double?, unit: String) -> String {
        guard let value else {
            return "-"
        }

        return "\(value.formatted(.number.precision(.fractionLength(0...1))))\(unit)"
    }

    private func downloadThresholdRows(_ thresholds: MonitoringThresholds) -> [DownloadThresholdRow] {
        thresholds.download?.values
            .map { key, band in
                DownloadThresholdRow(label: key.replacingOccurrences(of: "_mbps", with: ""), band: band)
            }
            .sorted { $0.label < $1.label } ?? []
    }
}

private enum ThresholdMode {
    case high
    case low
}

private struct DownloadThresholdRow {
    let label: String
    let band: ThresholdBand
}

private struct DashboardMetric: Identifiable {
    var id: String { title }

    let title: String
    let value: String
    let unit: String?
    let subtitle: String?
    let severity: MonitoringLevel
}

private struct ActiveIssueRow: View {
    let reason: MonitoringReason
    let isPrimary: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            SeverityChip(level: reason.level)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(reason.code)
                        .fontWeight(isPrimary ? .semibold : .regular)

                    if isPrimary {
                        Text("Primary")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(reason.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
