//
//  MenuBarStatusView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import AppKit
import SwiftUI

struct MenuBarStatusView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Netwatch")
                .font(.headline)

            statusContent

            Divider()

            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)

            if canAcknowledgeCurrentAlert {
                Button {
                    viewModel.acknowledgeCurrentAlert()
                } label: {
                    Label(viewModel.isCurrentAlertAcknowledged() ? "Acknowledged" : "Ack", systemImage: "checkmark.circle")
                }
                .disabled(viewModel.isCurrentAlertAcknowledged())
            }

            Button {
                viewModel.muteAlertsForOneHour()
            } label: {
                Label("Mute 1h", systemImage: "speaker.slash")
            }

            if viewModel.isMuted() {
                Button {
                    viewModel.unmuteAlerts()
                } label: {
                    Label("Unmute", systemImage: "speaker.wave.2")
                }
            }

            Button {
                openWindow(id: "dashboard")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("Open Window", systemImage: "macwindow")
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
        }
        .frame(width: 280, alignment: .leading)
        .padding()
        .task {
            viewModel.startAutoRefresh()
        }
    }

    private var statusContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let monitoringStatus = viewModel.monitoringStatus {
                HStack(spacing: 8) {
                    Image(statusImageName(for: monitoringStatus.level))
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text("Status: \(monitoringStatus.level.displayText)")
                        .fontWeight(.semibold)
                }

                Text(monitoringStatus.title)
                    .fontWeight(.medium)

                Text(monitoringStatus.message)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                detailRow(label: "Primary", value: monitoringStatus.primaryReason?.summaryText ?? "-")
                detailRow(label: "Issues", value: String(monitoringStatus.issueCount))
                detailRow(label: "Alert", value: monitoringStatus.alert ? "true" : "false")
                detailRow(label: "Ack", value: viewModel.isCurrentAlertAcknowledged() ? "Acknowledged" : "-")
            } else {
                Text("Status: Unknown")
                    .foregroundStyle(.secondary)
            }

            detailRow(label: "Updated", value: lastUpdatedText)
            detailRow(label: "Notifications", value: viewModel.notificationAuthorizationStatus)
            detailRow(label: "Last notify", value: lastNotificationText)
            detailRow(label: "Muted until", value: mutedUntilText)

            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let notificationErrorMessage = viewModel.notificationErrorMessage {
                Text(notificationErrorMessage)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var canAcknowledgeCurrentAlert: Bool {
        guard let status = viewModel.monitoringStatus else {
            return false
        }

        guard status.alert, status.statusId != nil else {
            return false
        }

        return status.level == .warning || status.level == .critical
    }

    private var lastUpdatedText: String {
        guard let lastUpdated = viewModel.lastUpdated else {
            return "Never"
        }

        return lastUpdated.formatted(date: .omitted, time: .standard)
    }

    private var lastNotificationText: String {
        guard let lastNotificationDate = viewModel.lastNotificationDate ?? viewModel.alertState.lastNotifiedAt else {
            return "Never"
        }

        return lastNotificationDate.formatted(date: .omitted, time: .standard)
    }

    private var mutedUntilText: String {
        guard let mutedUntil = viewModel.alertState.mutedUntil else {
            return "-"
        }

        return mutedUntil.formatted(date: .omitted, time: .shortened)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 92, alignment: .leading)
            Text(value)
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
