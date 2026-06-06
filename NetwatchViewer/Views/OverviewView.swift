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
                PingSectionView(samples: latest.ping)
                DNSSectionView(samples: latest.dns)
                HTTPSectionView(samples: latest.http)
                DownloadSectionView(samples: latest.download)
            } else {
                SectionCard(title: "Latest Data") {
                    Text("No latest data loaded.")
                        .foregroundStyle(.secondary)
                }
            }
        }
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
            subtitle: sample.ok ? "OK" : "Probe failed",
            severity: probeSeverity(ok: sample.ok)
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
            severity: probeSeverity(ok: sample.ok)
        )
    }

    private func packetLossMetric(_ latest: LatestResponse) -> DashboardMetric {
        let samples = sortedPingSamples(latest.ping)
        let maxLoss = samples.compactMap(\.lossPercent).max()

        guard !samples.isEmpty else {
            return DashboardMetric(title: "Packet Loss", value: "-", unit: "%", subtitle: "No ping probes", severity: .unknown)
        }

        let severity: MonitoringLevel
        if samples.contains(where: { !$0.ok }) {
            severity = .critical
        } else if let maxLoss, maxLoss > 0 {
            severity = .warning
        } else {
            severity = .ok
        }

        return DashboardMetric(
            title: "Packet Loss",
            value: formatMetricValue(maxLoss),
            unit: "%",
            subtitle: "Max across ping probes",
            severity: severity
        )
    }

    private func servicesMetric(_ latest: LatestResponse) -> DashboardMetric {
        let total = latest.http.count
        let okCount = latest.http.filter(\.ok).count

        guard total > 0 else {
            return DashboardMetric(title: "Services", value: "-", unit: "OK", subtitle: "No service probes", severity: .unknown)
        }

        let severity: MonitoringLevel = okCount == total ? .ok : .warning

        return DashboardMetric(
            title: "Services",
            value: "\(okCount)/\(total)",
            unit: "OK",
            subtitle: "HTTP probes healthy",
            severity: severity
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
            severity: probeSeverity(ok: sample.ok)
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

    private func probeSeverity(ok: Bool) -> MonitoringLevel {
        ok ? .ok : .critical
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
