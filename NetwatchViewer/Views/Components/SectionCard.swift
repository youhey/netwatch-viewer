//
//  SectionCard.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.055, green: 0.075, blue: 0.105).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.22, green: 0.42, blue: 0.52).opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    SectionCard(title: "Ping", subtitle: "Latest probe status") {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Gateway")
                Spacer()
                Text("1.8 ms")
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Packet Loss")
                Spacer()
                SeverityChip(level: .ok)
            }
        }
    }
    .padding()
    .background(Color(red: 0.04, green: 0.05, blue: 0.07))
}
