//
//  HTTPSectionView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct HTTPSectionView: View {
    let samples: [HTTPSample]
    let evaluator: SeverityEvaluator

    private var summary: ServiceHealthSummary {
        ServiceHealthSummary(samples: samples, evaluator: evaluator)
    }

    var body: some View {
        SectionCard(title: "Service Health", subtitle: "Grouped HTTP probe health", systemImage: "server.rack", fillsVertically: false) {
            if samples.isEmpty {
                Text("No HTTP samples.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    LazyVGrid(columns: groupColumns, alignment: .leading, spacing: 8) {
                        ForEach(summary.groups) { group in
                            ServiceGroupSummaryRow(group: group)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 9) {
                        Text("Issues")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.white.opacity(0.72))

                        if summary.issues.isEmpty {
                            Text("No service issues")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.68))
                        } else {
                            ForEach(summary.issues) { issue in
                                ServiceIssueRow(issue: issue)
                            }
                        }
                    }

                    Text("Show all services")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.42))
                }
            }
        }
    }

    private var groupColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 190), spacing: 12)]
    }
}

private struct ServiceHealthSummary {
    let groups: [ServiceGroupSummary]
    let issues: [ServiceIssue]

    init(samples: [HTTPSample], evaluator: SeverityEvaluator) {
        let enrichedSamples = samples.map { sample in
            ServiceSample(sample: sample, level: evaluator.severityForHTTP(sample))
        }

        let groupedSamples = Dictionary(grouping: enrichedSamples, by: \.displayGroupName)

        groups = groupedSamples.map { displayName, groupSamples in
            ServiceGroupSummary(
                displayName: displayName,
                okCount: groupSamples.filter { $0.level == .ok }.count,
                totalCount: groupSamples.count,
                level: ServiceHealthSummary.worstLevel(groupSamples.map(\.level)),
                displayOrder: groupSamples.map(\.displayOrder).min() ?? Int.max
            )
        }
        .sorted { lhs, rhs in
            (lhs.displayOrder, lhs.displayName) < (rhs.displayOrder, rhs.displayName)
        }

        issues = enrichedSamples
            .filter { $0.level != .ok }
            .map(ServiceIssue.init(serviceSample:))
            .sorted { lhs, rhs in
                (lhs.level.sortPriority, lhs.displayOrder, lhs.label) < (rhs.level.sortPriority, rhs.displayOrder, rhs.label)
            }
    }

    private static func worstLevel(_ levels: [MonitoringLevel]) -> MonitoringLevel {
        levels.min { lhs, rhs in
            lhs.sortPriority < rhs.sortPriority
        } ?? .unknown
    }
}

private struct ServiceSample {
    let sample: HTTPSample
    let level: MonitoringLevel

    nonisolated var displayOrder: Int {
        sample.displayOrder ?? Int.max
    }

    nonisolated var displayGroupName: String {
        ServiceProbeDisplay.groupName(group: sample.group, category: sample.category)
    }
}

private struct ServiceGroupSummary: Identifiable {
    var id: String { displayName }

    let displayName: String
    let okCount: Int
    let totalCount: Int
    let level: MonitoringLevel
    let displayOrder: Int
}

private struct ServiceIssue: Identifiable {
    var id: String { name }

    let name: String
    let label: String
    let group: String?
    let category: String?
    let level: MonitoringLevel
    let httpStatusCode: Int?
    let error: String?
    let durationMs: Double?
    let measuredAt: Date?
    let displayOrder: Int

    nonisolated init(serviceSample: ServiceSample) {
        let sample = serviceSample.sample

        name = sample.name
        label = ServiceProbeDisplay.label(for: sample)
        group = sample.group
        category = sample.category
        level = serviceSample.level
        httpStatusCode = sample.httpStatus
        error = sample.errorMessage ?? sample.error
        durationMs = sample.totalMs
        measuredAt = ChartDateParser.parse(sample.ts)
        displayOrder = serviceSample.displayOrder
    }
}

private struct ServiceGroupSummaryRow: View {
    let group: ServiceGroupSummary

    var body: some View {
        HStack(spacing: 8) {
            Text(group.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("\(group.okCount)/\(group.totalCount)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.84))
                .monospacedDigit()

            Text(group.level.dashboardCompactLabel)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(group.level.dashboardAccentColor)
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(group.level.dashboardSurfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(group.level.dashboardAccentColor.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct ServiceIssueRow: View {
    let issue: ServiceIssue

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: issue.level.dashboardSymbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(issue.level.dashboardAccentColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(issue.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(issue.level.dashboardCompactLabel)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(issue.level.dashboardAccentColor)
                }

                Text(issueDetailText)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.66))
                    .lineLimit(1)
            }
        }
    }

    private var issueDetailText: String {
        var parts: [String] = []

        if let error = issue.error, !error.isEmpty {
            parts.append(error)
        } else if let httpStatusCode = issue.httpStatusCode {
            parts.append("HTTP \(httpStatusCode)")
        } else {
            parts.append("No status")
        }

        if issue.durationMs != nil {
            parts.append(formatMilliseconds(issue.durationMs))
        }

        if let measuredAt = issue.measuredAt {
            parts.append(measuredAt.formatted(date: .omitted, time: .shortened))
        }

        return parts.joined(separator: "  ")
    }
}

private extension MonitoringLevel {
    var dashboardCompactLabel: String {
        switch self {
        case .ok:
            "OK"
        case .warning:
            "WARN"
        case .critical:
            "CRIT"
        case .unknown:
            "UNK"
        }
    }

    var dashboardSymbolName: String {
        switch self {
        case .ok:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .critical:
            "xmark.octagon.fill"
        case .unknown:
            "questionmark.circle.fill"
        }
    }
}
