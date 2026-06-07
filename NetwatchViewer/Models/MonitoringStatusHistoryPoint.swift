//
//  MonitoringStatusHistoryPoint.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct MonitoringStatusHistoryPoint: Codable, Identifiable {
    var id: Date { bucketStart }

    let bucketStart: Date
    let bucketEnd: Date?
    let level: MonitoringLevel
    let alert: Bool
    let sampleCount: Int
    let criticalCount: Int
    let warningCount: Int
    let unknownCount: Int
    let okCount: Int

    enum CodingKeys: String, CodingKey {
        case bucketStart
        case bucketEnd
        case level
        case alert
        case sampleCount
        case criticalCount
        case warningCount
        case unknownCount
        case okCount
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bucketStartString = try container.decode(String.self, forKey: .bucketStart)

        guard let bucketStart = ChartDateParser.parse(bucketStartString) else {
            throw DecodingError.dataCorruptedError(forKey: .bucketStart, in: container, debugDescription: "bucket_start を Date に変換できません。")
        }

        self.bucketStart = bucketStart
        bucketEnd = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .bucketEnd))
        level = try container.decodeIfPresent(MonitoringLevel.self, forKey: .level) ?? .unknown
        alert = try container.decodeIfPresent(Bool.self, forKey: .alert) ?? false
        sampleCount = try container.decodeIfPresent(Int.self, forKey: .sampleCount) ?? 0
        criticalCount = try container.decodeIfPresent(Int.self, forKey: .criticalCount) ?? 0
        warningCount = try container.decodeIfPresent(Int.self, forKey: .warningCount) ?? 0
        unknownCount = try container.decodeIfPresent(Int.self, forKey: .unknownCount) ?? 0
        okCount = try container.decodeIfPresent(Int.self, forKey: .okCount) ?? 0
    }
}
