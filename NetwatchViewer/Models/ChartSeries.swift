//
//  ChartSeries.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct ChartRange: RawRepresentable, CaseIterable, Hashable, Identifiable {
    nonisolated static let oneHour = ChartRange(rawValue: "1h")
    nonisolated static let sixHours = ChartRange(rawValue: "6h")
    nonisolated static let twentyFourHours = ChartRange(rawValue: "24h")
    nonisolated static let sevenDays = ChartRange(rawValue: "7d")
    nonisolated static let allCases: [ChartRange] = [.oneHour, .sixHours, .twentyFourHours, .sevenDays]

    let rawValue: String

    var id: String { rawValue }

    nonisolated init(rawValue: String) {
        self.rawValue = rawValue
    }

    var title: String {
        rawValue
    }

    var recommendedBucket: ChartBucket {
        switch rawValue {
        case "1h":
            .oneMinute
        case "6h", "24h":
            .fiveMinutes
        case "7d", "14d":
            .oneHour
        default:
            .fiveMinutes
        }
    }
}

struct ChartBucket: RawRepresentable, CaseIterable, Hashable, Identifiable {
    nonisolated static let oneMinute = ChartBucket(rawValue: "1m")
    nonisolated static let fiveMinutes = ChartBucket(rawValue: "5m")
    nonisolated static let fifteenMinutes = ChartBucket(rawValue: "15m")
    nonisolated static let oneHour = ChartBucket(rawValue: "1h")
    nonisolated static let allCases: [ChartBucket] = [.oneMinute, .fiveMinutes, .fifteenMinutes, .oneHour]

    let rawValue: String

    var id: String { rawValue }

    nonisolated init(rawValue: String) {
        self.rawValue = rawValue
    }

    var title: String {
        rawValue
    }
}

struct PingChartSeries: Decodable, Identifiable {
    var id: String { name }

    let type: String
    let name: String
    let target: String?
    let generatedAt: Date?
    let actualRangeStart: Date?
    let actualRangeEnd: Date?
    let timezone: String?
    let range: String
    let bucket: String
    let bucketSeconds: Int?
    let maxPoints: Int?
    let points: [PingChartPoint]

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case target
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
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        target = try container.decodeIfPresent(String.self, forKey: .target)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        actualRangeStart = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeStart))
        actualRangeEnd = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeEnd))
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        range = try container.decode(String.self, forKey: .range)
        bucket = try container.decode(String.self, forKey: .bucket)
        bucketSeconds = try container.decodeIfPresent(Int.self, forKey: .bucketSeconds)
        maxPoints = try container.decodeIfPresent(Int.self, forKey: .maxPoints)

        let rawPoints = try container.decodeIfPresent([PingChartRawPoint].self, forKey: .points) ?? []
        points = rawPoints.compactMap(PingChartPoint.init(rawPoint:))
    }
}

struct PingChartPoint: Identifiable {
    var id: Date { ts }

    let ts: Date
    let avgMs: Double?
    let minMs: Double?
    let maxMs: Double?
    let lossPercent: Double?
    let sampleCount: Int?

    nonisolated fileprivate init?(rawPoint: PingChartRawPoint) {
        guard let ts = ChartDateParser.parse(rawPoint.ts) else {
            return nil
        }

        self.ts = ts
        avgMs = rawPoint.avgMs
        minMs = rawPoint.minMs
        maxMs = rawPoint.maxMs
        lossPercent = rawPoint.lossPercent
        sampleCount = rawPoint.sampleCount
    }
}

struct HTTPChartSeries: Decodable, Identifiable {
    var id: String { name }

    let type: String
    let name: String
    let group: String?
    let category: String?
    let url: String?
    let generatedAt: Date?
    let actualRangeStart: Date?
    let actualRangeEnd: Date?
    let timezone: String?
    let range: String
    let bucket: String
    let bucketSeconds: Int?
    let maxPoints: Int?
    let points: [HTTPChartPoint]

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case group
        case category
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
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        group = try container.decodeIfPresent(String.self, forKey: .group)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        actualRangeStart = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeStart))
        actualRangeEnd = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeEnd))
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        range = try container.decode(String.self, forKey: .range)
        bucket = try container.decode(String.self, forKey: .bucket)
        bucketSeconds = try container.decodeIfPresent(Int.self, forKey: .bucketSeconds)
        maxPoints = try container.decodeIfPresent(Int.self, forKey: .maxPoints)

        let rawPoints = try container.decodeIfPresent([HTTPChartRawPoint].self, forKey: .points) ?? []
        points = rawPoints.compactMap(HTTPChartPoint.init(rawPoint:))
    }
}

struct HTTPChartPoint: Identifiable {
    var id: Date { ts }

