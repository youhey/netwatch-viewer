//
//  ChartSection.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct ChartSection<Content: View>: View {
    let title: String
    let emptyMessage: String
    let isEmpty: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            if isEmpty {
                Text(emptyMessage)
                    .foregroundStyle(.secondary)
                    .frame(height: 220, alignment: .center)
                    .frame(maxWidth: .infinity)
            } else {
                content
                    .frame(height: 260)
            }
        }
    }
}
