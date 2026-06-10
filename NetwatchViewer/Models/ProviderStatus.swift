//
//  ProviderStatus.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/10.
//

import Foundation

struct MonitoringCompactResponse: Decodable {
    let source: String?
    let generatedAt: Date?
    let level: MonitoringLevel?
    let label: String?
    let alert: Bool?
    let title: String?
    let message: String?
    let issueCount: Int?
    let reasons: [MonitoringReason]?
    let networkStatus: CompactNetworkStatus?
    let serviceHealth: CompactServiceHealth?
    let providerStatus: ProviderStatusSummary?

    enum CodingKeys: String, CodingKey {
        case source
        case generatedAt
        case level
        case label
        case alert
        case title
        case message
        case issueCount
        case reasons
        case networkStatus
        case serviceHealth
        case providerStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        level = try container.decodeIfPresent(MonitoringLevel.self, forKey: .level)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        alert = try container.decodeIfPresent(Bool.self, forKey: .alert)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        issueCount = try container.decodeIfPresent(Int.self, forKey: .issueCount)
        reasons = try container.decodeIfPresent([MonitoringReason].self, forKey: .reasons)
        networkStatus = try container.decodeIfPresent(CompactNetworkStatus.self, forKey: .networkStatus)
        serviceHealth = try container.decodeIfPresent(CompactServiceHealth.self, forKey: .serviceHealth)
        providerStatus = try container.decodeIfPresent(ProviderStatusSummary.self, forKey: .providerStatus)
    }

    var resolvedNetworkStatus: CompactNetworkStatus? {
        if let networkStatus {
            return networkStatus
        }

        guard level != nil || alert != nil || title != nil || message != nil || issueCount != nil || reasons != nil else {
            return nil
        }

        return CompactNetworkStatus(
            level: level,
            label: label,
            alert: alert,
            title: title,
            message: message,
            issueCount: issueCount,
            reasons: reasons
        )
    }
}

struct CompactNetworkStatus: Decodable {
    let level: MonitoringLevel?
    let label: String?
    let alert: Bool?
    let title: String?
    let message: String?
    let issueCount: Int?
    let reasons: [MonitoringReason]?

    init(
        level: MonitoringLevel?,
        label: String?,
        alert: Bool?,
        title: String?,
        message: String?,
        issueCount: Int?,
        reasons: [MonitoringReason]?
    ) {
        self.level = level
        self.label = label
        self.alert = alert
        self.title = title
        self.message = message
        self.issueCount = issueCount
        self.reasons = reasons
    }

    func monitoringStatus(source: String?, generatedAt: Date?) -> MonitoringStatus {
        let resolvedReasons = reasons ?? []

        return MonitoringStatus(
            alert: alert ?? false,
            source: source,
            statusId: nil,
            generatedAt: generatedAt,
            level: level ?? .unknown,
            title: title ?? "",
            message: message ?? "",
            primaryReason: resolvedReasons.first,
            reasons: resolvedReasons
        )
    }
}

struct CompactServiceHealth: Decodable {
    let level: MonitoringLevel?
    let alert: Bool?
    let issueCount: Int?
    let summary: [CompactServiceHealthGroupSummary]
    let issues: [CompactServiceHealthIssue]

    enum CodingKeys: String, CodingKey {
        case level
        case alert
        case issueCount
        case summary
        case issues
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decodeIfPresent(MonitoringLevel.self, forKey: .level)
        alert = try container.decodeIfPresent(Bool.self, forKey: .alert)
        issueCount = try container.decodeIfPresent(Int.self, forKey: .issueCount)
        summary = try container.decodeIfPresent([CompactServiceHealthGroupSummary].self, forKey: .summary) ?? []
        issues = try container.decodeIfPresent([CompactServiceHealthIssue].self, forKey: .issues) ?? []
    }
}

struct CompactServiceHealthGroupSummary: Decodable, Identifiable {
    var id: String { group }

    let group: String
    let label: String?
    let level: MonitoringLevel
    let ok: Int?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case group
        case label
        case level
        case ok
        case total
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        group = try container.decodeIfPresent(String.self, forKey: .group) ?? "other"
        label = try container.decodeIfPresent(String.self, forKey: .label)
        level = try container.decodeIfPresent(MonitoringLevel.self, forKey: .level) ?? .unknown
        ok = try container.decodeIfPresent(Int.self, forKey: .ok)
        total = try container.decodeIfPresent(Int.self, forKey: .total)
    }
}

