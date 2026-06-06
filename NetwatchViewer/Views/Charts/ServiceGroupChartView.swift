//
//  ServiceGroupChartView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Charts
import SwiftUI

struct ServiceGroupChartView: View {
    let series: [ServiceChartSeries]
    let catalog: ChartCatalog?

    private var points: [ChartValuePoint] {
        let labels = serviceGroupLabels

        return series.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard (point.sampleCount ?? 0) > 0, let value = point.avgTotalMs else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.group)-total-\(point.ts.timeIntervalSince1970)",
                    series: labels[series.group] ?? series.group,
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    var body: some View {
        ChartSection(title: "Service Groups", emptyMessage: "No service group points.", isEmpty: points.isEmpty) {
            Chart(points) { point in
                LineMark(
                    x: .value("Time", point.ts),
                    y: .value("Duration", point.value)
                )
                .foregroundStyle(by: .value("Group", point.series))
            }
            .chartYAxisLabel("ms")
        }
    }

    private var serviceGroupLabels: [String: String] {
        Dictionary(uniqueKeysWithValues: (catalog?.serviceGroups ?? []).map { group in
            (group.group, group.label ?? group.group)
        })
    }
}
