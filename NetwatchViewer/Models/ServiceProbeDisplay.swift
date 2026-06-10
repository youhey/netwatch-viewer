//
//  ServiceProbeDisplay.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/10.
//

import Foundation

enum ServiceProbeDisplay {
    nonisolated static func label(for sample: HTTPSample) -> String {
        if let label = sample.label, !label.isEmpty {
            return label
        }

        if let displayName = sample.displayName, !displayName.isEmpty {
            return displayName
        }

        if !sample.name.isEmpty {
            return prettifyIdentifier(sample.name)
        }

        return sample.url ?? "Unknown service"
    }

    nonisolated static func groupName(group: String?, category: String?) -> String {
        if let group = group?.lowercased(), let displayName = groupDisplayNames[group] {
            return displayName
        }

        if let category = category?.lowercased(), let displayName = categoryDisplayNames[category] {
            return displayName
        }

        if let group, !group.isEmpty {
            return prettifyIdentifier(group)
        }

        if let category, !category.isEmpty {
            return prettifyIdentifier(category)
        }

        return "Other"
    }

    nonisolated static func groupSortOrder(_ displayName: String) -> Int {
        groupDisplayOrder[displayName] ?? 999
    }

    nonisolated static func expectedStatuses(for sample: HTTPSample) -> [Int] {
        sample.expectedStatuses ?? sample.expectedStatusCodes ?? []
    }

    nonisolated static func expectedText(for sample: HTTPSample) -> String {
        let statuses = expectedStatuses(for: sample).sorted()

        guard !statuses.isEmpty else {
            return "2xx / 3xx"
        }

        let joined = statuses.map(String.init).joined(separator: statuses.count > 2 ? ", " : " / ")

        if statuses.allSatisfy({ (200..<400).contains($0) }) {
            return joined
        }

        return "\(joined) expected"
    }

    nonisolated static func prettifyIdentifier(_ value: String) -> String {
        value
            .split { character in
                character == "_" || character == "-"
            }
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    nonisolated private static let groupDisplayNames: [String: String] = [
        "github": "Dev Core",
        "openai": "AI",
        "laravel": "Deploy",
        "docker": "Container",
        "baseline": "Baseline",
        "youtube": "Entertainment",
        "netflix": "Entertainment",
        "steam": "Entertainment",
        "psn": "Game",
        "pcgame": "Game",
        "aws": "Cloud",
        "azure": "Cloud",
        "cloudflare": "Cloud",
        "slack": "Service"
    ]

    nonisolated private static let categoryDisplayNames: [String: String] = [
        "dev": "Dev Core",
        "ai": "AI",
        "cloud": "Cloud",
        "container": "Container",
        "game": "Game",
        "service": "Service",
        "baseline": "Baseline"
    ]

    nonisolated private static let groupDisplayOrder: [String: Int] = [
        "Entertainment": 10,
        "Game": 20,
        "Service": 30,
        "Baseline": 40,
        "Cloud": 50,
        "Dev Core": 60,
        "Deploy": 70,
        "Container": 80,
        "AI": 90,
        "Other": 999
    ]
}
