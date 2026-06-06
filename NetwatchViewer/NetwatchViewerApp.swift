//
//  NetwatchViewerApp.swift
//  NetwatchViewer
//
//  Created by 池田洋平 on 2026/06/06.
//

import SwiftUI

@main
struct NetwatchViewerApp: App {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some Scene {
        Window("NetwatchViewer", id: "dashboard") {
            ContentView()
                .environmentObject(viewModel)
        }

        MenuBarExtra {
            MenuBarStatusView()
                .environmentObject(viewModel)
        } label: {
            MenuBarLabelView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
