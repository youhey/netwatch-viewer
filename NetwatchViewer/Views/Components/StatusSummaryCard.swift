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
        HStack(alignment: .center, spacing: 18) {
            StatusRing(level: status.level, alert: status.alert)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    SeverityChip(level: status.level)

                    if status.alert {
                        Text("ALERT")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(status.level.dashboardAccentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(status.title)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(status.message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 16) {
                    metadata(label: "Updated", value: updatedText)
                    metadata(label: "Issues", value: String(status.issueCount))
                    metadata(label: "Alert", value: status.alert ? "true" : "false")
                }

                if let statusId = status.statusId {
                    metadata(label: "Status ID", value: statusId)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if let alertState {
                    HStack(spacing: 16) {
                        metadata(label: "Observed", value: alertState.lastObservedLevel?.dashboardLabel ?? "-")
                        metadata(label: "Ack", value: alertState.acknowledgedStatusId == status.statusId ? "true" : "false")
                    }
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

        return updatedAt.formatted(date: .omitted, time: .standard)
    }

    private func metadata(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
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
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: symbolName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(level.dashboardAccentColor)
        }
        .frame(width: 92, height: 92)
    }

    private var symbolName: String {
        switch level {
        case .ok:
            return "checkmark"
        case .warning:
            return "exclamationmark"
        case .critical:
            return "xmark"
        case .unknown:
            return "questionmark"
        }
    }
}

#Preview {
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
