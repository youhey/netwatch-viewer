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
    @State private var showsErrorDetails = false

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

            ServicesView(latest: viewModel.latest, thresholds: viewModel.thresholds)
                .tabItem {
                    Label("Services", systemImage: "server.rack")
                }
        }
        .frame(minWidth: 760, minHeight: 560, alignment: .topLeading)
        .task {
            viewModel.startAutoRefresh()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 10) {
                    Text("NETWATCH")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(appAccentColor)

                    apiStatusButton
                }
                .padding(.horizontal, 14)
            }

            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 10) {
                    Text("Auto Refresh 10s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 18)

                    Button {
                        Task {
                            await viewModel.reload()
                        }
                    } label: {
                        ReloadIcon(isLoading: viewModel.isLoading)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 6)
            }
        }
    }

    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                OverviewView(
                    status: viewModel.monitoringStatus,
                    latest: viewModel.latest,
                    thresholds: viewModel.thresholds,
                    overviewChart: viewModel.overviewChart,
                    statusHistory: viewModel.statusHistory,
                    statusHistorySource: viewModel.statusHistorySource,
                    statusHistoryError: viewModel.statusHistoryError,
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

    private var apiStatusButton: some View {
        Image(systemName: viewModel.errorMessage == nil ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(viewModel.errorMessage == nil ? Color.green : Color.red)
            .contentShape(Rectangle())
            .onTapGesture {
                showsErrorDetails = viewModel.errorMessage != nil
            }
        .help(apiStatusHelpText)
        .popover(isPresented: $showsErrorDetails, arrowEdge: .bottom) {
            Text(viewModel.errorMessage ?? "Status and latest API requests are healthy.")
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(width: 280, alignment: .leading)
        }
    }

    private var apiStatusHelpText: String {
        viewModel.errorMessage ?? "Status and latest API requests are healthy."
    }

    private var appAccentColor: Color {
        Color(red: 0.27, green: 0.78, blue: 0.96)
    }
}

private struct ReloadIcon: View {
    let isLoading: Bool

    var body: some View {
        Image(systemName: "arrow.clockwise")
            .rotationEffect(.degrees(isLoading ? 360 : 0))
            .animation(
                isLoading ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default,
                value: isLoading
            )
    }
}

#Preview {
    ContentView()
        .environmentObject(DashboardViewModel(requestNotificationsOnInit: false))
}
