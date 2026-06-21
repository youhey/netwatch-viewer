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
                compactHeader
                topSummaryRow
                metricGrid
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color(red: 0.025, green: 0.035, blue: 0.055))
    }

    private var compactHeader: some View {
        HStack {
            Spacer(minLength: 8)

            Text("Updated \(formatTime(displayUpdatedAt))")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.66))
                .monospacedDigit()
        }
    }

    private var topSummaryRow: some View {
        HStack(alignment: .top, spacing: 8) {
            compactHero
                .frame(maxWidth: .infinity, alignment: .topLeading)

            compactStatusHistory
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var compactHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                CompactStatusBadge(level: displayLevel)

                VStack(alignment: .leading, spacing: 2) {
                    Text(compactTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(displayLevel.dashboardAccentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(compactMessage)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.68))
                        .lineLimit(2)
                }
            }

            HStack(spacing: 14) {
                compactMeta("Issues", compactIssueCountText)
                compactMeta("Alert", displayStatus?.alert == true ? "true" : "false")
                compactMeta("Ack", isAcknowledged ? "true" : "false")
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(displayLevel.dashboardSurfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(displayLevel.dashboardAccentColor.opacity(0.35), lineWidth: 1)
        )
    }

    private var metricGrid: some View {
        HStack(spacing: 8) {
            ForEach(compactMetrics) { metric in
                CompactMetricTile(metric: metric)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var compactStatusHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Status History 24h")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white.opacity(0.82))

                Spacer()

                if viewModel.statusHistorySource == .api, let generatedAt = viewModel.statusHistory?.generatedAt {
                    Text(formatTime(generatedAt))
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.54))
                        .monospacedDigit()
                }
            }

            if viewModel.statusHistoryBuckets.isEmpty {
                Text("Status history is not available yet.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.62))
            } else {
                HStack(spacing: 3) {
                    ForEach(viewModel.statusHistoryBuckets) { bucket in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(bucket.level.dashboardAccentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 14)
                            .opacity(bucket.level == .unknown ? 0.55 : 0.92)
                    }
                }
                .frame(height: 16)

                Text(statusHistoryCountText)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.70))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.055, green: 0.075, blue: 0.105))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func compactMeta(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.56))
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.82))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            return CompactMetric(title: "GW RTT", value: "--", unit: "ms", level: .unknown)
        }

        return CompactMetric(
            title: "GW RTT",
            value: formatNumber(sample.rttAvgMs),
            unit: "ms",
            level: evaluator.severityForGatewayPing(sample)
        )
    }

    private var externalMetric: CompactMetric {
        guard let sample = sortedPingSamples.first(where: { $0.name.caseInsensitiveCompare("gateway") != .orderedSame }) else {
            return CompactMetric(title: "EXT RTT", value: "--", unit: "ms", level: .unknown)
        }

        return CompactMetric(
            title: "EXT RTT",
            value: formatNumber(sample.rttAvgMs),
            unit: "ms",
            level: evaluator.severityForExternalPing(sample)
        )
    }

    private var packetLossMetric: CompactMetric {
        let samples = sortedPingSamples

        guard !samples.isEmpty else {
            return CompactMetric(title: "LOSS", value: "--", unit: "%", level: .unknown)
        }

        return CompactMetric(
            title: "LOSS",
            value: formatNumber(samples.compactMap(\.lossPercent).max()),
            unit: "%",
            level: evaluator.severityForPacketLossSummary(samples)
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
                level: throughputStatus.effectiveLevel
            )
        }

        guard let sample = sortedDownloadSamples.first else {
            return CompactMetric(title: "WAN", value: "--", unit: "Mbps", level: .unknown)
        }

        return CompactMetric(
            title: "WAN",
            value: formatNumber(sample.mbps),
            unit: "Mbps",
            level: evaluator.severityForDownload(sample)
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

    private var displayLevel: MonitoringLevel {
        displayStatus?.level ?? .unknown
    }

    private var compactTitle: String {
        if viewModel.isLoading && displayStatus == nil {
            return "Loading..."
        }

        if viewModel.errorMessage != nil && displayStatus == nil {
            return "Netwatch unavailable"
        }

        let title = viewModel.compactNetworkStatus?.title ?? displayStatus?.title ?? "Monitoring status unavailable"
        return title.isEmpty ? "Monitoring status unavailable" : title
    }

    private var compactMessage: String {
        if let message = viewModel.compactNetworkStatus?.message ?? displayStatus?.message, !message.isEmpty {
            return message
        }

        return viewModel.errorMessage ?? "No recent monitoring status is available."
    }

    private var compactIssueCountText: String {
        let count = viewModel.compactNetworkStatus?.issueCount ?? displayStatus?.issueCount ?? 0
        return String(count)
    }

    private var isAcknowledged: Bool {
        guard let statusId = displayStatus?.statusId else {
            return false
        }

        return viewModel.alertState.acknowledgedStatusId == statusId
    }

    private var displayUpdatedAt: Date? {
        displayStatus?.generatedAt ?? viewModel.lastUpdated
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

    private var statusHistoryCountText: String {
        if viewModel.statusHistorySource == .api, let summary = viewModel.statusHistory?.summary {
            return "OK \(summary.okCount) / WARN \(summary.warningCount) / CRIT \(summary.criticalCount) / UNK \(summary.unknownCount)"
        }

        let counts = Dictionary(grouping: viewModel.statusHistoryBuckets, by: \.level)
            .mapValues(\.count)

        return "OK \(counts[.ok, default: 0]) / WARN \(counts[.warning, default: 0]) / CRIT \(counts[.critical, default: 0]) / UNK \(counts[.unknown, default: 0])"
    }

    private func formatNumber(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }

        return value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date else {
            return "--:--"
        }

        return date.formatted(date: .omitted, time: .shortened)
    }
}

private struct CompactMetric: Identifiable {
    var id: String { title }

    let title: String
    let value: String
    let unit: String?
    let level: MonitoringLevel
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
}

private struct CompactStatusBadge: View {
    let level: MonitoringLevel

    var body: some View {
        Text(level.dashboardLabel == "UNKNOWN" ? "UNK" : level.dashboardLabel)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(level.dashboardAccentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(level.dashboardAccentColor.opacity(0.14))
            )
            .overlay(
                Capsule()
                    .stroke(level.dashboardAccentColor.opacity(0.42), lineWidth: 1)
            )
    }
}

#Preview {
    NetwatchCompactView()
        .environmentObject(DashboardViewModel(requestNotificationsOnInit: false))
        .frame(width: 380, height: 480)
}
