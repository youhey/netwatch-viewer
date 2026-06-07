//
//  MonitoringStatusHistoryResponse.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct MonitoringStatusHistoryResponse: Codable {
    let source: String?
    let generatedAt: Date?
    let range: String
    let bucket: String
    let bucketSeconds: Int?
    let actualRangeStart: Date?
    let actualRangeEnd: Date?
    let points: [MonitoringStatusHistoryPoint]
    let summary: MonitoringStatusHistorySummary?

    enum CodingKeys: String, CodingKey {
        case source
        case generatedAt
        case range
        case bucket
        case bucketSeconds
        case actualRangeStart
        case actualRangeEnd
        case points
        case summary
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        range = try container.decodeIfPresent(String.self, forKey: .range) ?? "24h"
        bucket = try container.decodeIfPresent(String.self, forKey: .bucket) ?? "1h"
        bucketSeconds = try container.decodeIfPresent(Int.self, forKey: .bucketSeconds)
        actualRangeStart = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeStart))
        actualRangeEnd = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeEnd))
        points = try container.decodeIfPresent([MonitoringStatusHistoryPoint].self, forKey: .points) ?? []
        summary = try container.decodeIfPresent(MonitoringStatusHistorySummary.self, forKey: .summary)
    }
}
