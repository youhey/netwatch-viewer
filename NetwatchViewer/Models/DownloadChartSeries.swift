//
//  DownloadChartSeries.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct DownloadChartSeries: Decodable, Identifiable {
    var id: String { name }

    let type: String?
    let name: String
    let url: String?
    let generatedAt: Date?
    let actualRangeStart: Date?
    let actualRangeEnd: Date?
    let timezone: String?
    let range: String
    let bucket: String
    let bucketSeconds: Int?
    let maxPoints: Int?
    let points: [DownloadChartPoint]

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case url
        case generatedAt
        case actualRangeStart
        case actualRangeEnd
        case timezone
        case range
        case bucket
        case bucketSeconds
        case maxPoints
        case points
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        actualRangeStart = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeStart))
        actualRangeEnd = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeEnd))
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        range = try container.decodeIfPresent(String.self, forKey: .range) ?? ""
        bucket = try container.decodeIfPresent(String.self, forKey: .bucket) ?? ""
        bucketSeconds = try container.decodeIfPresent(Int.self, forKey: .bucketSeconds)
        maxPoints = try container.decodeIfPresent(Int.self, forKey: .maxPoints)
        points = try container.decodeIfPresent([DownloadChartPoint].self, forKey: .points) ?? []
    }
}

struct DownloadChartPoint: Decodable, Identifiable {
    var id: Date { ts }

    let ts: Date
    let avgMbps: Double?
    let minMbps: Double?
    let maxMbps: Double?
    let failureCount: Int
    let timeoutCount: Int
    let sampleCount: Int

    enum CodingKeys: String, CodingKey {
        case ts
        case avgMbps
        case minMbps
        case maxMbps
        case failureCount
        case timeoutCount
        case sampleCount
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tsString = try container.decode(String.self, forKey: .ts)

        guard let parsedTS = ChartDateParser.parse(tsString) else {
            throw DecodingError.dataCorruptedError(forKey: .ts, in: container, debugDescription: "Invalid download chart timestamp.")
        }

        ts = parsedTS
        avgMbps = try container.decodeIfPresent(Double.self, forKey: .avgMbps)
        minMbps = try container.decodeIfPresent(Double.self, forKey: .minMbps)
        maxMbps = try container.decodeIfPresent(Double.self, forKey: .maxMbps)
        failureCount = try container.decodeIfPresent(Int.self, forKey: .failureCount) ?? 0
        timeoutCount = try container.decodeIfPresent(Int.self, forKey: .timeoutCount) ?? 0
        sampleCount = try container.decodeIfPresent(Int.self, forKey: .sampleCount) ?? 0
    }
}
