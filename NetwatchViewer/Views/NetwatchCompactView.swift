//
//  NetwatchCompactView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/21.
//

import SwiftUI

struct NetwatchCompactView: View {
    @EnvironmentObject private var viewModel: DashboardViewModel

    private var evaluator: SeverityEvaluator {
        SeverityEvaluator(thresholds: viewModel.thresholds)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                topSummaryRow
                metricGrid
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color(red: 0.025, green: 0.035, blue: 0.055))
    }

    private var topSummaryRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 8) {
                statusOverview
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                compactStatusHistory
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(minWidth: 760)

            VStack(alignment: .leading, spacing: 8) {
                statusOverview
                compactStatusHistory
            }
        }
    }

    @ViewBuilder
    private var statusOverview: some View {
        if let displayStatus {
            StatusSummaryCard(
                status: displayStatus,
                updatedAt: displayStatus.generatedAt ?? viewModel.lastUpdated,
                alertState: viewModel.alertState,
                titleOverride: viewModel.compactNetworkStatus?.title,
                messageOverride: viewModel.compactNetworkStatus?.message,
                issueCountOverride: viewModel.compactNetworkStatus?.issueCount
            )
        } else {
            SectionCard(title: "Status", systemImage: "shield.lefthalf.filled") {
                Text("No status loaded.")
                    .foregroundStyle(Color.white.opacity(0.68))
            }
        }
    }

    private var metricGrid: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ForEach(compactMetrics) { metric in
                    CompactMetricTile(metric: metric)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(minWidth: 520)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    CompactMetricTile(metric: gatewayMetric)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    CompactMetricTile(metric: externalMetric)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 8) {
                    CompactMetricTile(metric: packetLossMetric)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    CompactMetricTile(metric: throughputMetric)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var compactStatusHistory: some View {
        SectionCard(title: "Status History", subtitle: "Last 24h", systemImage: "clock.arrow.circlepath", fillsVertically: false) {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.statusHistoryBuckets.isEmpty {
                    Text("Status history is not available yet.")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.64))
                } else {
                    HStack(spacing: 4) {
                        ForEach(viewModel.statusHistoryBuckets) { bucket in
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

                            Text(statusLegendLabel(for: level))
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

                if let statusHistoryError = viewModel.statusHistoryError, viewModel.statusHistorySource != .api {
                    Text(statusHistoryError)
                        .font(.caption2)
                        .foregroundStyle(Color.red.opacity(0.82))
                        .lineLimit(2)
                }
            }
        }
    }

    private var compactMetrics: [CompactMetric] {
        [
            gatewayMetric,
            externalMetric,
            packetLossMetric,
            throughputMetric
        ]
    }

    private var gatewayMetric: CompactMetric {
        guard let sample = sortedPingSamples.first(where: { $0.name.caseInsensitiveCompare("gateway") == .orderedSame }) else {
            return CompactMetric(title: "GW RTT", value: "--", unit: "ms", level: .unknown, sparkline: [])
        }

        return CompactMetric(
            title: "GW RTT",
            value: formatNumber(sample.rttAvgMs),
            unit: "ms",
            level: evaluator.severityForGatewayPing(sample),
            sparkline: gatewayRTTSparkline(fallbackBase: sample.rttAvgMs)
        )
    }

    private var externalMetric: CompactMetric {
        guard let sample = sortedPingSamples.first(where: { $0.name.caseInsensitiveCompare("gateway") != .orderedSame }) else {
            return CompactMetric(title: "EXT RTT", value: "--", unit: "ms", level: .unknown, sparkline: [])
        }

        return CompactMetric(
            title: "EXT RTT",
            value: formatNumber(sample.rttAvgMs),
            unit: "ms",
            level: evaluator.severityForExternalPing(sample),
            sparkline: externalRTTSparkline(fallbackBase: sample.rttAvgMs)
        )
    }

    private var packetLossMetric: CompactMetric {
        let samples = sortedPingSamples

        guard !samples.isEmpty else {
            return CompactMetric(title: "LOSS", value: "--", unit: "%", level: .unknown, sparkline: [])
        }

        let maxLoss = samples.compactMap(\.lossPercent).max()

        return CompactMetric(
            title: "LOSS",
            value: formatNumber(maxLoss),
            unit: "%",
            level: evaluator.severityForPacketLossSummary(samples),
            sparkline: packetLossSparkline(fallbackBase: maxLoss)
        )
    }

    private var throughputMetric: CompactMetric {
        if let throughputStatus = viewModel.throughputStatus {
            let probe = throughputStatus.allProbes
                .sorted { lhs, rhs in
                    (lhs.level.sortPriority, lhs.name) < (rhs.level.sortPriority, rhs.name)
                }
                .first { $0.manualOnly != true && $0.mbps != nil }
                ?? throughputStatus.allProbes.first

            return CompactMetric(
                title: "WAN",
                value: formatNumber(probe?.mbps),
                unit: "Mbps",
                level: throughputStatus.effectiveLevel,
                sparkline: throughputSparkline(fallbackBase: probe?.mbps)
            )
        }

        guard let sample = sortedDownloadSamples.first else {
            return CompactMetric(title: "WAN", value: "--", unit: "Mbps", level: .unknown, sparkline: [])
        }

        return CompactMetric(
            title: "WAN",
            value: formatNumber(sample.mbps),
            unit: "Mbps",
            level: evaluator.severityForDownload(sample),
            sparkline: downloadSparkline(fallbackBase: sample.mbps)
        )
    }

    private var displayStatus: MonitoringStatus? {
        if let compactNetworkStatus = viewModel.compactNetworkStatus {
            return compactNetworkStatus.monitoringStatus(
                source: viewModel.monitoringStatus?.source,
                generatedAt: viewModel.compactGeneratedAt ?? viewModel.monitoringStatus?.generatedAt
            )
        }

        return viewModel.monitoringStatus
    }

    private var sortedPingSamples: [PingSample] {
        (viewModel.latest?.ping ?? []).sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    private var sortedDownloadSamples: [DownloadSample] {
        (viewModel.latest?.download ?? []).sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
    }

    private func gatewayRTTSparkline(fallbackBase: Double?) -> [Double] {
        if let series = sortedPingSeries(viewModel.overviewChart?.ping ?? []).first(where: { $0.name.caseInsensitiveCompare("gateway") == .orderedSame }) {
            let values = series.points.compactMap(\.avgMs)
            if !values.isEmpty {
                return values
            }
        }

        return fallbackSparklineValues(base: fallbackBase)
    }

    private func externalRTTSparkline(fallbackBase: Double?) -> [Double] {
        if let series = sortedPingSeries(viewModel.overviewChart?.ping ?? []).first(where: { $0.name.caseInsensitiveCompare("gateway") != .orderedSame }) {
            let values = series.points.compactMap(\.avgMs)
            if !values.isEmpty {
                return values
            }
        }

        return fallbackSparklineValues(base: fallbackBase)
    }

    private func packetLossSparkline(fallbackBase: Double?) -> [Double] {
        var maxLossByTimestamp: [Date: Double] = [:]

        for series in viewModel.overviewChart?.ping ?? [] {
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

    private func downloadSparkline(fallbackBase: Double?) -> [Double] {
        if let series = sortedDownloadSeries(viewModel.overviewChart?.download ?? []).first {
            let values = series.points.compactMap(\.avgMbps)
            if !values.isEmpty {
                return values
            }
        }

        return fallbackSparklineValues(base: fallbackBase)
    }

    private func throughputSparkline(fallbackBase: Double?) -> [Double] {
        if let series = sortedSpeedprobeSeries(viewModel.overviewChart?.speedprobe ?? []).first(where: \.isThroughputSeries) {
            let values = series.points.compactMap(\.throughputValue)
            if !values.isEmpty {
                return values
            }
        }

        return downloadSparkline(fallbackBase: fallbackBase)
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

    private func sortedSpeedprobeSeries(_ series: [SpeedprobeChartSeries]) -> [SpeedprobeChartSeries] {
        series.sorted { lhs, rhs in
            (lhs.displayOrder ?? Int.max, lhs.name) < (rhs.displayOrder ?? Int.max, rhs.name)
        }
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

    private var statusLegendColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 0), spacing: 6), count: 2)
    }

    private var statusLegendLevels: [MonitoringLevel] {
        [.ok, .warning, .critical, .unknown]
    }

    private var statusHistoryMetadataText: String? {
        switch viewModel.statusHistorySource {
        case .api:
            guard let statusHistory = viewModel.statusHistory else {
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
        guard viewModel.statusHistorySource == .api, let summary = viewModel.statusHistory?.summary else {
            return nil
        }

        return "OK \(summary.okCount) / WARN \(summary.warningCount) / CRIT \(summary.criticalCount) / UNK \(summary.unknownCount)"
    }

    private func formatNumber(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }

        return value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private func formatHistoryTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func statusLegendLabel(for level: MonitoringLevel) -> String {
        switch level {
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

private struct CompactMetric: Identifiable {
    var id: String { title }

    let title: String
    let value: String
    let unit: String?
    let level: MonitoringLevel
    let sparkline: [Double]
}

private struct CompactMetricTile: View {
    let metric: CompactMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(metric.level.dashboardAccentColor)
                    .frame(width: 6, height: 6)

                Text(metric.title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(metric.value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(metric.level == .ok ? Color.white.opacity(0.88) : metric.level.dashboardAccentColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let unit = metric.unit {
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(metric.level == .ok ? Color.white.opacity(0.70) : metric.level.dashboardAccentColor)
                        .lineLimit(1)
                }
            }

            if !metric.sparkline.isEmpty {
                CompactMiniSparkline(values: metric.sparkline, color: Self.metricAccent)
                    .frame(height: 22)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.055, green: 0.075, blue: 0.105))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(metric.level.dashboardAccentColor.opacity(metric.level == .ok ? 0.14 : 0.42), lineWidth: 1)
        )
    }

    private static var metricAccent: Color {
        Color(red: 0.27, green: 0.78, blue: 0.96)
    }
}

private struct CompactMiniSparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                Path { path in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let step = normalizedValues.count > 1 ? width / CGFloat(normalizedValues.count - 1) : width

                    for index in normalizedValues.indices {
                        let x = CGFloat(index) * step
                        let y = height - CGFloat(normalizedValues[index]) * height

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color.opacity(0.86), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

                Rectangle()
                    .fill(color.opacity(0.16))
                    .frame(height: 1)
                    .offset(y: -2)
            }
        }
    }

    private var normalizedValues: [Double] {
        guard let maxValue = values.max(), maxValue > 0 else {
            return values.map { _ in 0.2 }
        }

        return values.map { min(max($0 / maxValue, 0.12), 1) }
    }
}

#Preview {
    NetwatchCompactView()
        .environmentObject(DashboardViewModel(requestNotificationsOnInit: false))
        .frame(width: 380, height: 480)
}
