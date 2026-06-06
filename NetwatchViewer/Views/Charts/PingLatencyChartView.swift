//
//  PingLatencyChartView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Charts
import SwiftUI

struct PingLatencyChartView: View {
    let series: [PingChartSeries]
    let thresholds: MonitoringThresholds?
    let catalog: ChartCatalog?

    private var warningThreshold: Double? {
        thresholds?.ping?.externalRttAvgMs?.warning
    }

    private var criticalThreshold: Double? {
        thresholds?.ping?.externalRttAvgMs?.critical
    }

    private var points: [ChartValuePoint] {
        let labels = pingLabels

        return series.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard (point.sampleCount ?? 0) > 0, let value = point.avgMs else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.name)-avg-\(point.ts.timeIntervalSince1970)",
                    series: series.displayName ?? labels[series.name] ?? series.name,
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    var body: some View {
        ChartSection(title: "External RTT", emptyMessage: "No ping latency points.", isEmpty: points.isEmpty) {
            Chart {
                ForEach(points) { point in
                    LineMark(
                        x: .value("Time", point.ts),
                        y: .value("RTT", point.value)
                    )
                    .foregroundStyle(by: .value("Probe", point.series))
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

    private var pingLabels: [String: String] {
        Dictionary(uniqueKeysWithValues: (catalog?.ping ?? []).map { target in
            (target.name, target.displayName ?? target.label ?? target.name)
        })
    }
}
