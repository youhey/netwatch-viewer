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
    @State private var isExportProgressPresented = false
    @State private var isExportFileExporterPresented = false
    @State private var exportDocument = AIAnalysisExportDocument()
    @State private var exportDefaultFilename = AIAnalysisExportRange.oneDay.defaultFilename

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
            }

            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 10) {
                    Text("Auto Refresh 10s")
                        .font(.caption)
                        .foregroundStyle(.secondary)

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
        .overlay {
            if isExportProgressPresented {
                ZStack {
                    Color.black.opacity(0.28)
                    ExportProgressView()
                }
            }
        }
        .fileExporter(
            isPresented: $isExportFileExporterPresented,
            document: exportDocument,
            contentType: .zip,
            defaultFilename: exportDefaultFilename
        ) { result in
            Task { @MainActor in
                handleExportResult(result)
            }
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
                    throughputStatus: viewModel.throughputStatus,
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

    @MainActor
    private func exportAIAnalysis(range: AIAnalysisExportRange) async {
        isExportProgressPresented = true

        guard let export = await viewModel.downloadAIAnalysisExport(range: range) else {
            isExportProgressPresented = false
            exportAlert = ExportAlert(
                title: "Export failed",
                message: viewModel.exportErrorMessage ?? "Could not create AI analysis export."
            )
            return
        }

        exportDocument = AIAnalysisExportDocument(data: export.data)
        exportDefaultFilename = export.suggestedFilename
        isExportProgressPresented = false
        isExportFileExporterPresented = true
    }

    @MainActor
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            viewModel.completeAIAnalysisExportSave(filename: url.lastPathComponent)
            exportAlert = ExportAlert(
                title: "Export completed",
                message: viewModel.exportMessage ?? "AI analysis export was saved."
            )

        case .failure(let error):
            if isUserCancelled(error) {
                viewModel.cancelAIAnalysisExportSave()
                return
            }

            viewModel.failAIAnalysisExportSave(error)
            exportAlert = ExportAlert(
                title: "Export failed",
                message: viewModel.exportErrorMessage ?? error.localizedDescription
            )
        }
    }

    private func isUserCancelled(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain && nsError.code == CocoaError.Code.userCancelled.rawValue
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

private struct AIAnalysisExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.zip]
    }

    let data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct ExportProgressView: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(Color(red: 0.27, green: 0.78, blue: 0.96))

            Text("Exporting...")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Downloading AI analysis ZIP export.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .padding(28)
        .frame(width: 320, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.055, green: 0.075, blue: 0.105).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.27, green: 0.78, blue: 0.96).opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 12)
    }
}

#Preview {
    ContentView()
        .environmentObject(DashboardViewModel(requestNotificationsOnInit: false))
}
