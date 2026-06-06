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
    @Binding var selectedGroups: Set<String>

    private var points: [ChartValuePoint] {
        chartPoints(from: visibleSeries)
    }

    private var allPoints: [ChartValuePoint] {
        chartPoints(from: series)
    }

    var body: some View {
        ChartSection(title: "Service Groups", emptyMessage: "No service group points.", isEmpty: allPoints.isEmpty) {
            VStack(alignment: .leading, spacing: 8) {
                ChartSeriesSelector(items: selectableItems, selectedIDs: $selectedGroups)

                Chart(points) { point in
                    LineMark(
                        x: .value("Time", point.ts),
                        y: .value("Duration", point.value)
                    )
                    .foregroundStyle(by: .value("Group", point.series))
                }
                .chartYAxisLabel("ms")
                .chartLegend(.hidden)
                .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
                .frame(height: 260)
            }
        }
    }

    private func chartPoints(from sourceSeries: [ServiceChartSeries]) -> [ChartValuePoint] {
        let labels = serviceGroupLabels

        return sourceSeries.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard (point.sampleCount ?? 0) > 0, let value = point.avgTotalMs else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.group)-total-\(point.ts.timeIntervalSince1970)",
                    series: series.displayName ?? labels[series.group] ?? series.group,
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    private var visibleSeries: [ServiceChartSeries] {
        selectedGroups.isEmpty ? series : series.filter { selectedGroups.contains($0.group) }
    }

    private var selectableItems: [ChartSelectableItem] {
        let labels = serviceGroupLabels
        return series.enumerated().map { index, series in
            ChartSelectableItem(
                id: series.group,
                title: series.displayName ?? labels[series.group] ?? series.group,
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

    private var serviceGroupLabels: [String: String] {
        Dictionary(uniqueKeysWithValues: (catalog?.serviceGroups ?? []).map { group in
            (group.group, group.displayName ?? group.label ?? group.group)
        })
    }
}
