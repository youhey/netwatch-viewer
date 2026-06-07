//
//  ContentView.swift
//  NetwatchViewer
//
//  Created by 池田洋平 on 2026/06/06.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: DashboardViewModel
    @StateObject private var chartsViewModel = ChartsViewModel()

    var body: some View {
        TabView {
            overviewTab
                .tabItem {
                    Label("Overview", systemImage: "list.bullet.rectangle")
                }

            ChartsView(viewModel: chartsViewModel)
                .tabItem {
                    Label("Charts", systemImage: "chart.xyaxis.line")
                }
        }
        .frame(minWidth: 760, minHeight: 560, alignment: .topLeading)
        .task {
            viewModel.startAutoRefresh()
        }
    }

    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                OverviewView(
                    status: viewModel.monitoringStatus,
                    latest: viewModel.latest,
                    thresholds: viewModel.thresholds,
                    lastUpdated: viewModel.lastUpdated,
                    alertState: viewModel.alertState
                )
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .background(Color(red: 0.025, green: 0.035, blue: 0.055))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NETWATCH")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                        .tracking(1.6)

                    Text("Network monitoring dashboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.055, green: 0.075, blue: 0.105).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.22, green: 0.42, blue: 0.52).opacity(0.18), lineWidth: 1)
        )
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
        .environmentObject(DashboardViewModel(requestNotificationsOnInit: false))
}
