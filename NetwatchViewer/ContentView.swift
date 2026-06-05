//
//  ContentView.swift
//  NetwatchViewer
//
//  Created by 池田洋平 on 2026/06/06.
//

import SwiftUI

struct ContentView: View {
    @State private var monitoringStatus: MonitoringStatus?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let client = NetwatchClient()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Netwatch")
                .font(.title)
                .bold()

            if isLoading {
                ProgressView("Loading...")
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else if let monitoringStatus {
                VStack(alignment: .leading, spacing: 8) {
                    statusRow(label: "Status", value: monitoringStatus.status)
                    statusRow(label: "Level", value: monitoringStatus.level)
                    statusRow(label: "Title", value: monitoringStatus.title)
                    statusRow(label: "Message", value: monitoringStatus.message)
                }
            } else {
                Text("No status loaded.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 360, minHeight: 220, alignment: .topLeading)
        .padding()
        .task {
            await loadMonitoringStatus()
        }
    }

    private func statusRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
        }
    }

    private func loadMonitoringStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            monitoringStatus = try await client.fetchMonitoringStatus()
        } catch {
            monitoringStatus = nil
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    ContentView()
}
