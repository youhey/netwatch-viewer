//
//  MenuBarLabelView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct MenuBarLabelView: View {
    @EnvironmentObject private var viewModel: DashboardViewModel

    var body: some View {
        Image(menuBarImageName)
            .resizable()
            .frame(width: 16, height: 16)
            .accessibilityLabel(menuBarAccessibilityLabel)
            .task {
                viewModel.startAutoRefresh()
            }
    }

    private var menuBarImageName: String {
        guard let level = viewModel.monitoringStatus?.level.lowercased() else {
            return "menu-bar-unknown"
        }

        switch level {
        case "ok":
            return "menu-bar-ok"
        case "warning":
            return "menu-bar-warning"
        case "critical":
            return "menu-bar-critical"
        default:
            return "menu-bar-unknown"
        }
    }

    private var menuBarAccessibilityLabel: String {
        guard let level = viewModel.monitoringStatus?.level.uppercased() else {
            return "Netwatch status unknown"
        }

        return "Netwatch status \(level)"
    }
}
