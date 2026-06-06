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
    @Binding var selectedNames: Set<String>

    private var warningThreshold: Double? {
        thresholds?.http?.totalMs?.warning
    }

    private var criticalThreshold: Double? {
        thresholds?.http?.totalMs?.critical
    }

    private var totalPoints: [ChartValuePoint] {
        totalPoints(from: visibleSeries)
    }

    private var allTotalPoints: [ChartValuePoint] {
        totalPoints(from: series)
    }

    private var ttfbPoints: [ChartValuePoint] {
        ttfbPoints(from: visibleSeries)
    }

    private var allTtfbPoints: [ChartValuePoint] {
        ttfbPoints(from: series)
    }

    private var allPoints: [ChartValuePoint] {
        allTotalPoints + allTtfbPoints
    }

    var body: some View {
        ChartSection(title: "HTTP Duration", emptyMessage: "No HTTP duration points.", isEmpty: allPoints.isEmpty) {
            VStack(alignment: .leading, spacing: 8) {
                ChartSeriesSelector(items: selectableItems, selectedIDs: $selectedNames)

                Chart {
                    ForEach(totalPoints) { point in
                        LineMark(
                            x: .value("Time", point.ts),
                            y: .value("Duration", point.value)
                        )
                        .foregroundStyle(by: .value("Series", point.series))
                    }

                    ForEach(ttfbPoints) { point in
                        LineMark(
                            x: .value("Time", point.ts),
                            y: .value("Duration", point.value)
                        )
                        .foregroundStyle(by: .value("Series", point.series))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .opacity(0.5)
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
                .chartLegend(.hidden)
                .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
                .frame(height: 260)
            }
        }
    }

    private func totalPoints(from sourceSeries: [HTTPChartSeries]) -> [ChartValuePoint] {
        let labels = httpLabels

        return sourceSeries.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard (point.sampleCount ?? 0) > 0, let value = point.avgTotalMs else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.name)-total-\(point.ts.timeIntervalSince1970)",
                    series: series.displayName ?? labels[series.name] ?? series.name,
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    private func ttfbPoints(from sourceSeries: [HTTPChartSeries]) -> [ChartValuePoint] {
        let labels = httpLabels

        return sourceSeries.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard (point.sampleCount ?? 0) > 0, let value = point.avgTtfbMs else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.name)-ttfb-\(point.ts.timeIntervalSince1970)",
                    series: series.displayName ?? labels[series.name] ?? series.name,
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    private var visibleSeries: [HTTPChartSeries] {
        selectedNames.isEmpty ? series : series.filter { selectedNames.contains($0.name) }
    }

    private var selectableItems: [ChartSelectableItem] {
        let labels = httpLabels
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

    private var httpLabels: [String: String] {
        Dictionary(uniqueKeysWithValues: (catalog?.http ?? []).map { target in
            (target.name, target.displayName ?? target.label ?? target.name)
        })
    }
}
