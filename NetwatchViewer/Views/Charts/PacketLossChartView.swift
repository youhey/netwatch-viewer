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
    let thresholds: MonitoringThresholds?
    let catalog: ChartCatalog?
    @Binding var selectedNames: Set<String>

    private var warningThreshold: Double? {
        thresholds?.ping?.externalLossPercent?.warning
    }

    private var criticalThreshold: Double? {
        thresholds?.ping?.externalLossPercent?.critical
    }

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

                Chart {
                    ForEach(points) { point in
                        LineMark(
                            x: .value("Time", point.ts),
                            y: .value("Loss", point.value)
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
