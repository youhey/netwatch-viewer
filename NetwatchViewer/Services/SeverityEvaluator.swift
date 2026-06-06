//
//  SeverityEvaluator.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct SeverityEvaluator {
    let thresholds: MonitoringThresholds?

    func severityForGatewayPing(_ sample: PingSample) -> MonitoringLevel {
        guard sample.ok else {
            return .critical
        }

        return worst(
            severityForHighValue(sample.rttAvgMs, band: thresholds?.ping?.gatewayRttAvgMs ?? Self.defaultGatewayRttAvgMs),
            severityForGatewayLoss(sample.lossPercent)
        )
    }

    func severityForExternalPing(_ sample: PingSample) -> MonitoringLevel {
        guard sample.ok else {
            return .critical
        }

        return worst(
            severityForExternalRTT(sample.rttAvgMs),
            severityForExternalLoss(sample.lossPercent)
        )
    }

    func severityForDNS(_ sample: DNSSample) -> MonitoringLevel {
        guard sample.ok else {
            return .warning
        }

        return severityForHighValue(sample.durationMs, band: thresholds?.dns?.durationMs ?? Self.defaultDNSDurationMs)
    }

    func severityForHTTP(_ sample: HTTPSample) -> MonitoringLevel {
        guard sample.ok else {
            return .warning
        }

        return severityForHighValue(sample.totalMs, band: thresholds?.http?.totalMs ?? Self.defaultHTTPTotalMs)
    }

    func severityForDownload(_ sample: DownloadSample) -> MonitoringLevel {
        guard sample.ok else {
            return .warning
        }

        return severityForLowValue(sample.mbps, band: downloadThreshold(for: sample.name))
    }

    func severityForPing(_ sample: PingSample) -> MonitoringLevel {
        isGateway(sample) ? severityForGatewayPing(sample) : severityForExternalPing(sample)
    }

    func severityForExternalRTT(_ value: Double?) -> MonitoringLevel {
        severityForHighValue(value, band: thresholds?.ping?.externalRttAvgMs ?? Self.defaultExternalRttAvgMs)
    }

    func severityForExternalLoss(_ value: Double?) -> MonitoringLevel {
        severityForHighValue(value, band: thresholds?.ping?.externalLossPercent ?? Self.defaultExternalLossPercent)
    }

    func severityForGatewayLoss(_ value: Double?) -> MonitoringLevel {
        guard let value else {
            return .unknown
        }

        let band = thresholds?.ping?.gatewayLossPercent ?? Self.defaultGatewayLossPercent

        if let critical = band.critical, value >= critical {
            return .critical
        }

        if let warning = band.warning, value > warning {
            return .warning
        }

        return .ok
    }

    func severityForServiceSummary(_ samples: [HTTPSample]) -> MonitoringLevel {
        guard !samples.isEmpty else {
            return .unknown
        }

        return worst(samples.map(severityForHTTP))
    }

    func severityForPacketLossSummary(_ samples: [PingSample]) -> MonitoringLevel {
        guard !samples.isEmpty else {
            return .unknown
        }

        return worst(samples.map { sample in
            if !sample.ok {
                return .critical
            }

            return isGateway(sample) ? severityForGatewayLoss(sample.lossPercent) : severityForExternalLoss(sample.lossPercent)
        })
    }

    func isGateway(_ sample: PingSample) -> Bool {
        sample.name.caseInsensitiveCompare("gateway") == .orderedSame
    }

    private func downloadThreshold(for name: String) -> ThresholdBand {
        thresholds?.download?.threshold(for: name) ?? Self.defaultDownloadThreshold(for: name)
    }

    private func severityForHighValue(_ value: Double?, band: ThresholdBand) -> MonitoringLevel {
        guard let value else {
            return .unknown
        }

        if band.warning == nil, band.critical == nil {
            return .unknown
        }

        if let critical = band.critical, value >= critical {
            return .critical
        }

        if let warning = band.warning, value >= warning {
            return .warning
        }

        return .ok
    }

    private func severityForLowValue(_ value: Double?, band: ThresholdBand) -> MonitoringLevel {
        guard let value else {
            return .unknown
        }

        if band.warning == nil, band.critical == nil {
            return .unknown
        }

        if let critical = band.critical, value < critical {
            return .critical
        }

        if let warning = band.warning, value < warning {
            return .warning
        }

        return .ok
    }

    private func worst(_ levels: [MonitoringLevel]) -> MonitoringLevel {
        levels.min { lhs, rhs in
            lhs.sortPriority < rhs.sortPriority
        } ?? .unknown
    }

    private func worst(_ lhs: MonitoringLevel, _ rhs: MonitoringLevel) -> MonitoringLevel {
        worst([lhs, rhs])
    }

    private static func defaultDownloadThreshold(for name: String) -> ThresholdBand {
        switch name.lowercased() {
        case "r2_1mb":
            return ThresholdBand(warning: 5, critical: 1)
        case "r2_10mb":
            return ThresholdBand(warning: 10, critical: 3)
        default:
            return ThresholdBand(warning: nil, critical: nil)
        }
    }

    private static let defaultGatewayRttAvgMs = ThresholdBand(warning: 5, critical: 20)
    private static let defaultGatewayLossPercent = ThresholdBand(warning: 0.1, critical: 1)
    private static let defaultExternalRttAvgMs = ThresholdBand(warning: 100, critical: 200)
    private static let defaultExternalLossPercent = ThresholdBand(warning: 1, critical: 5)
    private static let defaultDNSDurationMs = ThresholdBand(warning: 300, critical: 1_000)
    private static let defaultHTTPTotalMs = ThresholdBand(warning: 3_000, critical: 5_000)
}
