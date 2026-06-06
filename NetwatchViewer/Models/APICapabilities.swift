//
//  APICapabilities.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct APICapabilities: Decodable {
    let service: String?
    let version: String?
    let apiVersion: String?
    let generatedAt: Date?
    let features: APIFeatures
    let chart: APIChartCapabilities?

    enum CodingKeys: String, CodingKey {
        case service
        case version
        case apiVersion
        case generatedAt
        case features
        case chart
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        service = try container.decodeIfPresent(String.self, forKey: .service)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        apiVersion = try container.decodeIfPresent(String.self, forKey: .apiVersion)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        features = try container.decodeIfPresent(APIFeatures.self, forKey: .features) ?? APIFeatures()
        chart = try container.decodeIfPresent(APIChartCapabilities.self, forKey: .chart)
    }
}

struct APIFeatures: Decodable {
    let ping: Bool
    let dns: Bool
    let http: Bool
    let services: Bool
    let download: Bool
    let downloadSeries: Bool
    let charts: Bool
    let chartsCatalog: Bool
    let chartsOverview: Bool
    let chartsDownload: Bool
    let monitoringStatus: Bool
    let monitoringThresholds: Bool

    nonisolated init(
        ping: Bool = false,
        dns: Bool = false,
        http: Bool = false,
        services: Bool = false,
        download: Bool = false,
        downloadSeries: Bool = false,
        charts: Bool = false,
        chartsCatalog: Bool = false,
        chartsOverview: Bool = false,
        chartsDownload: Bool = false,
        monitoringStatus: Bool = false,
        monitoringThresholds: Bool = false
    ) {
        self.ping = ping
        self.dns = dns
        self.http = http
        self.services = services
        self.download = download
        self.downloadSeries = downloadSeries
        self.charts = charts
        self.chartsCatalog = chartsCatalog
        self.chartsOverview = chartsOverview
        self.chartsDownload = chartsDownload
        self.monitoringStatus = monitoringStatus
        self.monitoringThresholds = monitoringThresholds
    }

    enum CodingKeys: String, CodingKey {
        case ping
        case dns
        case http
        case services
        case download
        case downloadSeries
        case charts
        case chartsCatalog
        case chartsOverview
        case chartsDownload
        case monitoringStatus
        case monitoringThresholds
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ping = try container.decodeIfPresent(Bool.self, forKey: .ping) ?? false
        dns = try container.decodeIfPresent(Bool.self, forKey: .dns) ?? false
        http = try container.decodeIfPresent(Bool.self, forKey: .http) ?? false
        services = try container.decodeIfPresent(Bool.self, forKey: .services) ?? false
        download = try container.decodeIfPresent(Bool.self, forKey: .download) ?? false
        downloadSeries = try container.decodeIfPresent(Bool.self, forKey: .downloadSeries) ?? false
        charts = try container.decodeIfPresent(Bool.self, forKey: .charts) ?? false
        chartsCatalog = try container.decodeIfPresent(Bool.self, forKey: .chartsCatalog) ?? false
        chartsOverview = try container.decodeIfPresent(Bool.self, forKey: .chartsOverview) ?? false
        chartsDownload = try container.decodeIfPresent(Bool.self, forKey: .chartsDownload) ?? false
        monitoringStatus = try container.decodeIfPresent(Bool.self, forKey: .monitoringStatus) ?? false
        monitoringThresholds = try container.decodeIfPresent(Bool.self, forKey: .monitoringThresholds) ?? false
    }
}

struct APIChartCapabilities: Decodable {
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

struct ChartMaxPoints: Decodable {
    let min: Int?
    let max: Int?
    let defaultValue: Int?

    enum CodingKeys: String, CodingKey {
        case min
        case max
        case defaultValue = "default"
    }

    func clamped(_ value: Int) -> Int {
        var nextValue = value

        if let min, nextValue < min {
            nextValue = min
        }

        if let max, nextValue > max {
            nextValue = max
        }

        return nextValue
    }
}
