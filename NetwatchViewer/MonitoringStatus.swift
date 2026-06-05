//
//  MonitoringStatus.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct MonitoringStatus: Codable {
    let alert: Bool
    let source: String
    let level: String
    let title: String
    let message: String

    var status: String {
        alert ? "alert" : "normal"
    }
}
