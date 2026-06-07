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
        HStack(alignment: .top, spacing: 16) {
            mainColumn
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)

            sidebar
                .frame(width: 300, alignment: .topLeading)
        }
    }

    private var mainColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            statusOverview
            metricsGrid
            activeIssues
            detailSections
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            statusHistory
            latencyMiniChart
            thresholdsSummary
            systemInfo
        }
        .frame(width: 300, alignment: .topLeading)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 12) {
            ForEach(metrics) { metric in
                MetricCard(
                    title: metric.title,
                    value: metric.value,
                    unit: metric.unit,
                    subtitle: metric.subtitle,
                    severity: metric.severity,
                    systemImage: metric.systemImage,
                    sparkline: metric.sparkline
                )
            }
        }
    }

    @ViewBuilder
    private var detailSections: some View {
        if let latest {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    PingSectionView(samples: latest.ping, evaluator: evaluator)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)

                    DNSSectionView(samples: latest.dns, evaluator: evaluator)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)

                    DownloadSectionView(samples: latest.download, evaluator: evaluator)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                }

                HTTPSectionView(samples: latest.http, evaluator: evaluator)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        } else {
            SectionCard(title: "Latest Data") {
                Text("No latest data loaded.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusHistory: some View {
        SectionCard(title: "Status History", subtitle: "Last 24h") {
            VStack(alignment: .leading, spacing: 10) {
                if let status {
                    HStack(spacing: 4) {
                        ForEach(0..<18, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index == 17 ? status.level.dashboardAccentColor : status.level.dashboardAccentColor.opacity(0.28))
                                .frame(height: index == 17 ? 18 : 12)
                        }
                    }
                    .frame(height: 20)

                    HStack {
                        SeverityChip(level: status.level)
                        Text("Current state only")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No status history available yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var latencyMiniChart: some View {
        SectionCard(title: "Latency", subtitle: "Current ping probes") {
            if let latest, !latest.ping.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(sortedPingSamples(latest.ping).prefix(3)), id: \.name) { sample in
                        LatencyMiniRow(sample: sample, severity: evaluator.severityForPing(sample))
                    }
                }
            } else {
                Text("No latency data loaded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var systemInfo: some View {
        SectionCard(title: "System Info", subtitle: "Viewer runtime") {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 7) {
                overviewRow(label: "Viewer", value: viewerVersion)
                overviewRow(label: "API", value: "http://netpi:8080")
                overviewRow(label: "Refresh", value: "10s")
                overviewRow(label: "Updated", value: formatOptionalDate(lastUpdated))
                overviewRow(label: "Observed", value: alertState.lastObservedLevel?.dashboardLabel ?? "-")
                overviewRow(label: "Muted", value: formatOptionalDate(alertState.mutedUntil))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
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
            StatusSummaryCard(status: status, updatedAt: lastUpdated, alertState: alertState)
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
                DashboardMetric(title: "Gateway RTT", value: "-", unit: "ms", subtitle: "No ping data", severity: .unknown, systemImage: "network"),
                DashboardMetric(title: "External RTT", value: "-", unit: "ms", subtitle: "No ping data", severity: .unknown, systemImage: "globe"),
                DashboardMetric(title: "Packet Loss", value: "-", unit: "%", subtitle: "No ping data", severity: .unknown, systemImage: "point.3.connected.trianglepath.dotted"),
                DashboardMetric(title: "Services", value: "-", unit: "OK", subtitle: "No service data", severity: .unknown, systemImage: "server.rack"),
                DashboardMetric(title: "Download", value: "-", unit: "Mbps", subtitle: "No download data", severity: .unknown, systemImage: "arrow.down.circle")
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
            return DashboardMetric(title: "Gateway RTT", value: "-", unit: "ms", subtitle: "Not reported", severity: .unknown, systemImage: "network")
        }

        return DashboardMetric(
            title: "Gateway RTT",
            value: formatMetricValue(sample.rttAvgMs),
            unit: "ms",
            subtitle: sample.ok ? "Gateway RTT" : "Probe failed",
            severity: evaluator.severityForGatewayPing(sample),
            systemImage: "network",
            sparkline: sparklineValues(base: sample.rttAvgMs)
        )
    }

    private func externalRTTMetric(_ latest: LatestResponse) -> DashboardMetric {
        let sample = sortedPingSamples(latest.ping).first { $0.name.caseInsensitiveCompare("gateway") != .orderedSame }

        guard let sample else {
            return DashboardMetric(title: "External RTT", value: "-", unit: "ms", subtitle: "Not reported", severity: .unknown, systemImage: "globe")
        }

        return DashboardMetric(
            title: "External RTT",
            value: formatMetricValue(sample.rttAvgMs),
            unit: "ms",
            subtitle: sample.displayName ?? sample.name,
            severity: evaluator.severityForExternalPing(sample),
            systemImage: "globe",
            sparkline: sparklineValues(base: sample.rttAvgMs)
        )
    }

    private func packetLossMetric(_ latest: LatestResponse) -> DashboardMetric {
        let samples = sortedPingSamples(latest.ping)
        let maxLoss = samples.compactMap(\.lossPercent).max()

        guard !samples.isEmpty else {
            return DashboardMetric(title: "Packet Loss", value: "-", unit: "%", subtitle: "No ping probes", severity: .unknown, systemImage: "point.3.connected.trianglepath.dotted")
        }

        return DashboardMetric(
            title: "Packet Loss",
            value: formatMetricValue(maxLoss),
            unit: "%",
            subtitle: "Max across ping probes",
            severity: evaluator.severityForPacketLossSummary(samples),
            systemImage: "point.3.connected.trianglepath.dotted",
            sparkline: sparklineValues(base: maxLoss)
        )
    }

    private func servicesMetric(_ latest: LatestResponse) -> DashboardMetric {
        let total = latest.http.count
        let okCount = latest.http.filter(\.ok).count

        guard total > 0 else {
            return DashboardMetric(title: "Services", value: "-", unit: "OK", subtitle: "No service probes", severity: .unknown, systemImage: "server.rack")
        }

        return DashboardMetric(
            title: "Services",
            value: "\(okCount)/\(total)",
            unit: "OK",
            subtitle: "HTTP probes healthy",
            severity: evaluator.severityForServiceSummary(latest.http),
            systemImage: "server.rack",
            sparkline: sparklineValues(base: Double(okCount))
        )
    }

    private func downloadMetric(_ latest: LatestResponse) -> DashboardMetric {
        let sample = sortedDownloadSamples(latest.download).first

        guard let sample else {
            return DashboardMetric(title: "Download", value: "-", unit: "Mbps", subtitle: "No download probes", severity: .unknown, systemImage: "arrow.down.circle")
        }

        return DashboardMetric(
            title: "Download",
            value: formatMetricValue(sample.mbps),
            unit: "Mbps",
            subtitle: sample.displayName ?? sample.name,
            severity: evaluator.severityForDownload(sample),
            systemImage: "arrow.down.circle",
            sparkline: sparklineValues(base: sample.mbps)
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

    private func sparklineValues(base: Double?) -> [Double] {
        guard let base, base > 0 else {
            return []
        }

        return [0.72, 0.66, 0.78, 0.62, 0.85, 0.70, 0.92, 0.76].map { base * $0 }
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
                .lineLimit(1)
                .minimumScaleFactor(0.82)
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

    private var viewerVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (version, build) {
        case let (version?, build?):
            return "v\(version) (\(build))"
        case let (version?, nil):
            return "v\(version)"
        default:
            return "-"
        }
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
    let systemImage: String?
    let sparkline: [Double]

    init(
        title: String,
        value: String,
        unit: String?,
        subtitle: String?,
        severity: MonitoringLevel,
        systemImage: String? = nil,
        sparkline: [Double] = []
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.subtitle = subtitle
        self.severity = severity
        self.systemImage = systemImage
        self.sparkline = sparkline
    }
}

private struct LatencyMiniRow: View {
    let sample: PingSample
    let severity: MonitoringLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(sample.displayName ?? sample.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(formatMilliseconds(sample.rttAvgMs))
                    .font(.caption)
                    .foregroundStyle(severity == .ok ? Color.secondary : severity.dashboardAccentColor)
                    .monospacedDigit()
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 5)

                Capsule()
                    .fill(severity.dashboardAccentColor.opacity(0.78))
                    .frame(width: barWidth, height: 5)
            }
        }
    }

    private var barWidth: CGFloat {
        let value = sample.rttAvgMs ?? 0
        return CGFloat(min(max(value / 200, 0.04), 1) * 170)
    }
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
