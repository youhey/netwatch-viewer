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

func formatMbps(_ value: Double?) -> String {
    guard let value else {
        return "-"
    }

    return String(format: "%.1f Mbps", value)
}

func formatBytes(_ value: Int?) -> String {
    guard let value else {
        return "-"
    }

    let bytes = Double(value)

    if bytes >= 1_048_576 {
        return String(format: "%.1f MB", bytes / 1_048_576)
    }

    if bytes >= 1_024 {
        return String(format: "%.1f KB", bytes / 1_024)
    }

    return "\(value) B"
}
