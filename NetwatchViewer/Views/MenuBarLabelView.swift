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
        Text(labelText)
            .task {
                viewModel.startAutoRefresh()
            }
    }

    private var labelText: String {
        guard let level = viewModel.monitoringStatus?.level.lowercased() else {
            return "NET ..."
        }

        switch level {
        case "ok":
            return "NET OK"
        case "warning":
            return "NET WARN"
        case "critical":
            return "NET CRIT"
        default:
            return "NET ..."
        }
    }
}
