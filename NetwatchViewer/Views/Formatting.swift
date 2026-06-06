//
//  Formatting.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

func formatMilliseconds(_ value: Double?) -> String {
    guard let value else {
        return "-"
    }

    return String(format: "%.1f ms", value)
}

func formatPercent(_ value: Double?) -> String {
    guard let value else {
        return "-"
    }

    return String(format: "%.1f%%", value)
}

func formatHTTPStatus(_ value: Int?) -> String {
    guard let value else {
        return "-"
    }

    return String(value)
}
