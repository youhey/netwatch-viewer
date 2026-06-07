//
//  MonitoringStatusHistorySummary.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct MonitoringStatusHistorySummary: Codable {
    let okCount: Int
    let warningCount: Int
    let criticalCount: Int
    let unknownCount: Int
}
