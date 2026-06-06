//
//  ChartCatalog.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct ChartCatalog: Decodable {
    let generatedAt: Date?
    let timezone: String?
    let defaults: ChartCatalogDefaults?
    let supported: ChartCatalogSupported?
    let ping: [ChartCatalogPingTarget]
    let dns: [ChartCatalogDNSTarget]
    let http: [ChartCatalogHTTPTarget]
    let download: [ChartCatalogDownloadTarget]
    let serviceGroups: [ChartCatalogServiceGroup]

    enum CodingKeys: String, CodingKey {
        case generatedAt
        case timezone
        case defaults
        case supported
        case ping
        case dns
        case http
        case download
        case serviceGroups
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        defaults = try container.decodeIfPresent(ChartCatalogDefaults.self, forKey: .defaults)
        supported = try container.decodeIfPresent(ChartCatalogSupported.self, forKey: .supported)
        ping = try container.decodeIfPresent([ChartCatalogPingTarget].self, forKey: .ping) ?? []
        dns = try container.decodeIfPresent([ChartCatalogDNSTarget].self, forKey: .dns) ?? []
        http = try container.decodeIfPresent([ChartCatalogHTTPTarget].self, forKey: .http) ?? []
        download = try container.decodeIfPresent([ChartCatalogDownloadTarget].self, forKey: .download) ?? []
        serviceGroups = try container.decodeIfPresent([ChartCatalogServiceGroup].self, forKey: .serviceGroups) ?? []
    }
}

struct ChartCatalogDefaults: Decodable {
    let range: String?
    let bucket: String?
    let maxPoints: Int?
}

struct ChartCatalogSupported: Decodable {
    let ranges: [String]
    let buckets: [String]
    let maxPoints: ChartMaxPoints?

    enum CodingKeys: String, CodingKey {
        case ranges
        case buckets
        case maxPoints
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ranges = try container.decodeIfPresent([String].self, forKey: .ranges) ?? []
        buckets = try container.decodeIfPresent([String].self, forKey: .buckets) ?? []
        maxPoints = try container.decodeIfPresent(ChartMaxPoints.self, forKey: .maxPoints)
    }
}

struct ChartCatalogPingTarget: Decodable, Identifiable {
    var id: String { name }

    let name: String
    let displayName: String?
    let displayOrder: Int?
    let target: String?
    let label: String?
}

struct ChartCatalogDNSTarget: Decodable, Identifiable {
    var id: String { name }

    let name: String
    let displayName: String?
    let displayOrder: Int?
    let hostname: String?
    let label: String?
}

struct ChartCatalogHTTPTarget: Decodable, Identifiable {
    var id: String { name }

    let name: String
    let displayName: String?
    let displayOrder: Int?
    let group: String?
    let category: String?
    let url: String?
    let label: String?
}

struct ChartCatalogDownloadTarget: Decodable, Identifiable {
    var id: String { name }

    let name: String
    let displayName: String?
    let displayOrder: Int?
    let url: String?
    let expectedBytes: Int?
    let label: String?
}

struct ChartCatalogServiceGroup: Decodable, Identifiable {
    var id: String { group }

    let group: String
    let displayName: String?
    let displayOrder: Int?
    let category: String?
    let label: String?
}
