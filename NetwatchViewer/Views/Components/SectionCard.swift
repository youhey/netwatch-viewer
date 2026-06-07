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
    let systemImage: String?
    let fillsVertically: Bool
    @ViewBuilder let content: Content

    init(title: String, subtitle: String? = nil, systemImage: String? = nil, fillsVertically: Bool = true, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.fillsVertically = fillsVertically
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: title, subtitle: subtitle, systemImage: systemImage)

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: fillsVertically ? .infinity : nil, alignment: .topLeading)
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

struct SectionHeaderView: View {
    let title: String
    let subtitle: String?
    let systemImage: String?

    init(title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Self.iconColor)
                    .frame(width: 20, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.62))
                }
            }
        }
    }

    private static var iconColor: Color {
        Color(red: 0.28, green: 0.78, blue: 0.96)
    }
}

#Preview {
    SectionCard(title: "Ping", subtitle: "Latest probe status", systemImage: "antenna.radiowaves.left.and.right") {
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
