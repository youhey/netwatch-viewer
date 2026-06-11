//
//  SpeedprobeChartSeries.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/12.
//

import Foundation

struct SpeedprobeChartSeries: Decodable, Identifiable {
    var id: String { name }

    let type: String?
    let name: String
    let displayName: String?
    let displayOrder: Int?
    let metric: String?
    let unit: String?
    let generatedAt: Date?
    let actualRangeStart: Date?
    let actualRangeEnd: Date?
    let timezone: String?
    let range: String
    let bucket: String
    let bucketSeconds: Int?
    let maxPoints: Int?
    let points: [SpeedprobeChartPoint]

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case displayName
        case displayOrder
        case metric
        case unit
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
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder)
        metric = try container.decodeIfPresent(String.self, forKey: .metric)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        actualRangeStart = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeStart))
        actualRangeEnd = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeEnd))
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        range = try container.decodeIfPresent(String.self, forKey: .range) ?? ""
        bucket = try container.decodeIfPresent(String.self, forKey: .bucket) ?? ""
        bucketSeconds = try container.decodeIfPresent(Int.self, forKey: .bucketSeconds)
        maxPoints = try container.decodeIfPresent(Int.self, forKey: .maxPoints)
        points = try container.decodeIfPresent([SpeedprobeChartPoint].self, forKey: .points) ?? []
    }

    nonisolated var isThroughputSeries: Bool {
        let value = [metric, unit, name].compactMap { $0?.lowercased() }.joined(separator: " ")
        return value.contains("mbps")
    }

    nonisolated var isDurationSeries: Bool {
        let value = [metric, unit, name].compactMap { $0?.lowercased() }.joined(separator: " ")
        return value.contains("duration") || value.contains("duration_ms")
    }
}

struct SpeedprobeChartPoint: Decodable, Identifiable {
    var id: Date { ts }

    let ts: Date
    let avgMbps: Double?
    let minMbps: Double?
    let maxMbps: Double?
    let mbps: Double?
    let avgDurationMs: Double?
    let minDurationMs: Double?
    let maxDurationMs: Double?
    let durationMs: Double?
    let sampleCount: Int
    let failureCount: Int
    let timeoutCount: Int

    enum CodingKeys: String, CodingKey {
        case ts
        case avgMbps
        case minMbps
        case maxMbps
        case mbps
        case avgDurationMs
        case minDurationMs
        case maxDurationMs
        case durationMs
        case sampleCount
        case failureCount
        case timeoutCount
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tsString = try container.decode(String.self, forKey: .ts)

        guard let parsedTS = ChartDateParser.parse(tsString) else {
            throw DecodingError.dataCorruptedError(forKey: .ts, in: container, debugDescription: "Invalid speedprobe chart timestamp.")
        }

        ts = parsedTS
        avgMbps = try container.decodeIfPresent(Double.self, forKey: .avgMbps)
        minMbps = try container.decodeIfPresent(Double.self, forKey: .minMbps)
        maxMbps = try container.decodeIfPresent(Double.self, forKey: .maxMbps)
        mbps = try container.decodeIfPresent(Double.self, forKey: .mbps)
        avgDurationMs = try container.decodeIfPresent(Double.self, forKey: .avgDurationMs)
        minDurationMs = try container.decodeIfPresent(Double.self, forKey: .minDurationMs)
        maxDurationMs = try container.decodeIfPresent(Double.self, forKey: .maxDurationMs)
        durationMs = try container.decodeIfPresent(Double.self, forKey: .durationMs)
        sampleCount = try container.decodeIfPresent(Int.self, forKey: .sampleCount) ?? 0
        failureCount = try container.decodeIfPresent(Int.self, forKey: .failureCount) ?? 0
        timeoutCount = try container.decodeIfPresent(Int.self, forKey: .timeoutCount) ?? 0
    }

    nonisolated var throughputValue: Double? {
        avgMbps ?? mbps
    }

    nonisolated var throughputMaxValue: Double? {
        maxMbps
    }

    nonisolated var durationValue: Double? {
        avgDurationMs ?? durationMs
    }

    nonisolated var durationMaxValue: Double? {
        maxDurationMs
    }
}