    let ts: Date
    let avgTotalMs: Double?
    let avgTtfbMs: Double?
    let maxTotalMs: Double?
    let failureCount: Int?
    let timeoutCount: Int?
    let sampleCount: Int?

    nonisolated fileprivate init?(rawPoint: HTTPChartRawPoint) {
        guard let ts = ChartDateParser.parse(rawPoint.ts) else {
            return nil
        }

        self.ts = ts
        avgTotalMs = rawPoint.avgTotalMs
        avgTtfbMs = rawPoint.avgTtfbMs
        maxTotalMs = rawPoint.maxTotalMs
        failureCount = rawPoint.failureCount
        timeoutCount = rawPoint.timeoutCount
        sampleCount = rawPoint.sampleCount
    }
}

struct ServiceChartSeries: Decodable, Identifiable {
    var id: String { group }

    let type: String
    let group: String
    let category: String?
    let generatedAt: Date?
    let actualRangeStart: Date?
    let actualRangeEnd: Date?
    let timezone: String?
    let range: String
    let bucket: String
    let bucketSeconds: Int?
    let maxPoints: Int?
    let targets: [String]
    let points: [ServiceChartPoint]

    enum CodingKeys: String, CodingKey {
        case type
        case group
        case category
        case generatedAt
        case actualRangeStart
        case actualRangeEnd
        case timezone
        case range
        case bucket
        case bucketSeconds
        case maxPoints
        case targets
        case points
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        group = try container.decode(String.self, forKey: .group)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        actualRangeStart = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeStart))
        actualRangeEnd = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .actualRangeEnd))
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        range = try container.decode(String.self, forKey: .range)
        bucket = try container.decode(String.self, forKey: .bucket)
        bucketSeconds = try container.decodeIfPresent(Int.self, forKey: .bucketSeconds)
        maxPoints = try container.decodeIfPresent(Int.self, forKey: .maxPoints)
        targets = try container.decodeIfPresent([String].self, forKey: .targets) ?? []

        let rawPoints = try container.decodeIfPresent([ServiceChartRawPoint].self, forKey: .points) ?? []
        points = rawPoints.compactMap(ServiceChartPoint.init(rawPoint:))
    }
}

struct ServiceChartPoint: Identifiable {
    var id: Date { ts }

    let ts: Date
    let avgTotalMs: Double?
    let maxTotalMs: Double?
    let okRate: Double?
    let failureCount: Int?
    let sampleCount: Int?

    nonisolated fileprivate init?(rawPoint: ServiceChartRawPoint) {
        guard let ts = ChartDateParser.parse(rawPoint.ts) else {
            return nil
        }

        self.ts = ts
        avgTotalMs = rawPoint.avgTotalMs
        maxTotalMs = rawPoint.maxTotalMs
        okRate = rawPoint.okRate
        failureCount = rawPoint.failureCount
        sampleCount = rawPoint.sampleCount
    }
}

private struct PingChartRawPoint: Decodable {
    let ts: String
    let avgMs: Double?
    let minMs: Double?
    let maxMs: Double?
    let lossPercent: Double?
    let sampleCount: Int?
}

private struct HTTPChartRawPoint: Decodable {
    let ts: String
    let avgTotalMs: Double?
    let avgTtfbMs: Double?
    let maxTotalMs: Double?
    let failureCount: Int?
    let timeoutCount: Int?
    let sampleCount: Int?
}

private struct ServiceChartRawPoint: Decodable {
    let ts: String
    let avgTotalMs: Double?
    let maxTotalMs: Double?
    let okRate: Double?
    let failureCount: Int?
    let sampleCount: Int?
}

enum ChartDateParser {
    nonisolated static func parse(_ value: String?) -> Date? {
        guard let value else {
            return nil
        }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let standardFormatter = ISO8601DateFormatter()
        standardFormatter.formatOptions = [.withInternetDateTime]

        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        if let date = standardFormatter.date(from: value) {
            return date
        }

        if let trimmedValue = trimFractionalSeconds(value), let date = fractionalFormatter.date(from: trimmedValue) {
            return date
        }

        return nil
    }

    nonisolated private static func trimFractionalSeconds(_ value: String) -> String? {
        guard let dotRange = value.range(of: ".") else {
            return nil
        }

        let fractionStart = dotRange.upperBound
        let suffixStart = value[fractionStart...].firstIndex { character in
            character == "+" || character == "-" || character == "Z"
        }

        guard let suffixStart else {
            return nil
        }

        let fraction = value[fractionStart..<suffixStart]
        let suffix = value[suffixStart...]
        return String(value[..<fractionStart]) + fraction.prefix(6) + suffix
    }
}
