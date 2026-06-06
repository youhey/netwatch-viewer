//
//  ChartsView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct ChartsView: View {
    @ObservedObject var viewModel: ChartsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                PingLatencyChartView(series: viewModel.pingSeries, thresholds: viewModel.thresholds, catalog: viewModel.catalog)
                PacketLossChartView(series: viewModel.pingSeries, catalog: viewModel.catalog)
                HTTPDurationChartView(series: viewModel.httpSeries, thresholds: viewModel.thresholds, catalog: viewModel.catalog)
                ServiceGroupChartView(series: viewModel.serviceSeries, catalog: viewModel.catalog)
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
            HStack {
                Text("Charts")
                    .font(.title)
                    .bold()

                Spacer()

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
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }

            HStack(spacing: 12) {
                Text("Updated: \(lastUpdatedText)")
                    .foregroundStyle(.secondary)

                if viewModel.isLoading || viewModel.isLoadingSupport {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(viewModel.isLoadingSupport ? "Loading API support..." : "Loading...")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            metadata

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

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Range: \(viewModel.metadata?.range ?? viewModel.range.rawValue) / Bucket: \(viewModel.metadata?.bucket ?? viewModel.bucket.rawValue) / Points: max \(viewModel.metadata?.maxPoints ?? viewModel.maxPoints)")

            if let bucketSeconds = viewModel.metadata?.bucketSeconds {
                Text("Bucket seconds: \(bucketSeconds)")
            }

            if let actualRangeStart = viewModel.metadata?.actualRangeStart, let actualRangeEnd = viewModel.metadata?.actualRangeEnd {
                Text("Actual: \(formatDateTime(actualRangeStart)) - \(formatDateTime(actualRangeEnd))")
            }

            HStack(spacing: 12) {
                if let generatedAt = viewModel.metadata?.generatedAt {
                    Text("Generated: \(formatTime(generatedAt))")
                }

                Text("Timezone: \(viewModel.metadata?.timezone ?? viewModel.catalog?.timezone ?? "-")")
            }

            if let generatedAt = viewModel.capabilities?.generatedAt {
                Text("Capabilities: \(formatTime(generatedAt))")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var lastUpdatedText: String {
        guard let lastUpdated = viewModel.lastUpdated else {
            return "Never"
        }

        return lastUpdated.formatted(date: .omitted, time: .standard)
    }

    private func formatTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .standard)
    }

    private func formatDateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}
