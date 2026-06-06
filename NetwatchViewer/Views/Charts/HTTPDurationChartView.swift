//
//  HTTPDurationChartView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Charts
import SwiftUI

struct HTTPDurationChartView: View {
    let series: [HTTPChartSeries]
    let thresholds: MonitoringThresholds?
    let catalog: ChartCatalog?

    private var warningThreshold: Double? {
        thresholds?.http?.totalMs?.warning
    }

    private var criticalThreshold: Double? {
        thresholds?.http?.totalMs?.critical
    }

    private var totalPoints: [ChartValuePoint] {
        let labels = httpLabels

        return series.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard (point.sampleCount ?? 0) > 0, let value = point.avgTotalMs else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.name)-total-\(point.ts.timeIntervalSince1970)",
                    series: "\(labels[series.name] ?? series.name) total",
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    private var ttfbPoints: [ChartValuePoint] {
        let labels = httpLabels

        return series.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard (point.sampleCount ?? 0) > 0, let value = point.avgTtfbMs else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.name)-ttfb-\(point.ts.timeIntervalSince1970)",
                    series: "\(labels[series.name] ?? series.name) ttfb",
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    private var points: [ChartValuePoint] {
        totalPoints + ttfbPoints
    }

    var body: some View {
        ChartSection(title: "HTTP Duration", emptyMessage: "No HTTP duration points.", isEmpty: points.isEmpty) {
            Chart {
                ForEach(points) { point in
                    LineMark(
                        x: .value("Time", point.ts),
                        y: .value("Duration", point.value)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                }

                if let warningThreshold {
                    RuleMark(y: .value("Warning", warningThreshold))
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                if let criticalThreshold {
                    RuleMark(y: .value("Critical", criticalThreshold))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartYAxisLabel("ms")
        }
    }

    private var httpLabels: [String: String] {
        Dictionary(uniqueKeysWithValues: (catalog?.http ?? []).map { target in
            (target.name, target.label ?? target.name)
        })
    }
}
