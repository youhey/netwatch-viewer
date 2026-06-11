//
//  SpeedprobeChartViews.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/12.
//

import Charts
import SwiftUI

struct SpeedprobeThroughputChartView: View {
    let series: [SpeedprobeChartSeries]
    let catalog: ChartCatalog?
    @Binding var selectedNames: Set<String>

    var body: some View {
        SpeedprobeMetricChartView(
            title: "Speedprobe Throughput",
            emptyMessage: "Speedprobe throughput data is not available yet.",
            yAxisLabel: "Mbps",
            valueLabel: "Throughput",
            series: series,
            catalog: catalog,
            selectedNames: $selectedNames,
            value: \.throughputValue,
            maxValue: \.throughputMaxValue
        )
    }
}

struct SpeedprobeDurationChartView: View {
    let series: [SpeedprobeChartSeries]
    let catalog: ChartCatalog?
    @Binding var selectedNames: Set<String>

    var body: some View {
        SpeedprobeMetricChartView(
            title: "Speedprobe Duration",
            emptyMessage: "Speedprobe duration data is not available yet.",
            yAxisLabel: "ms",
            valueLabel: "Duration",
            series: series,
            catalog: catalog,
            selectedNames: $selectedNames,
            value: \.durationValue,
            maxValue: \.durationMaxValue
        )
    }
}

private struct SpeedprobeMetricChartView: View {
    let title: String
    let emptyMessage: String
    let yAxisLabel: String
    let valueLabel: String
    let series: [SpeedprobeChartSeries]
    let catalog: ChartCatalog?
    @Binding var selectedNames: Set<String>
    let value: KeyPath<SpeedprobeChartPoint, Double?>
    let maxValue: KeyPath<SpeedprobeChartPoint, Double?>

    private var averagePoints: [ChartValuePoint] {
        chartPoints(from: visibleSeries, value: value, suffix: "avg")
    }

    private var allAveragePoints: [ChartValuePoint] {
        chartPoints(from: series, value: value, suffix: "avg")
    }

    private var maxPoints: [ChartValuePoint] {
        chartPoints(from: visibleSeries, value: maxValue, suffix: "max")
    }

    var body: some View {
        ChartSection(title: title, emptyMessage: emptyMessage, isEmpty: allAveragePoints.isEmpty) {
            VStack(alignment: .leading, spacing: 8) {
                ChartSeriesSelector(items: selectableItems, selectedIDs: $selectedNames)

                Chart {
                    ForEach(averagePoints) { point in
                        LineMark(
                            x: .value("Time", point.ts),
                            y: .value(valueLabel, point.value)
                        )
                        .foregroundStyle(by: .value("Speedprobe", point.series))

                        PointMark(
                            x: .value("Time", point.ts),
                            y: .value(valueLabel, point.value)
                        )
                        .foregroundStyle(by: .value("Speedprobe", point.series))
                    }

                    ForEach(maxPoints) { point in
                        LineMark(
                            x: .value("Time", point.ts),
                            y: .value("Max \(valueLabel.lowercased())", point.value)
                        )
                        .foregroundStyle(by: .value("Speedprobe", point.series))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .opacity(0.45)
                    }
                }
                .chartYAxisLabel(yAxisLabel)
                .chartLegend(.hidden)
                .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
                .frame(height: 260)
            }
        }
    }

    private var visibleSeries: [SpeedprobeChartSeries] {
        selectedNames.isEmpty ? series : series.filter { selectedNames.contains($0.name) }
    }

    private var selectableItems: [ChartSelectableItem] {
        let labels = speedprobeLabels
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

    private var speedprobeLabels: [String: String] {
        (catalog?.speedprobe ?? []).reduce(into: [:]) { labels, target in
            labels[target.name] = target.displayName ?? target.label ?? target.name
        }
    }

    private func chartPoints(from sourceSeries: [SpeedprobeChartSeries], value: KeyPath<SpeedprobeChartPoint, Double?>, suffix: String) -> [ChartValuePoint] {
        let labels = speedprobeLabels

        return sourceSeries.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard let pointValue = point[keyPath: value] else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.name)-\(suffix)-\(point.ts.timeIntervalSince1970)",
                    series: series.displayName ?? labels[series.name] ?? series.name,
                    ts: point.ts,
                    value: pointValue
                )
            }
        }
    }
}
