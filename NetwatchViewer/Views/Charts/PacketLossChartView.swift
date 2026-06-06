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
    @Binding var selectedNames: Set<String>

    private var points: [ChartValuePoint] {
        chartPoints(from: visibleSeries)
    }

    private var allPoints: [ChartValuePoint] {
        chartPoints(from: series)
    }

    var body: some View {
        ChartSection(title: "Packet Loss", emptyMessage: "No packet loss points.", isEmpty: allPoints.isEmpty) {
            VStack(alignment: .leading, spacing: 8) {
                ChartSeriesSelector(items: selectableItems, selectedIDs: $selectedNames)

                Chart(points) { point in
                    LineMark(
                        x: .value("Time", point.ts),
                        y: .value("Loss", point.value)
                    )
                    .foregroundStyle(by: .value("Probe", point.series))
                }
                .chartYAxisLabel("%")
                .chartLegend(.hidden)
                .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
                .frame(height: 260)
            }
        }
    }

    private func chartPoints(from sourceSeries: [PingChartSeries]) -> [ChartValuePoint] {
        let labels = pingLabels

        return sourceSeries.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard (point.sampleCount ?? 0) > 0, let value = point.lossPercent else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.name)-loss-\(point.ts.timeIntervalSince1970)",
                    series: series.displayName ?? labels[series.name] ?? series.name,
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    private var visibleSeries: [PingChartSeries] {
        selectedNames.isEmpty ? series : series.filter { selectedNames.contains($0.name) }
    }

    private var selectableItems: [ChartSelectableItem] {
        let labels = pingLabels
        return series.enumerated().map { index, series in
            ChartSelectableItem(
                id: series.name,
                title: series.displayName ?? labels[series.name] ?? series.name,
                color: ChartSeriesPalette.color(at: index)
            )
        }
    }

    private var colorDomain: [String] {
        selectableItems.map(\.title)
    }

    private var colorRange: [Color] {
        selectableItems.map(\.color)
    }

    private var pingLabels: [String: String] {
        Dictionary(uniqueKeysWithValues: (catalog?.ping ?? []).map { target in
            (target.name, target.displayName ?? target.label ?? target.name)
        })
    }
}
