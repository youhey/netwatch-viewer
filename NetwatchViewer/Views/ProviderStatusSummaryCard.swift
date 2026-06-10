//
//  ProviderStatusSummaryCard.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/10.
//

import SwiftUI

struct ProviderStatusSummaryCard: View {
    let summary: ProviderStatusSummary?
    let errorMessage: String?

    var body: some View {
        SectionCard(title: "Provider Status", subtitle: "Official status pages", systemImage: "checkmark.shield") {
            VStack(alignment: .leading, spacing: 14) {
                if let summary {
                    if summary.providers.isEmpty {
                        providerStatusEmptyState
                    } else {
                        summaryHeader(summary)
                        Divider()
                        providerRows(summary.providers)
                        providerIssues(summary.issueProviders)
                    }
                } else {
                    providerStatusUnavailable
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(Color.red.opacity(0.82))
                        .lineLimit(2)
                }
            }
        }
    }

    private var providerStatusUnavailable: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Provider status unavailable.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.72))

            Text("No provider status data has been loaded.")
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.56))
        }
    }

    private var providerStatusEmptyState: some View {
        HStack(spacing: 8) {
            SeverityChip(level: .ok)

            Text("Provider status is not configured.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.72))
        }
    }

    private func summaryHeader(_ summary: ProviderStatusSummary) -> some View {
        HStack(spacing: 10) {
            SeverityChip(level: summary.level)

            Text("\(summary.issueCount) issue\(summary.issueCount == 1 ? "" : "s") / \(summary.providers.count) provider\(summary.providers.count == 1 ? "" : "s")")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.78))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func providerRows(_ providers: [ProviderStatusItem]) -> some View {
        LazyVGrid(columns: providerColumns, alignment: .leading, spacing: 8) {
            ForEach(providers) { provider in
                ProviderStatusRow(provider: provider)
            }
        }
    }

    private var providerColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 180), spacing: 10)]
    }

    @ViewBuilder
    private func providerIssues(_ providers: [ProviderStatusItem]) -> some View {
        Divider()

        VStack(alignment: .leading, spacing: 8) {
            Text("Issues")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.72))

            if providers.isEmpty {
                Text("All provider status pages are operational.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.68))
            } else {
                ForEach(providers) { provider in
                    ProviderStatusIssueRow(provider: provider)
                }
            }
        }
    }
}

private struct ProviderStatusRow: View {
    let provider: ProviderStatusItem

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            SeverityChip(level: provider.level)

            VStack(alignment: .leading, spacing: 3) {
                Text(provider.displayLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(providerDescription)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 1)
    }

    private var providerDescription: String {
        if let error = provider.error, !error.isEmpty {
            return error
        }

        if let description = provider.description, !description.isEmpty {
            return description
        }

        return provider.level == .ok ? "Operational" : "No description"
    }
}

private struct ProviderStatusIssueRow: View {
    let provider: ProviderStatusItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: provider.level.providerSymbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(provider.level.dashboardAccentColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(provider.displayLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("Provider")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.58))
                }

                Text(issueDescription)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.66))
                    .lineLimit(2)
            }
        }
    }

    private var issueDescription: String {
        if let error = provider.error, !error.isEmpty {
            return error
        }

        if let description = provider.description, !description.isEmpty {
            return description
        }

        return "Provider status page reports \(provider.level.dashboardLabel.lowercased())."
    }
}

private extension MonitoringLevel {
    var providerSymbolName: String {
        switch self {
        case .ok:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .critical:
            "xmark.octagon.fill"
        case .unknown:
            "questionmark.circle.fill"
        }
    }
}

#Preview {
    ProviderStatusSummaryCard(summary: nil, errorMessage: nil)
        .padding()
        .background(Color(red: 0.025, green: 0.035, blue: 0.055))
}
