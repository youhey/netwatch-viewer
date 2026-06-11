//
//  ChartsView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct ChartsView: View {
    @ObservedObject var viewModel: ChartsViewModel
    @State private var selectedPingNames: Set<String> = []
    @State private var selectedHTTPNames: Set<String> = []
    @State private var selectedDownloadNames: Set<String> = []
    @State private var selectedSpeedprobeThroughputNames: Set<String> = []
    @State private var selectedSpeedprobeDurationNames: Set<String> = []
    @State private var selectedServiceGroups: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                PingLatencyChartView(series: viewModel.pingSeries, thresholds: viewModel.thresholds, catalog: viewModel.catalog, selectedNames: $selectedPingNames)
                PacketLossChartView(series: viewModel.pingSeries, thresholds: viewModel.thresholds, catalog: viewModel.catalog, selectedNames: $selectedPingNames)
                HTTPDurationChartView(series: viewModel.httpSeries, thresholds: viewModel.thresholds, catalog: viewModel.catalog, selectedNames: $selectedHTTPNames)
                if viewModel.showsDownloadChart {
                    DownloadThroughputChartView(series: viewModel.downloadSeries, thresholds: viewModel.thresholds, catalog: viewModel.catalog, selectedNames: $selectedDownloadNames)
                }
                if !viewModel.speedprobeThroughputSeries.isEmpty {
                    SpeedprobeThroughputChartView(series: viewModel.speedprobeThroughputSeries, catalog: viewModel.catalog, selectedNames: $selectedSpeedprobeThroughputNames)
                }
                if !viewModel.speedprobeDurationSeries.isEmpty {
                    SpeedprobeDurationChartView(series: viewModel.speedprobeDurationSeries, catalog: viewModel.catalog, selectedNames: $selectedSpeedprobeDurationNames)
                }
                ServiceGroupChartView(series: viewModel.serviceSeries, catalog: viewModel.catalog, selectedGroups: $selectedServiceGroups)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .task {
            viewModel.startAutoRefresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Picker("Range", selection: rangeBinding) {
                    ForEach(viewModel.supportedRanges) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 110)

                Picker("Bucket", selection: bucketBinding) {
                    ForEach(viewModel.supportedBuckets) { bucket in
                        Text(bucket.title).tag(bucket)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)

                Button {
                    resetChartSelections()
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)

                if viewModel.isLoading || viewModel.isLoadingSupport {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(viewModel.isLoadingSupport ? "Loading API support..." : "Loading...")
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var rangeBinding: Binding<ChartRange> {
        Binding(
            get: { viewModel.range },
            set: { viewModel.setRange($0) }
        )
    }

    private var bucketBinding: Binding<ChartBucket> {
        Binding(
            get: { viewModel.bucket },
            set: { viewModel.setBucket($0) }
        )
    }

    private func resetChartSelections() {
        selectedPingNames = []
        selectedHTTPNames = []
        selectedDownloadNames = []
        selectedSpeedprobeThroughputNames = []
        selectedSpeedprobeDurationNames = []
        selectedServiceGroups = []
    }
}
