//
//  StatusSummaryCard.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct StatusSummaryCard: View {
    let status: MonitoringStatus
    let updatedAt: Date?
    let alertState: AlertState?

    init(status: MonitoringStatus, updatedAt: Date?, alertState: AlertState? = nil) {
        self.status = status
        self.updatedAt = updatedAt
        self.alertState = alertState
    }

    var body: some View {
        HStack(alignment: .center, spacing: 34) {
            StatusRing(level: status.level, alert: status.alert)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(heroTitle)
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(status.level.dashboardAccentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(heroMessage)
                        .font(.callout)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: 22) {
                    metadata(label: "Updated", value: updatedText)
                    metadata(label: "Status", value: statusLabel)
                    metadata(label: "Issues", value: String(status.issueCount))
                    metadata(label: "Alert", value: status.alert ? "true" : "false")
                    metadata(label: "Ack", value: acknowledgedText)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.05, green: 0.07, blue: 0.10).mix(with: status.level.dashboardAccentColor, by: 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(status.level.dashboardAccentColor.opacity(0.42), lineWidth: 1)
        )
    }

    private var updatedText: String {
        guard let updatedAt else {
            return "Never"
        }

        return updatedAt.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits))
    }

    private var statusLabel: String {
        if let statusId = status.statusId, !statusId.isEmpty {
            return statusId
        }

        return status.level.rawValue
    }

    private var heroTitle: String {
        switch status.level {
        case .ok:
            return "All systems operational"
        case .warning:
            return "Network degradation detected"
        case .critical:
            return "Critical network issue detected"
        case .unknown:
            return "Monitoring status unavailable"
        }
    }

    private var heroMessage: String {
        switch status.level {
        case .ok:
            return "All probes are healthy. Network performance is normal."
        case .warning:
            return reasonMessage(
                thresholdLabel: "warning",
                fallback: "One or more probes are outside normal thresholds. Check active issues for details."
            )
        case .critical:
            return reasonMessage(
                thresholdLabel: "critical",
                fallback: "One or more critical probes are failing or outside critical thresholds. Immediate attention may be needed."
            )
        case .unknown:
            if status.reasons.isEmpty {
                return "No recent monitoring status is available."
            }

            return "Netwatch cannot determine current network health. Check API connectivity and probe freshness."
        }
    }

    private var acknowledgedText: String {
        guard let alertState else {
            return "-"
        }

        return alertState.acknowledgedStatusId == status.statusId ? "true" : "false"
    }

    private func reasonMessage(thresholdLabel: String, fallback: String) -> String {
        guard let reason = status.primaryReason ?? status.reasons.first else {
            return fallback
        }

        return "\(reasonLead(for: reason, thresholdLabel: thresholdLabel)) \(issueCountText)"
    }

    private func reasonLead(for reason: MonitoringReason, thresholdLabel: String) -> String {
        let subject = reasonSubject(for: reason)
        let comparison = reasonComparison(for: reason, thresholdLabel: thresholdLabel)

        guard let target = reason.target, !target.isEmpty else {
            return "\(subject) \(comparison)."
        }

        return "\(subject) \(comparison) on \(formattedTargetName(target))."
    }

    private func reasonSubject(for reason: MonitoringReason) -> String {
        switch reason.metric {
        case "mbps":
            return "Download throughput"
        case "loss_percent":
            return "Packet loss"
        case "rtt_avg_ms":
            return "Latency"
        case "duration_ms":
            return "DNS duration"
        case "total_ms", "ttfb_ms":
            return "Service latency"
        default:
            return "Probe health"
        }
    }

    private func reasonComparison(for reason: MonitoringReason, thresholdLabel: String) -> String {
        switch reason.metric {
        case "mbps":
            return "is below the \(thresholdLabel) threshold"
        case "loss_percent", "rtt_avg_ms", "duration_ms", "total_ms", "ttfb_ms":
            return "is above the \(thresholdLabel) threshold"
        default:
            return "is outside the \(thresholdLabel) threshold"
        }
    }

    private var issueCountText: String {
        let count = max(status.issueCount, 1)
        let noun = count == 1 ? "issue" : "issues"
        return "\(count) active \(noun) detected."
    }

    private func formattedTargetName(_ value: String) -> String {
        value.split(separator: "_")
            .map { formattedTargetPart($0) }
            .joined(separator: " ")
    }

    private func formattedTargetPart(_ part: Substring) -> String {
        let lower = part.lowercased()

        switch lower {
        case "dns":
            return "DNS"
        case "http":
            return "HTTP"
        case "r2":
            return "R2"
        default:
            if lower.hasSuffix("mb") {
                let number = lower.dropLast(2)
                if !number.isEmpty, number.allSatisfy(\.isNumber) {
                    return "\(number)MB"
                }
            }

            return lower.prefix(1).uppercased() + String(lower.dropFirst())
        }
    }

    private func metadata(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.68))

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(minWidth: 68, maxWidth: 132, alignment: .leading)
    }
}

