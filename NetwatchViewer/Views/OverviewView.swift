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
    let overviewChart: ChartsOverviewResponse?
    let statusHistory: MonitoringStatusHistoryResponse?
    let statusHistorySource: StatusHistorySource
    let statusHistoryError: String?
    let statusHistoryBuckets: [StatusHistoryBucket]
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
            detailSections
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            statusHistorySection
            thresholdsSummary
            activeIssues
                .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 300, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
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
                LazyVGrid(columns: detailCardColumns, alignment: .leading, spacing: 16) {
                    PingSectionView(samples: latest.ping, evaluator: evaluator)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)

                    DNSSectionView(samples: latest.dns, evaluator: evaluator)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)

                    DownloadSectionView(samples: latest.download, evaluator: evaluator)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                }

                LazyVGrid(columns: summaryCardColumns, alignment: .leading, spacing: 16) {
                    HTTPSectionView(samples: latest.http, evaluator: evaluator)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        } else {
            SectionCard(title: "Latest Data", systemImage: "tray.full") {
                Text("No latest data loaded.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusHistorySection: some View {
        SectionCard(title: "Status History", subtitle: "Last 24h", systemImage: "clock.arrow.circlepath", fillsVertically: false) {
            VStack(alignment: .leading, spacing: 12) {
                if statusHistoryBuckets.isEmpty {
                    Text("Status history is not available yet.")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.64))
                } else {
                    HStack(spacing: 4) {
                        ForEach(statusHistoryBuckets) { bucket in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(bucket.level.dashboardAccentColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 16)
                                .opacity(bucket.level == .unknown ? 0.55 : 0.9)
                        }
                    }
                    .frame(height: 18)
                }

                LazyVGrid(columns: statusLegendColumns, alignment: .leading, spacing: 7) {
                    ForEach(statusLegendLevels, id: \.rawValue) { level in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(level.dashboardAccentColor)
                                .frame(width: 7, height: 7)

                            Text(level.dashboardLegendLabel)
                                .font(.caption2)
                                .foregroundStyle(Color.white.opacity(0.72))
                        }
                    }
                }

                if let summaryText = statusHistorySummaryText {
                    Text(summaryText)
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.68))
                        .lineLimit(1)
                }

                if let metadataText = statusHistoryMetadataText {
                    Text(metadataText)
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.58))
                        .lineLimit(1)
                }

                if let statusHistoryError, statusHistorySource != .api {
                    Text(statusHistoryError)
                        .font(.caption2)
                        .foregroundStyle(Color.red.opacity(0.82))
                        .lineLimit(2)
                }
            }
        }
    }

    private var evaluator: SeverityEvaluator {
        SeverityEvaluator(thresholds: thresholds)
    }

    private var metricColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 0), spacing: 12), count: 5)
    }

    private var detailCardColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 0), spacing: 16), count: 3)
    }

    private var summaryCardColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 420), spacing: 16)]
    }

    private var statusLegendColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 0), spacing: 6), count: 2)
    }

    private var statusLegendLevels: [MonitoringLevel] {
        [.ok, .warning, .critical, .unknown]
    }

    private var statusHistoryMetadataText: String? {
        switch statusHistorySource {
        case .api:
            guard let statusHistory else {
                return nil
            }

            var parts = ["Bucket: \(statusHistory.bucket)"]

            if let generatedAt = statusHistory.generatedAt {
                parts.append("Generated: \(formatHistoryTime(generatedAt))")
            }

            return parts.joined(separator: "  ")
        case .observed:
            return "Observed while viewer is running"
        case .unavailable:
            return nil
        }
    }

    private var statusHistorySummaryText: String? {
        guard statusHistorySource == .api, let summary = statusHistory?.summary else {
            return nil
        }

        return "OK \(summary.okCount) / WARN \(summary.warningCount) / CRIT \(summary.criticalCount) / UNK \(summary.unknownCount)"
    }

    @ViewBuilder
    private var statusOverview: some View {
        if let status {
            StatusSummaryCard(status: status, updatedAt: lastUpdated, alertState: alertState)
        } else {
            SectionCard(title: "Status", systemImage: "shield.lefthalf.filled") {
                Text("No status loaded.")
                    .foregroundStyle(Color.white.opacity(0.68))
            }
        }
    }

    private var activeIssues: some View {
        SectionCard(title: "Active Issues", subtitle: "Current monitoring reasons", systemImage: "shield.lefthalf.filled") {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let status {
                        if status.reasons.isEmpty {
                            HStack(spacing: 8) {
                                SeverityChip(level: .ok)
                                Text("No active issues")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(sortedReasons(status.reasons)) { reason in
                                ActiveIssueRow(reason: reason, isPrimary: reason == status.primaryReason)
                            }
                        }
                    } else {
                        Text("No status loaded.")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var thresholdsSummary: some View {
        SectionCard(title: "Thresholds", subtitle: "Warning and critical bands", systemImage: "slider.horizontal.3", fillsVertically: false) {
            if let thresholds {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
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
                DashboardMetric(title: "Services", value: "-", unit: nil, subtitle: "No service data", severity: .unknown, systemImage: "server.rack"),
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
            subtitle: sample.ok ? nil : "Probe failed",
            severity: evaluator.severityForGatewayPing(sample),
            systemImage: "network",
            sparkline: gatewayRTTSparkline(fallbackBase: sample.rttAvgMs)
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
            subtitle: sample.ok ? nil : "Probe failed",
            severity: evaluator.severityForExternalPing(sample),
            systemImage: "globe",
            sparkline: externalRTTSparkline(fallbackBase: sample.rttAvgMs)
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
            subtitle: nil,
            severity: evaluator.severityForPacketLossSummary(samples),
            systemImage: "point.3.connected.trianglepath.dotted",
            sparkline: packetLossSparkline(fallbackBase: maxLoss)
        )
    }

    private func servicesMetric(_ latest: LatestResponse) -> DashboardMetric {
        let total = latest.http.count
        let okCount = latest.http.filter(\.ok).count

        guard total > 0 else {
            return DashboardMetric(title: "Services", value: "-", unit: nil, subtitle: "No service probes", severity: .unknown, systemImage: "server.rack")
        }

        return DashboardMetric(
            title: "Services",
            value: "\(okCount)/\(total)",
            unit: nil,
            subtitle: okCount == total ? nil : "\(total - okCount) failing",
            severity: evaluator.severityForServiceSummary(latest.http),
            systemImage: "server.rack",
            sparkline: serviceSparkline(fallbackBase: Double(okCount))
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
            subtitle: sample.ok ? nil : "Probe failed",
            severity: evaluator.severityForDownload(sample),
            systemImage: "arrow.down.circle",
            sparkline: downloadSparkline(fallbackBase: sample.mbps)
        )
    }

    private func gatewayRTTSparkline(fallbackBase: Double?) -> [Double] {
        if let series = sortedPingSeries(overviewChart?.ping ?? []).first(where: { $0.name.caseInsensitiveCompare("gateway") == .orderedSame }) {
            let values = series.points.compactMap(\.avgMs)
            if !values.isEmpty {
                return values
            }
        }

        return fallbackSparklineValues(base: fallbackBase)
    }

    private func externalRTTSparkline(fallbackBase: Double?) -> [Double] {
        if let series = sortedPingSeries(overviewChart?.ping ?? []).first(where: { $0.name.caseInsensitiveCompare("gateway") != .orderedSame }) {
            let values = series.points.compactMap(\.avgMs)
            if !values.isEmpty {
                return values
            }
        }

        return fallbackSparklineValues(base: fallbackBase)
    }

    private func packetLossSparkline(fallbackBase: Double?) -> [Double] {
        var maxLossByTimestamp: [Date: Double] = [:]

        for series in overviewChart?.ping ?? [] {
            for point in series.points {
                guard let lossPercent = point.lossPercent else {
                    continue
                }

                maxLossByTimestamp[point.ts] = max(maxLossByTimestamp[point.ts] ?? lossPercent, lossPercent)
            }
        }

        let values = maxLossByTimestamp
            .sorted { $0.key < $1.key }
            .map(\.value)

        return values.isEmpty ? fallbackSparklineValues(base: fallbackBase) : values
    }

    private func serviceSparkline(fallbackBase: Double?) -> [Double] {
        if let series = sortedServiceSeries(overviewChart?.serviceGroups ?? []).first {
            let values = series.points.compactMap(\.okRate)
            if !values.isEmpty {
                return values
            }
        }

        return fallbackSparklineValues(base: fallbackBase)
    }

    private func downloadSparkline(fallbackBase: Double?) -> [Double] {
        if let series = sortedDownloadSeries(overviewChart?.download ?? []).first {
            let values = series.points.compactMap(\.avgMbps)
            if !values.isEmpty {
                return values
            }
        }

        return fallbackSparklineValues(base: fallbackBase)
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

    private func sortedPingSeries(_ series: [PingChartSeries]) -> [PingChartSeries] {
        series.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    private func sortedDownloadSeries(_ series: [DownloadChartSeries]) -> [DownloadChartSeries] {
        series.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    private func sortedServiceSeries(_ series: [ServiceChartSeries]) -> [ServiceChartSeries] {
        series.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.group) < (rhs.displayOrder ?? Int.max, rhs.group)
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

    private func fallbackSparklineValues(base: Double?) -> [Double] {
        guard let base else {
            return []
        }

        if base == 0 {
            return Array(repeating: 0, count: 8)
        }

        return [0.72, 0.66, 0.78, 0.62, 0.85, 0.70, 0.92, 0.76].map { base * $0 }
    }

    private func thresholdText(_ label: String, band: ThresholdBand?, unit: String, mode: ThresholdMode) -> some View {
        GridRow {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.72))
                .frame(width: 96, alignment: .leading)

            thresholdValue("warn", value: band?.warning, unit: unit, mode: mode, color: .warning)
            thresholdValue("crit", value: band?.critical, unit: unit, mode: mode, color: .critical)
        }
    }

    private func thresholdValue(_ label: String, value: Double?, unit: String, mode: ThresholdMode, color: MonitoringLevel) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color.dashboardAccentColor)
                .frame(width: 5, height: 5)

            Text("\(label) \(thresholdDirection(mode)) \(formatThresholdValue(value, unit: unit))")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.78))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private func formatThresholdValue(_ value: Double?, unit: String) -> String {
        guard let value else {
            return "-"
        }

        return "\(value.formatted(.number.precision(.fractionLength(0...1))))\(unit)"
    }

    private func thresholdDirection(_ mode: ThresholdMode) -> String {
        mode == .high ? ">=" : "<"
    }

    private func formatHistoryTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
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
                            .foregroundStyle(Color.white.opacity(0.68))
                    }
                }

                Text(reason.detailText)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.68))
            }
        }
    }
}

private extension MonitoringLevel {
    var dashboardLegendLabel: String {
        switch self {
        case .ok:
            return "OK"
        case .warning:
            return "Warning"
        case .critical:
            return "Critical"
        case .unknown:
            return "Unknown"
        }
    }
}
