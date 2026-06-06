//
//  DownloadThroughputChartView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Charts
import SwiftUI

struct DownloadThroughputChartView: View {
    let series: [DownloadChartSeries]
    let thresholds: MonitoringThresholds?
    let catalog: ChartCatalog?
    @Binding var selectedNames: Set<String>

    private var averagePoints: [ChartValuePoint] {
        averagePoints(from: visibleSeries)
    }

    private var allAveragePoints: [ChartValuePoint] {
        averagePoints(from: series)
    }

    private var maxPoints: [ChartValuePoint] {
        maxPoints(from: visibleSeries)
    }

    private var thresholdMarks: [DownloadThresholdMark] {
        thresholdMarks(from: visibleSeries)
    }

    private var isEmpty: Bool {
        allAveragePoints.isEmpty
    }

    var body: some View {
        ChartSection(
            title: "Download Throughput (lower is worse)",
            emptyMessage: "Download data is not available yet.",
            isEmpty: isEmpty
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ChartSeriesSelector(items: selectableItems, selectedIDs: $selectedNames)

                Chart {
                    ForEach(averagePoints) { point in
                        LineMark(
                            x: .value("Time", point.ts),
                            y: .value("Throughput", point.value)
                        )
                        .foregroundStyle(by: .value("Download", point.series))

                        PointMark(
                            x: .value("Time", point.ts),
                            y: .value("Throughput", point.value)
                        )
                        .foregroundStyle(by: .value("Download", point.series))
                    }

                    ForEach(maxPoints) { point in
                        LineMark(
                            x: .value("Time", point.ts),
                            y: .value("Max throughput", point.value)
                        )
                        .foregroundStyle(by: .value("Download", point.series))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .opacity(0.45)
                    }

                    ForEach(thresholdMarks) { mark in
                        RuleMark(y: .value(mark.title, mark.value))
                            .foregroundStyle(mark.color)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                .chartYAxisLabel("Mbps")
                .chartLegend(.hidden)
                .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
                .frame(height: 260)
            }
        }
    }

    private func averagePoints(from sourceSeries: [DownloadChartSeries]) -> [ChartValuePoint] {
        let labels = downloadLabels

        return sourceSeries.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard point.sampleCount > 0, let value = point.avgMbps else {
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

    private func maxPoints(from sourceSeries: [DownloadChartSeries]) -> [ChartValuePoint] {
        let labels = downloadLabels

        return sourceSeries.flatMap { series in
            series.points.compactMap { point -> ChartValuePoint? in
                guard
                    point.sampleCount > 0,
                    let value = point.maxMbps,
                    let average = point.avgMbps,
                    abs(value - average) > 0.001
                else {
                    return nil
                }

                return ChartValuePoint(
                    id: "\(series.name)-max-\(point.ts.timeIntervalSince1970)",
                    series: series.displayName ?? labels[series.name] ?? series.name,
                    ts: point.ts,
                    value: value
                )
            }
        }
    }

    private func thresholdMarks(from sourceSeries: [DownloadChartSeries]) -> [DownloadThresholdMark] {
        let labels = downloadLabels

        return sourceSeries.flatMap { series -> [DownloadThresholdMark] in
            guard let band = thresholds?.download?.threshold(for: series.name) else {
                return []
            }

            var marks: [DownloadThresholdMark] = []

            if let warning = band.warning {
                marks.append(
                    DownloadThresholdMark(
                        id: "\(series.name)-warning",
                        title: "\(series.displayName ?? labels[series.name] ?? series.name) warning",
                        value: warning,
                        color: .orange
                    )
                )
            }

            if let critical = band.critical {
                marks.append(
                    DownloadThresholdMark(
                        id: "\(series.name)-critical",
                        title: "\(series.displayName ?? labels[series.name] ?? series.name) critical",
                        value: critical,
                        color: .red
                    )
                )
            }

            return marks
        }
    }

    private var visibleSeries: [DownloadChartSeries] {
        selectedNames.isEmpty ? series : series.filter { selectedNames.contains($0.name) }
    }

    private var selectableItems: [ChartSelectableItem] {
        let labels = downloadLabels
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

    private var downloadLabels: [String: String] {
        Dictionary(uniqueKeysWithValues: (catalog?.download ?? []).map { target in
            (target.name, target.displayName ?? target.label ?? target.name)
        })
    }
}

private struct DownloadThresholdMark: Identifiable {
    let id: String
    let title: String
    let value: Double
    let color: Color
}
