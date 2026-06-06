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
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var notificationAuthorizationStatus = "Unknown"
    @Published private(set) var lastNotificationDate: Date?
    @Published private(set) var notificationErrorMessage: String?

    private let client: NetwatchClient
    private let notificationManager: NotificationManager
    private let refreshInterval: Duration
    private var refreshTask: Task<Void, Never>?

    init(
        client: NetwatchClient? = nil,
        notificationManager: NotificationManager? = nil,
        refreshInterval: Duration = .seconds(10),
        requestNotificationsOnInit: Bool = true
    ) {
        self.client = client ?? NetwatchClient()
        self.notificationManager = notificationManager ?? NotificationManager()
        self.refreshInterval = refreshInterval

        if requestNotificationsOnInit {
            Task { [weak self] in
                await self?.requestNotificationAuthorization()
            }
        }
    }

    func startAutoRefresh() {
        if refreshTask != nil {
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.runAutoRefresh()
        }
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

    func refresh() async {
        if isLoading {
            return
        }

        isLoading = true

        var errors: [String] = []
        var didUpdate = false

        do {
            let previousLevel = monitoringStatus?.level
            let status = try await client.fetchMonitoringStatus()
            monitoringStatus = status
            didUpdate = true
            await notifyIfNeeded(previousLevel: previousLevel, status: status)
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

    private func notifyIfNeeded(previousLevel: String?, status: MonitoringStatus) async {
        guard shouldNotify(previousLevel: previousLevel, newLevel: status.level, alert: status.alert) else {
            return
        }

        do {
            try await notificationManager.notify(status: status)
            notificationErrorMessage = nil
        } catch {
            notificationErrorMessage = "Notifications: \(error.localizedDescription)"
        }

        syncNotificationState()
    }

    private func shouldNotify(previousLevel: String?, newLevel: String, alert: Bool) -> Bool {
        guard alert else {
            return false
        }

        let previousLevel = previousLevel?.lowercased()

        switch newLevel.lowercased() {
        case "critical":
            return previousLevel != "critical"
        case "warning":
            return previousLevel != "warning" && previousLevel != "critical"
        default:
            return false
        }
    }

    private func syncNotificationState() {
        notificationAuthorizationStatus = notificationManager.authorizationStatusText
        lastNotificationDate = notificationManager.lastNotificationDate
    }
}