struct CompactServiceHealthIssue: Decodable, Identifiable {
    var id: String { name }

    let name: String
    let label: String?
    let group: String?
    let category: String?
    let level: MonitoringLevel
    let reason: String?
    let httpStatusCode: Int?
    let durationMs: Double?
    let measuredAt: Date?

    enum CodingKeys: String, CodingKey {
        case name
        case label
        case group
        case category
        case level
        case reason
        case httpStatusCode
        case durationMs
        case measuredAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "unknown"
        label = try container.decodeIfPresent(String.self, forKey: .label)
        group = try container.decodeIfPresent(String.self, forKey: .group)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        level = try container.decodeIfPresent(MonitoringLevel.self, forKey: .level) ?? .unknown
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        httpStatusCode = try container.decodeIfPresent(Int.self, forKey: .httpStatusCode)
        durationMs = try container.decodeIfPresent(Double.self, forKey: .durationMs)
        measuredAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .measuredAt))
    }

    nonisolated var displayLabel: String {
        if let label, !label.isEmpty {
            return label
        }

        return ServiceProbeDisplay.prettifyIdentifier(name)
    }

    nonisolated var isIssue: Bool {
        level != .ok
    }
}

struct StatusPagesLatestResponse: Decodable {
    let generatedAt: Date?
    let providers: [ProviderStatusItem]

    enum CodingKeys: String, CodingKey {
        case generatedAt
        case providers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        providers = try container.decodeIfPresent([ProviderStatusItem].self, forKey: .providers) ?? []
    }

    var providerStatusSummary: ProviderStatusSummary {
        ProviderStatusSummary(providers: providers)
    }
}

struct ProviderStatusSummary: Decodable {
    let level: MonitoringLevel
    let alert: Bool
    let issueCount: Int
    let providers: [ProviderStatusItem]

    var issueProviders: [ProviderStatusItem] {
        var seen: Set<String> = []

        return providers.filter(\.isIssue).filter { provider in
            let key = [
                provider.displayLabel,
                provider.level.rawValue,
                provider.description ?? provider.indicator ?? ""
            ].joined(separator: "\u{1f}")

            return seen.insert(key).inserted
        }
    }

    enum CodingKeys: String, CodingKey {
        case level
        case alert
        case issueCount
        case providers
    }

    init(providers: [ProviderStatusItem]) {
        self.providers = providers
        level = ProviderStatusSummary.aggregateLevel(providers.map(\.level))
        alert = level == .warning || level == .critical
        issueCount = providers.filter(\.isIssue).count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        providers = try container.decodeIfPresent([ProviderStatusItem].self, forKey: .providers) ?? []
        level = try container.decodeIfPresent(MonitoringLevel.self, forKey: .level) ?? ProviderStatusSummary.aggregateLevel(providers.map(\.level))
        alert = try container.decodeIfPresent(Bool.self, forKey: .alert) ?? (level == .warning || level == .critical)
        issueCount = try container.decodeIfPresent(Int.self, forKey: .issueCount) ?? providers.filter(\.isIssue).count
    }

    private static func aggregateLevel(_ levels: [MonitoringLevel]) -> MonitoringLevel {
        if levels.contains(.critical) {
            return .critical
        }

        if levels.contains(.warning) {
            return .warning
        }

        if levels.contains(.unknown) {
            return .unknown
        }

        return .ok
    }
}

struct ProviderStatusItem: Decodable, Identifiable {
    var id: String { name }

    let name: String
    let label: String
    let group: String?
    let category: String?
    let level: MonitoringLevel
    let description: String?
    let indicator: String?
    let measuredAt: Date?
    let error: String?

    nonisolated var displayLabel: String {
        label.isEmpty ? name : label
    }

    nonisolated var isIssue: Bool {
        level == .warning || level == .critical
    }

    enum CodingKeys: String, CodingKey {
        case name
        case label
        case group
        case category
        case level
        case description
        case indicator
        case measuredAt
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "unknown"
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? name
        group = try container.decodeIfPresent(String.self, forKey: .group)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        level = try container.decodeIfPresent(MonitoringLevel.self, forKey: .level) ?? .unknown
        description = try container.decodeIfPresent(String.self, forKey: .description)
        indicator = try container.decodeIfPresent(String.self, forKey: .indicator)
        measuredAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .measuredAt))
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }
}
