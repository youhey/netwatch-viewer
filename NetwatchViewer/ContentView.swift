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

                statusSummary

                OverviewView(latest: viewModel.latest)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
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
                        Image(statusImageName(for: monitoringStatus.level))
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(monitoringStatus.level.displayText)
                            .fontWeight(.semibold)
                    }
                    statusRow(label: "Level", value: monitoringStatus.level.rawValue)
                    statusRow(label: "Title", value: monitoringStatus.title)
                    statusRow(label: "Message", value: monitoringStatus.message)
                    statusRow(label: "Primary", value: monitoringStatus.primaryReason?.summaryText ?? "-")
                    statusRow(label: "Issues", value: String(monitoringStatus.issueCount))
                    statusRow(label: "Alert", value: monitoringStatus.alert ? "true" : "false")
                    if let generatedAt = monitoringStatus.generatedAt {
                        statusRow(label: "Generated", value: generatedAt.formatted(date: .abbreviated, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let statusId = monitoringStatus.statusId {
                        statusRow(label: "Status ID", value: statusId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                monitoringReasons(monitoringStatus)
            } else {
                Text("No status loaded.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func monitoringReasons(_ status: MonitoringStatus) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reasons")
                .font(.headline)

            if status.reasons.isEmpty {
                Text("No active issues")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedReasons(status.reasons)) { reason in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(reason.level.displayText)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(reasonColor(reason.level))
                            Text(reason.code)
                                .fontWeight(reason == status.primaryReason ? .semibold : .regular)

                            if reason == status.primaryReason {
                                Text("Primary")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(reason.detailText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.top, 4)
    }

    private func sortedReasons(_ reasons: [MonitoringReason]) -> [MonitoringReason] {
        reasons.sorted { lhs, rhs in
            (lhs.level.sortPriority, lhs.code, lhs.target ?? "", lhs.metric ?? "") < (rhs.level.sortPriority, rhs.code, rhs.target ?? "", rhs.metric ?? "")
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

    private func reasonColor(_ level: MonitoringLevel) -> Color {
        switch level {
        case .ok:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        case .unknown:
            return .secondary
        }
    }

    private func statusImageName(for level: MonitoringLevel) -> String {
        switch level {
        case .ok:
            "status-ok"
        case .warning:
            "status-warning"
        case .critical:
            "status-critical"
        case .unknown:
            "status-unknown"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DashboardViewModel(requestNotificationsOnInit: false))
}
