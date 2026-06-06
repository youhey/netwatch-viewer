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
    let service: ServiceMonitoringThresholds?

    enum CodingKeys: String, CodingKey {
        case generatedAt
        case ping
        case dns
        case http
        case service
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = ChartDateParser.parse(try container.decodeIfPresent(String.self, forKey: .generatedAt))
        ping = try container.decodeIfPresent(PingMonitoringThresholds.self, forKey: .ping)
        dns = try container.decodeIfPresent(DNSMonitoringThresholds.self, forKey: .dns)
        http = try container.decodeIfPresent(HTTPMonitoringThresholds.self, forKey: .http)
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

struct ServiceMonitoringThresholds: Decodable {
    let okRatePercent: ThresholdBand?
}
