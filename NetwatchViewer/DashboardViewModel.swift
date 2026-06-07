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

    private let client: NetwatchClient
    private let notificationManager: NotificationManager
    private let alertController: AlertController
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

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: overviewChartRefreshInterval)
            } catch {
                return
            }

            await refreshOverviewChart()
        }
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
