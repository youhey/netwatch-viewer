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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        SeverityChip(level: status.level)

                        if status.alert {
                            Text("ALERT")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(status.level.dashboardAccentColor)
                        }
                    }

                    Text(status.title)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(status.shortDetail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Updated")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(updatedText)
                        .font(.headline)
                        .monospacedDigit()

                    Text("Issues \(status.issueCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let statusId = status.statusId {
                Text(statusId)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.07, green: 0.09, blue: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(status.level.dashboardAccentColor.opacity(0.35), lineWidth: 1)
        )
    }

    private var updatedText: String {
        guard let updatedAt else {
            return "Never"
        }

        return updatedAt.formatted(date: .omitted, time: .standard)
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
