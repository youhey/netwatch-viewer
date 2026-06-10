//
//  ContentView.swift
//  NetwatchViewer
//
//  Created by 池田洋平 on 2026/06/06.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var viewModel: DashboardViewModel
    @StateObject private var chartsViewModel = ChartsViewModel()
    @State private var showsErrorDetails = false
    @State private var exportAlert: ExportAlert?

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
                    Menu {
                        ForEach(AIAnalysisExportRange.allCases) { range in
                            Button(range.title) {
                                Task {
                                    await exportAIAnalysis(range: range)
                                }
                            }
                        }
                    } label: {
                        Label(viewModel.isExporting ? "Exporting..." : "Export", systemImage: "square.and.arrow.down")
                    }
                    .disabled(viewModel.isExporting)

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
        .alert(item: $exportAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                OverviewView(
                    status: viewModel.monitoringStatus,
                    latest: viewModel.latest,
                    compactNetworkStatus: viewModel.compactNetworkStatus,
                    compactGeneratedAt: viewModel.compactGeneratedAt,
                    serviceHealth: viewModel.serviceHealth,
                    providerStatus: viewModel.providerStatus,
                    providerStatusError: viewModel.providerStatusError,
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

    private func exportAIAnalysis(range: AIAnalysisExportRange) async {
        guard let export = await viewModel.downloadAIAnalysisExport(range: range) else {
            exportAlert = ExportAlert(
                title: "Export failed",
                message: viewModel.exportErrorMessage ?? "Could not create AI analysis export."
            )
            return
        }

        guard let saveURL = chooseExportSaveURL(suggestedFilename: export.suggestedFilename) else {
            viewModel.cancelAIAnalysisExportSave()
            return
        }

        viewModel.saveAIAnalysisExport(export, to: saveURL)

        if let errorMessage = viewModel.exportErrorMessage {
            exportAlert = ExportAlert(title: "Export failed", message: errorMessage)
        } else {
            exportAlert = ExportAlert(
                title: "Export completed",
                message: viewModel.exportMessage ?? "AI analysis export was saved."
            )
        }
    }

    private func chooseExportSaveURL(suggestedFilename: String) -> URL? {
        let panel = NSSavePanel()
        panel.title = "Save AI Analysis Export"
        panel.message = "Choose where to save the netwatch AI analysis ZIP export."
        panel.nameFieldStringValue = suggestedFilename
        panel.allowedContentTypes = [.zip]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        return panel.runModal() == .OK ? panel.url : nil
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

private struct ExportAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

#Preview {
    ContentView()
        .environmentObject(DashboardViewModel(requestNotificationsOnInit: false))
}
