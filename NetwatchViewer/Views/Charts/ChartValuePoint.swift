//
//  ChartValuePoint.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct ChartValuePoint: Identifiable {
    let id: String
    let series: String
    let ts: Date
    let value: Double
}
