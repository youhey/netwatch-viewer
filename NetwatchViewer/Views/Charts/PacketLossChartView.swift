//
//  PacketLossChartView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Charts
import SwiftUI

struct PacketLossChartView: View {
    let series: [PingChartSeries]
    let catalog: ChartCatalog?

    private var points: [ChartValuePoint] {
        let labels = pingLabels

        return series.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard (point.sampleCount ?? 0) > 0, let value = point.lossPercent else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.name)-loss-\(point.ts.timeIntervalSince1970)",
                    series: labels[series.name] ?? series.name,
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    var body: some View {
        ChartSection(title: "Packet Loss", emptyMessage: "No packet loss points.", isEmpty: points.isEmpty) {
            Chart(points) { point in
                LineMark(
                    x: .value("Time", point.ts),
                    y: .value("Loss", point.value)
                )
                .foregroundStyle(by: .value("Probe", point.series))
            }
            .chartYAxisLabel("%")
        }
    }

    private var pingLabels: [String: String] {
        Dictionary(uniqueKeysWithValues: (catalog?.ping ?? []).map { target in
            (target.name, target.label ?? target.name)
        })
    }
}
