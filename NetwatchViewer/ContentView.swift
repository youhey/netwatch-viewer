//
//  ContentView.swift
//  NetwatchViewer
//
//  Created by 池田洋平 on 2026/06/06.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            if let monitoringStatus = viewModel.monitoringStatus {
                VStack(alignment: .leading, spacing: 8) {
                    statusRow(label: "Level", value: monitoringStatus.level)
                    statusRow(label: "Title", value: monitoringStatus.title)
                    statusRow(label: "Message", value: monitoringStatus.message)
                    statusRow(label: "Alert", value: monitoringStatus.alert ? "true" : "false")
                }
            } else {
                Text("No status loaded.")
                    .foregroundStyle(.secondary)
            }

            statusRow(label: "Updated", value: lastUpdatedText)

            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .frame(minWidth: 420, minHeight: 260, alignment: .topLeading)
        .padding()
        .task {
            await viewModel.runAutoRefresh()
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
}

#Preview {
    ContentView()
}
