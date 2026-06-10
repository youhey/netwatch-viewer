//
//  MonitoringStatus.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct MonitoringStatus: Codable {
    let alert: Bool
    let source: String?
    let statusId: String?
    let generatedAt: Date?
    let level: MonitoringLevel
    let title: String
    let message: String
    let primaryReason: MonitoringReason?
    let reasons: [MonitoringReason]

    var status: String {
        alert ? "alert" : "normal"
    }

    var issueCount: Int {
        reasons.count
    }

    var shortDetail: String {
        primaryReason?.summaryText ?? message
    }

    enum CodingKeys: String, CodingKey {
        case alert
        case source
        case statusId
        case generatedAt
        case level
        case title
        case message
        case primaryReason
        case reasons
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alert = try container.decodeIfPresent(Bool.self, forKey: .alert) ?? false
        source = try container.decodeIfPresent(String.self, forKey: .source)
        statusId = try container.decodeIfPresent(String.self, forKey: .statusId)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        level = try container.decodeIfPresent(MonitoringLevel.self, forKey: .level) ?? .unknown
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "NET UNKNOWN"
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        primaryReason = try container.decodeIfPresent(MonitoringReason.self, forKey: .primaryReason)
        reasons = try container.decodeIfPresent([MonitoringReason].self, forKey: .reasons) ?? []
    }
}

enum MonitoringLevel: String, Codable, Equatable {
    case ok
    case warning
    case critical
    case unknown

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        self = MonitoringLevel(rawValue: rawValue) ?? .unknown
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var displayText: String {
        rawValue.uppercased()
    }

    nonisolated var sortPriority: Int {
        switch self {
        case .critical:
            return 0
        case .warning:
            return 1
        case .unknown:
            return 2
        case .ok:
            return 3
        }
    }
}

struct MonitoringReason: Codable, Identifiable, Equatable {
    var id: String {
        "\(code)-\(target ?? "")-\(metric ?? "")"
    }

    let code: String
    let level: MonitoringLevel
    let target: String?
    let metric: String?
    let value: Double?
    let warning: Double?
    let critical: Double?
    let observedCount: Int?
    let requiredCount: Int?

    var summaryText: String {
        [code, target, formattedValue].compactMap { value in
            guard let value, !value.isEmpty else {
                return nil
            }

            return value
        }
        .joined(separator: " ")
    }

    var detailText: String {
        var parts: [String] = []

        if let target {
            parts.append(target)
        }

        if let metric {
            parts.append(metric)
        }

        if let formattedValue {
            parts.append(formattedValue)
        }

        if let warning {
            parts.append("warn \(formatNumber(warning))")
        }

        if let critical {
            parts.append("crit \(formatNumber(critical))")
        }

        if let observedCount, let requiredCount {
            parts.append("\(observedCount)/\(requiredCount)")
        }

        return parts.joined(separator: " / ")
    }

    private var formattedValue: String? {
        guard let value else {
            return nil
        }

        let formatted = formatNumber(value)

        switch metric {
        case let metric? where metric.contains("percent"):
            return "\(formatted)%"
        case let metric? where metric.contains("_ms"):
            return "\(formatted)ms"
        case let metric? where metric == "mbps":
            return "\(formatted)Mbps"
        default:
            return formatted
        }
    }

    private func formatNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
