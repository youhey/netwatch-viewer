//
//  ChartsOverviewResponse.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct ChartsOverviewResponse: Decodable {
    let generatedAt: Date?
    let actualRangeStart: Date?
    let actualRangeEnd: Date?
    let timezone: String?
    let range: String?
    let bucket: String?
    let bucketSeconds: Int?
    let maxPoints: Int?
    let ping: [PingChartSeries]
    let http: [HTTPChartSeries]
    let serviceGroups: [ServiceChartSeries]

    enum CodingKeys: String, CodingKey {
        case generatedAt
        case actualRangeStart
        case actualRangeEnd
        case timezone
        case range
        case bucket
        case bucketSeconds
        case maxPoints
        case ping
        case http
        case serviceGroups
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        actualRangeStart = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeStart))
        actualRangeEnd = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeEnd))
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        range = try container.decodeIfPresent(String.self, forKey: .range)
        bucket = try container.decodeIfPresent(String.self, forKey: .bucket)
        bucketSeconds = try container.decodeIfPresent(Int.self, forKey: .bucketSeconds)
        maxPoints = try container.decodeIfPresent(Int.self, forKey: .maxPoints)
        ping = try container.decodeIfPresent([PingChartSeries].self, forKey: .ping) ?? []
        http = try container.decodeIfPresent([HTTPChartSeries].self, forKey: .http) ?? []
        serviceGroups = try container.decodeIfPresent([ServiceChartSeries].self, forKey: .serviceGroups) ?? []
    }
}
