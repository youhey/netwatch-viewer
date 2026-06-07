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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Self.metricAccent)
                        .frame(width: 28, height: 28)
                }

                Text(title)
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)
            }

            HStack(alignment: .center, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(value)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(valueColor)
                        .monospacedDigit()
                        .lineLimit(1)

                    if let unit {
                        Text(unit)
                            .font(.callout)
                            .foregroundStyle(Color.white.opacity(0.68))
                    }
                }

                Spacer(minLength: 8)

                SeverityChip(level: severity)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.68))
                    .lineLimit(2)
            }

            if !sparkline.isEmpty {
                MiniSparkline(values: sparkline, color: Self.metricAccent)
                    .frame(height: 26)
            }
        }
        .padding(16)
        .frame(minWidth: 175, maxWidth: .infinity, minHeight: 150, alignment: .leading)
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

    private static var metricAccent: Color {
        Color(red: 0.27, green: 0.78, blue: 0.96)
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
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                Path { path in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let step = normalizedValues.count > 1 ? width / CGFloat(normalizedValues.count - 1) : width

                    for index in normalizedValues.indices {
                        let x = CGFloat(index) * step
                        let y = height - CGFloat(normalizedValues[index]) * height

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color.opacity(0.86), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                Rectangle()
                    .fill(color.opacity(0.18))
                    .frame(height: 1)
                    .offset(y: -2)
            }
        }
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
            MetricCard(title: "Packet Loss", value: 0.0, unit: "%", severity: .unknown, sparkline: Array(repeating: 0, count: 8))
            MetricCard(title: "Download", value: 16.4, unit: "Mbps", severity: .critical, sparkline: [10, 8, 6, 5, 4, 3, 3, 2])
        }
    }
    .padding()
    .background(Color(red: 0.04, green: 0.05, blue: 0.07))
}
