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

    private let client: NetwatchClient
    private let refreshInterval: Duration

    init(
        client: NetwatchClient? = nil,
        refreshInterval: Duration = .seconds(10)
    ) {
        self.client = client ?? NetwatchClient()
        self.refreshInterval = refreshInterval
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
            let status = try await client.fetchMonitoringStatus()
            monitoringStatus = status
            didUpdate = true
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
}
