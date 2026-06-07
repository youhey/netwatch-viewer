//
//  MetricCard.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String?
    let subtitle: String?
    let severity: MonitoringLevel
    let systemImage: String?
    let sparkline: [Double]

    init(
        title: String,
        value: String,
        unit: String? = nil,
        subtitle: String? = nil,
        severity: MonitoringLevel = .unknown,
        systemImage: String? = nil,
        sparkline: [Double] = []
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.subtitle = subtitle
        self.severity = severity
        self.systemImage = systemImage
        self.sparkline = sparkline
    }

    init(
        title: String,
        value: Double,
        unit: String? = nil,
        subtitle: String? = nil,
        severity: MonitoringLevel = .unknown,
        systemImage: String? = nil,
        sparkline: [Double] = []
    ) {
        self.init(
            title: title,
            value: value.formatted(.number.precision(.fractionLength(0...1))),
            unit: unit,
            subtitle: subtitle,
            severity: severity,
            systemImage: systemImage,
            sparkline: sparkline
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                HStack(spacing: 7) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.caption)
                            .foregroundStyle(severity.dashboardAccentColor)
                    }

                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                SeverityChip(level: severity)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(valueColor)
                    .monospacedDigit()
                    .lineLimit(1)

                if let unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if !sparkline.isEmpty {
                MiniSparkline(values: sparkline, color: severity.dashboardAccentColor)
                    .frame(height: 18)
            }
        }
        .padding(14)
        .frame(minWidth: 150, maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(severity.dashboardAccentColor.opacity(borderOpacity), lineWidth: 1)
        )
    }

    private var valueColor: Color {
        severity == .ok ? .primary : severity.dashboardAccentColor
    }

    private var backgroundColor: Color {
        switch severity {
        case .warning, .critical:
            return Color(red: 0.08, green: 0.10, blue: 0.13).mix(with: severity.dashboardAccentColor, by: 0.08)
        case .ok, .unknown:
            return Color(red: 0.08, green: 0.10, blue: 0.13)
        }
    }

    private var borderOpacity: Double {
        switch severity {
        case .warning, .critical:
            return 0.55
        case .ok:
            return 0.22
        case .unknown:
            return 0.28
        }
    }
}

private struct MiniSparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(normalizedValues.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.72))
                    .frame(width: 5, height: 4 + value * 14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var normalizedValues: [Double] {
        guard let maxValue = values.max(), maxValue > 0 else {
            return values.map { _ in 0.2 }
        }

        return values.map { min(max($0 / maxValue, 0.12), 1) }
    }
}

#Preview {
    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
        GridRow {
            MetricCard(title: "Gateway", value: 1.8, unit: "ms", subtitle: "OK", severity: .ok)
            MetricCard(title: "External RTT", value: 12.0, unit: "ms", subtitle: "OK", severity: .ok)
        }

        GridRow {
            MetricCard(title: "Packet Loss", value: 0.0, unit: "%", subtitle: "OK", severity: .ok)
            MetricCard(title: "Download", value: 16.4, unit: "Mbps", subtitle: "R2 10MB", severity: .warning)
        }
    }
    .padding()
    .background(Color(red: 0.04, green: 0.05, blue: 0.07))
}
