//
//  MonitoringThresholds.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct MonitoringThresholds: Decodable {
    let generatedAt: Date?
    let ping: PingMonitoringThresholds?
    let dns: DNSMonitoringThresholds?
    let http: HTTPMonitoringThresholds?
    let download: DownloadMonitoringThresholds?
    let service: ServiceMonitoringThresholds?

    enum CodingKeys: String, CodingKey {
        case generatedAt
        case ping
        case dns
        case http
        case download
        case service
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        ping = try container.decodeIfPresent(PingMonitoringThresholds.self, forKey: .ping)
        dns = try container.decodeIfPresent(DNSMonitoringThresholds.self, forKey: .dns)
        http = try container.decodeIfPresent(HTTPMonitoringThresholds.self, forKey: .http)
        download = try container.decodeIfPresent(DownloadMonitoringThresholds.self, forKey: .download)
        service = try container.decodeIfPresent(ServiceMonitoringThresholds.self, forKey: .service)
    }
}

struct ThresholdBand: Decodable {
    let warning: Double?
    let critical: Double?
}

struct PingMonitoringThresholds: Decodable {
    let externalRttAvgMs: ThresholdBand?
    let externalLossPercent: ThresholdBand?
    let gatewayLossPercent: ThresholdBand?
}

struct DNSMonitoringThresholds: Decodable {
    let durationMs: ThresholdBand?
}

struct HTTPMonitoringThresholds: Decodable {
    let totalMs: ThresholdBand?
}

struct DownloadMonitoringThresholds: Decodable {
    let values: [String: ThresholdBand]

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var nextValues: [String: ThresholdBand] = [:]

        for key in container.allKeys {
            nextValues[key.stringValue] = try container.decode(ThresholdBand.self, forKey: key)
        }

        values = nextValues
    }

    func threshold(for downloadName: String) -> ThresholdBand? {
        values["\(downloadName)_mbps"]
    }
}

struct ServiceMonitoringThresholds: Decodable {
    let okRatePercent: ThresholdBand?
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}