private struct StatusRing: View {
    let level: MonitoringLevel
    let alert: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(level.dashboardAccentColor.opacity(0.16), lineWidth: 12)

            Circle()
                .trim(from: 0, to: alert ? 0.78 : 0.92)
                .stroke(
                    level.dashboardAccentColor,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                if level == .ok {
                    Text("NET")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }

                Text(ringLabel)
                    .font(.system(size: level == .ok ? 22 : 24, weight: .bold, design: .rounded))
            }
            .foregroundStyle(level.dashboardAccentColor)
            .minimumScaleFactor(0.75)
        }
        .frame(width: 112, height: 112)
    }

    private var ringLabel: String {
        switch level {
        case .ok:
            return "OK"
        case .warning:
            return "WARN"
        case .critical:
            return "CRIT"
        case .unknown:
            return "UNK"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusSummaryCard(
            status: PreviewMonitoringStatusFactory.status(
                level: "ok",
                alert: false,
                title: "NET OK",
                message: "all probes healthy",
                reasons: []
            ),
            updatedAt: Date()
        )

        StatusSummaryCard(
            status: PreviewMonitoringStatusFactory.status(
                level: "warning",
                alert: true,
                title: "NET WARN",
                message: "download threshold warning",
                reasons: [
                    [
                        "code": "download_mbps_low",
                        "level": "warning",
                        "target": "r2_1mb",
                        "metric": "mbps",
                        "value": 4.8,
                        "warning": 5.0
                    ]
                ]
            ),
            updatedAt: Date()
        )

        StatusSummaryCard(
            status: PreviewMonitoringStatusFactory.status(
                level: "critical",
                alert: true,
                title: "NET CRIT",
                message: "packet loss critical",
                reasons: [
                    [
                        "code": "packet_loss_high",
                        "level": "critical",
                        "target": "cloudflare_dns",
                        "metric": "loss_percent",
                        "value": 6.0,
                        "critical": 5.0
                    ]
                ]
            ),
            updatedAt: Date()
        )

        StatusSummaryCard(
            status: PreviewMonitoringStatusFactory.status(
                level: "unknown",
                alert: false,
                title: "NET UNKNOWN",
                message: "status unavailable",
                reasons: []
            ),
            updatedAt: nil
        )
    }
    .padding()
    .background(Color(red: 0.04, green: 0.05, blue: 0.07))
}

private enum PreviewMonitoringStatusFactory {
    static func status(
        level: String,
        alert: Bool,
        title: String,
        message: String,
        reasons: [[String: Any]]
    ) -> MonitoringStatus {
        let payload: [String: Any] = [
            "source": "netwatch",
            "status_id": "preview-\(level)",
            "generated_at": "2026-06-07T00:56:22+09:00",
            "level": level,
            "alert": alert,
            "title": title,
            "message": message,
            "primary_reason": reasons.first ?? NSNull(),
            "reasons": reasons
        ]

        let data = try! JSONSerialization.data(withJSONObject: payload)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try! decoder.decode(MonitoringStatus.self, from: data)
    }
}
