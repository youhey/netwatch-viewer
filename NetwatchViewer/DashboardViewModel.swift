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

        do {
            monitoringStatus = try await client.fetchMonitoringStatus()
            lastUpdated = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
