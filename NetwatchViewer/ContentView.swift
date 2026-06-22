//
//  ContentView.swift
//  NetwatchViewer
//
//  Created by 池田洋平 on 2026/06/06.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ViewerMode: String, CaseIterable, Identifiable {
    case compact
    case overview
    case charts
    case services

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact:
            return "Compact"
        case .overview:
            return "Overview"
        case .charts:
            return "Charts"
        case .services:
            return "Services"
        }
    }

    var windowContentSize: NSSize {
        switch self {
        case .compact:
            return NSSize(width: 800, height: 280)
        case .overview, .charts, .services:
            return NSSize(width: 1420, height: 1200)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: DashboardViewModel
    @AppStorage("netwatch.viewerMode") private var viewerMode: ViewerMode = .overview
    @StateObject private var chartsViewModel = ChartsViewModel()
    @State private var showsErrorDetails = false
    @State private var exportAlert: ExportAlert?
    @State private var isExportProgressPresented = false
    @State private var isExportFileExporterPresented = false
    @State private var exportDocument = AIAnalysisExportDocument()
    @State private var exportDefaultFilename = AIAnalysisExportRange.oneDay.defaultFilename
    @State private var dashboardWindow: NSWindow?

    var body: some View {
        content
            .frame(
                minWidth: viewerMode == .compact ? 320 : 760,
                minHeight: viewerMode == .compact ? 280 : 560,
                alignment: .topLeading
            )
            .background(
                WindowAccessor { window in
                    dashboardWindow = window
                    resizeDashboardWindow(for: viewerMode, animated: false)
                }
            )
            .task {
                viewModel.startAutoRefresh()
            }
            .onChange(of: viewerMode) { _, newMode in
                resizeDashboardWindow(for: newMode, animated: true)
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

                ToolbarItem(placement: .principal) {
                    ViewerModeControl(selection: $viewerMode)
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

    @ViewBuilder
    private var content: some View {
        switch viewerMode {
        case .compact:
            NetwatchCompactView()
                .environmentObject(viewModel)
        case .overview:
            overviewTab
        case .charts:
            ChartsView(viewModel: chartsViewModel)
        case .services:
            ServicesView(latest: viewModel.latest, thresholds: viewModel.thresholds)
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
    private func resizeDashboardWindow(for mode: ViewerMode, animated: Bool) {
        guard let dashboardWindow else {
            return
        }

        let targetSize = mode.windowContentSize
        let currentContentSize = dashboardWindow.contentLayoutRect.size
        guard abs(currentContentSize.width - targetSize.width) > 0.5
            || abs(currentContentSize.height - targetSize.height) > 0.5 else {
            return
        }

        let frameRect = dashboardWindow.frameRect(forContentRect: NSRect(origin: .zero, size: targetSize))
        var frame = dashboardWindow.frame
        frame.origin.y += frame.height - frameRect.height
        frame.size = frameRect.size
        dashboardWindow.setFrame(frame, display: true, animate: animated)
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

private struct ViewerModeControl: View {
    @Binding var selection: ViewerMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ViewerMode.allCases) { mode in
                Button {
                    selection = mode
                } label: {
                    Text(mode.title)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(selection == mode ? .semibold : .medium)
                        .foregroundStyle(selection == mode ? Color.white.opacity(0.96) : Color.white.opacity(0.82))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selection == mode ? Color.white.opacity(0.16) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .frame(width: 360)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onResolve(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onResolve(window)
            }
        }
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
