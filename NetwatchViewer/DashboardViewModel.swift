//
//  DashboardViewModel.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var monitoringStatus: MonitoringStatus?
    @Published private(set) var latest: LatestResponse?
    @Published private(set) var compactNetworkStatus: CompactNetworkStatus?
    @Published private(set) var compactGeneratedAt: Date?
    @Published private(set) var serviceHealth: CompactServiceHealth?
    @Published private(set) var providerStatus: ProviderStatusSummary?
    @Published private(set) var providerStatusError: String?
    @Published private(set) var thresholds: MonitoringThresholds?
    @Published private(set) var overviewChart: ChartsOverviewResponse?
    @Published private(set) var overviewChartLastUpdated: Date?
    @Published private(set) var overviewChartError: String?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var notificationAuthorizationStatus = "Unknown"
    @Published private(set) var lastNotificationDate: Date?
    @Published private(set) var notificationErrorMessage: String?
    @Published private(set) var alertState: AlertState
    @Published private(set) var statusHistory: MonitoringStatusHistoryResponse?
    @Published private(set) var statusHistoryLastUpdated: Date?
    @Published private(set) var statusHistoryError: String?
    @Published private(set) var statusHistorySource: StatusHistorySource
    @Published private(set) var statusHistoryBuckets: [StatusHistoryBucket]
    @Published private(set) var isExporting = false
    @Published private(set) var exportMessage: String?
    @Published private(set) var exportErrorMessage: String?

    private let client: NetwatchClient
    private let notificationManager: NotificationManager
    private let alertController: AlertController
    private var statusHistoryStore: StatusHistoryStore
    private let refreshInterval: Duration
    private let overviewChartRefreshInterval: Duration
    private var refreshTask: Task<Void, Never>?
    private var overviewChartRefreshTask: Task<Void, Never>?

    init(
        client: NetwatchClient? = nil,
        notificationManager: NotificationManager? = nil,
        alertController: AlertController? = nil,
        refreshInterval: Duration = .seconds(10),
        overviewChartRefreshInterval: Duration = .seconds(60),
        requestNotificationsOnInit: Bool = true
    ) {
        self.client = client ?? NetwatchClient()
        self.notificationManager = notificationManager ?? NotificationManager()
        let resolvedAlertController = alertController ?? AlertController()
        self.alertController = resolvedAlertController
        alertState = resolvedAlertController.state
        statusHistoryStore = StatusHistoryStore()
        statusHistoryBuckets = statusHistoryStore.hasPoints ? statusHistoryStore.buckets() : []
        statusHistorySource = statusHistoryStore.hasPoints ? .observed : .unavailable
        self.refreshInterval = refreshInterval
        self.overviewChartRefreshInterval = overviewChartRefreshInterval

        if requestNotificationsOnInit {
            Task { [weak self] in
                await self?.requestNotificationAuthorization()
            }
        }
    }

    func startAutoRefresh() {
        startStatusAutoRefresh()
        startOverviewChartAutoRefresh()
    }

    func runAutoRefresh() async {
        await refresh()

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: refreshInterval)
            } catch {
                return
            }

            await refresh()
        }
    }

    func runOverviewChartAutoRefresh() async {
        await refreshOverviewChart()
        await refreshMonitoringStatusHistory()

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: overviewChartRefreshInterval)
            } catch {
                return
            }

            await refreshOverviewChart()
            await refreshMonitoringStatusHistory()
        }
    }

    func reload() async {
        await refresh()
        await refreshOverviewChart()
        await refreshMonitoringStatusHistory()
    }

    func downloadAIAnalysisExport(range: AIAnalysisExportRange) async -> AIAnalysisExport? {
        guard !isExporting else {
            return nil
        }

        isExporting = true
        exportMessage = nil
        exportErrorMessage = nil

        do {
            return try await client.fetchAIAnalysisExport(range: range)
        } catch {
            isExporting = false
            exportErrorMessage = "Export failed: \(error.localizedDescription)"
            return nil
        }
    }

    func saveAIAnalysisExport(_ export: AIAnalysisExport, to url: URL) {
        do {
            try export.data.write(to: url, options: .atomic)
            exportMessage = "Export completed: \(url.lastPathComponent)"
            exportErrorMessage = nil
        } catch {
            exportMessage = nil
            exportErrorMessage = "Export failed: \(error.localizedDescription)"
        }

        isExporting = false
    }

    func cancelAIAnalysisExportSave() {
        isExporting = false
    }

    func refresh() async {
        if isLoading {
            return
        }

        isLoading = true

        var errors: [String] = []
        var didUpdate = false

        do {
            let status = try await client.fetchMonitoringStatus()
            monitoringStatus = status
            let observedBuckets = statusHistoryStore.record(status: status)
            if statusHistory == nil {
                statusHistoryBuckets = observedBuckets
                statusHistorySource = .observed
            }
            didUpdate = true
            await notifyIfNeeded(status: status)
            alertController.recordObserved(status)
            syncAlertState()
        } catch {
            errors.append("Status: \(error.localizedDescription)")
        }

        do {
            let latestResponse = try await client.fetchLatest()
            latest = latestResponse
            didUpdate = true
        } catch {
            errors.append("Latest: \(error.localizedDescription)")
        }

        await refreshCompactMonitoring()

        do {
            thresholds = try await client.fetchMonitoringThresholds()
        } catch {
            thresholds = nil
        }

        if didUpdate {
            lastUpdated = Date()
        }

        if errors.isEmpty {
            errorMessage = nil
        } else {
            errorMessage = errors.joined(separator: "\n")
        }

        isLoading = false
    }

    func refreshOverviewChart() async {
        do {
            overviewChart = try await client.fetchChartsOverview(range: .twentyFourHours, bucket: .fiveMinutes, maxPoints: 500)
            overviewChartLastUpdated = Date()
            overviewChartError = nil
        } catch {
            overviewChart = nil
            overviewChartError = "Charts overview: \(error.localizedDescription)"
        }
    }

    func refreshMonitoringStatusHistory() async {
        do {
            let response = try await client.fetchMonitoringStatusHistory(range: "24h", bucket: "1h")
            statusHistory = response
            statusHistoryBuckets = response.historyBuckets
            statusHistoryLastUpdated = Date()
            statusHistoryError = nil
            statusHistorySource = .api
        } catch {
            statusHistoryError = "Status history: \(error.localizedDescription)"

            if statusHistory == nil {
                syncObservedStatusHistoryFallback()
            }
        }
    }

    private func refreshCompactMonitoring() async {
        do {
            let compact = try await client.fetchMonitoringCompact()
            compactNetworkStatus = compact.resolvedNetworkStatus
            compactGeneratedAt = compact.generatedAt
            serviceHealth = compact.serviceHealth

            if let providerStatus = compact.providerStatus {
                self.providerStatus = providerStatus
                providerStatusError = nil
                return
            }
        } catch {
            compactNetworkStatus = nil
            compactGeneratedAt = nil
            serviceHealth = nil
            await refreshProviderStatusFallback(compactError: error)
            return
        }

        await refreshProviderStatusFallback(compactError: nil)
    }

    private func refreshProviderStatusFallback(compactError: Error?) async {
        do {
            providerStatus = try await client.fetchStatusPagesLatest().providerStatusSummary
            providerStatusError = nil
        } catch {
            providerStatusError = "Provider status: \((compactError ?? error).localizedDescription)"
        }
    }

    func requestNotificationAuthorization() async {
        do {
            try await notificationManager.requestAuthorization()
            notificationErrorMessage = nil
        } catch {
            notificationErrorMessage = "Notifications: \(error.localizedDescription)"
            await notificationManager.refreshAuthorizationStatus()
        }

        syncNotificationState()
    }

    func acknowledgeCurrentAlert() {
        guard let monitoringStatus else {
            return
        }

        alertController.acknowledge(status: monitoringStatus)
        syncAlertState()
    }

    func muteAlertsForOneHour() {
        alertController.mute()
        syncAlertState()
    }

    func unmuteAlerts() {
        alertController.unmute()
        syncAlertState()
    }

    func isCurrentAlertAcknowledged() -> Bool {
        alertController.isAcknowledged(status: monitoringStatus)
    }

    func isMuted() -> Bool {
        alertController.isMuted()
    }

    private func startStatusAutoRefresh() {
        guard refreshTask == nil else {
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.runAutoRefresh()
        }
    }

    private func startOverviewChartAutoRefresh() {
        guard overviewChartRefreshTask == nil else {
            return
        }

        overviewChartRefreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.runOverviewChartAutoRefresh()
        }
    }

    private func syncObservedStatusHistoryFallback() {
        if statusHistoryStore.hasPoints {
            statusHistoryBuckets = statusHistoryStore.buckets()
            statusHistorySource = .observed
        } else {
            statusHistoryBuckets = []
            statusHistorySource = .unavailable
        }
    }

    private func notifyIfNeeded(status: MonitoringStatus) async {
        let now = Date()

        guard alertController.shouldNotify(status: status, now: now) else {
            return
        }

        do {
            try await notificationManager.notify(status: status)
            alertController.recordNotification(status: status, now: now)
            notificationErrorMessage = nil
        } catch {
            notificationErrorMessage = "Notifications: \(error.localizedDescription)"
        }

        syncNotificationState()
        syncAlertState()
    }

    private func syncNotificationState() {
        notificationAuthorizationStatus = notificationManager.authorizationStatusText
        lastNotificationDate = notificationManager.lastNotificationDate ?? alertController.state.lastNotifiedAt
    }

    private func syncAlertState() {
        alertState = alertController.state
    }
}
