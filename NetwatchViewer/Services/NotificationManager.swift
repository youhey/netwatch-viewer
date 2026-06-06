//
//  NotificationManager.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus?
    @Published private(set) var lastNotificationDate: Date?

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    var authorizationStatusText: String {
        guard let authorizationStatus else {
            return "Unknown"
        }

        switch authorizationStatus {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }

    func requestAuthorization() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
        await refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func notify(status: MonitoringStatus) async throws {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: status)
        content.body = status.message
        content.sound = .default

        let identifier = "netwatch.\(normalizedLevel(status.level))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await center.add(request)
        lastNotificationDate = Date()
        await refreshAuthorizationStatus()
    }

    private func notificationTitle(for status: MonitoringStatus) -> String {
        switch normalizedLevel(status.level) {
        case "critical":
            return status.title.uppercased().contains("CRITICAL") ? status.title : "NET CRITICAL"
        default:
            return status.title
        }
    }

    private func normalizedLevel(_ level: String) -> String {
        switch level.lowercased() {
        case "warning", "critical":
            return level.lowercased()
        default:
            return "unknown"
        }
    }
}
