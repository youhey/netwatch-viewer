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
                    overviewChart: viewModel.overviewChart,
                    statusHistoryBuckets: viewModel.statusHistoryBuckets,
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NETWATCH")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(appAccentColor)

                    Text("Network monitoring dashboard")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.58))
                }

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 7) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                    .opacity(viewModel.isLoading ? 1 : 0)
                    .frame(width: 100, alignment: .trailing)

                    Text("Auto Refresh 10s")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.62))

                    Button {
                        Task {
                            await viewModel.refresh()
                        }
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.top, 2)
    }

    private var appAccentColor: Color {
        Color(red: 0.27, green: 0.78, blue: 0.96)
    }
}

#Preview {
    ContentView()
        .environmentObject(DashboardViewModel(requestNotificationsOnInit: false))
}
