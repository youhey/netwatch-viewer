//
//  ContentView.swift
//  NetwatchViewer
//
//  Created by 池田洋平 on 2026/06/06.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                statusSummary

                OverviewView(latest: viewModel.latest)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .frame(minWidth: 760, minHeight: 560, alignment: .topLeading)
        .task {
            viewModel.startAutoRefresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Netwatch")
                    .font(.title)
                    .bold()

                Spacer()

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
                statusRow(label: "Updated", value: lastUpdatedText)

                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    private var statusSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let monitoringStatus = viewModel.monitoringStatus {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Status")
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Circle()
                            .fill(statusColor(for: monitoringStatus.level))
                            .frame(width: 8, height: 8)
                        Text(monitoringStatus.level.uppercased())
                            .fontWeight(.semibold)
                    }
                    statusRow(label: "Level", value: monitoringStatus.level)
                    statusRow(label: "Title", value: monitoringStatus.title)
                    statusRow(label: "Message", value: monitoringStatus.message)
                    statusRow(label: "Alert", value: monitoringStatus.alert ? "true" : "false")
                }
            } else {
                Text("No status loaded.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var lastUpdatedText: String {
        guard let lastUpdated = viewModel.lastUpdated else {
            return "Never"
        }

        return lastUpdated.formatted(date: .omitted, time: .standard)
    }

    private func statusRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
        }
    }

    private func statusColor(for level: String) -> Color {
        switch level.lowercased() {
        case "ok":
            .green
        case "warning":
            .orange
        default:
            .red
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DashboardViewModel())
}
