//
//  SeverityChip.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct SeverityChip: View {
    let level: MonitoringLevel

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(level.dashboardAccentColor)
                .frame(width: 7, height: 7)

            Text(level.dashboardLabel)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(level.dashboardAccentColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(level.dashboardAccentColor.opacity(0.14))
        )
        .overlay(
            Capsule()
                .stroke(level.dashboardAccentColor.opacity(0.42), lineWidth: 1)
        )
    }
}

extension MonitoringLevel {
    var dashboardLabel: String {
        switch self {
        case .ok:
            return "OK"
        case .warning:
            return "WARN"
        case .critical:
            return "CRIT"
        case .unknown:
            return "UNKNOWN"
        }
    }

    var dashboardAccentColor: Color {
        switch self {
        case .ok:
            return Color(red: 0.24, green: 0.78, blue: 0.58)
        case .warning:
            return Color(red: 0.96, green: 0.68, blue: 0.28)
        case .critical:
            return Color(red: 0.98, green: 0.32, blue: 0.38)
        case .unknown:
            return Color(red: 0.58, green: 0.66, blue: 0.76)
        }
    }

    var dashboardSurfaceColor: Color {
        dashboardAccentColor.opacity(0.08)
    }
}

#Preview {
    HStack(spacing: 10) {
        SeverityChip(level: .ok)
        SeverityChip(level: .warning)
        SeverityChip(level: .critical)
        SeverityChip(level: .unknown)
    }
    .padding()
    .background(Color(red: 0.06, green: 0.08, blue: 0.11))
}
