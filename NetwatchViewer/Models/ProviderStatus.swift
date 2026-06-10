//
//  ProviderStatus.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/10.
//

import Foundation

struct MonitoringCompactResponse: Decodable {
    let providerStatus: ProviderStatusSummary?
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
        providers.filter(\.isIssue)
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
    let level: MonitoringLevel
    let description: String?
    let measuredAt: Date?
    let error: String?

    var displayLabel: String {
        label.isEmpty ? name : label
    }

    var isIssue: Bool {
        level == .warning || level == .critical
    }

    enum CodingKeys: String, CodingKey {
        case name
        case label
        case level
        case description
        case measuredAt
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "unknown"
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? name
        level = try container.decodeIfPresent(MonitoringLevel.self, forKey: .level) ?? .unknown
        description = try container.decodeIfPresent(String.self, forKey: .description)
        measuredAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .measuredAt))
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }
}
