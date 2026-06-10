//
//  ServicesView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/10.
//

import SwiftUI

struct ServicesView: View {
    let latest: LatestResponse?
    let thresholds: MonitoringThresholds?

    @State private var statusFilter: ServiceStatusFilter = .all
    @State private var selectedGroupName: String?
    @State private var selectedServiceID: String?

    private var evaluator: SeverityEvaluator {
        SeverityEvaluator(thresholds: thresholds)
    }

    private var allItems: [ServiceProbeItem] {
        (latest?.http ?? [])
            .map { ServiceProbeItem(sample: $0, evaluator: evaluator) }
            .sorted(by: ServiceProbeItem.defaultSort)
    }

    private var filteredItems: [ServiceProbeItem] {
        let statusFiltered = allItems.filter(statusFilter.matches)

        guard let selectedGroupName else {
            return sortFilteredItems(statusFiltered)
        }

        return sortFilteredItems(statusFiltered.filter { $0.groupDisplayName == selectedGroupName })
    }

    private var groupSections: [ServiceProbeGroupSection] {
        Dictionary(grouping: filteredItems, by: \.groupDisplayName)
            .map { groupName, items in
                ServiceProbeGroupSection(groupName: groupName, items: sortFilteredItems(items))
            }
            .sorted { lhs, rhs in
                (lhs.groupOrder, lhs.groupName) < (rhs.groupOrder, rhs.groupName)
            }
    }

    private var summary: ServicesSummary {
        ServicesSummary(items: allItems)
    }

    private var groupNames: [String] {
        Array(Set(allItems.map(\.groupDisplayName)))
            .sorted { lhs, rhs in
                (ServiceProbeDisplay.groupSortOrder(lhs), lhs) < (ServiceProbeDisplay.groupSortOrder(rhs), rhs)
            }
    }

    private var selectedItem: ServiceProbeItem? {
        guard let selectedServiceID else {
            return nil
        }

        return allItems.first { $0.id == selectedServiceID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryRow
                filters

                HStack(alignment: .top, spacing: 16) {
                    serviceList
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    ServiceProbeDetailView(item: selectedItem)
                        .frame(width: 360, alignment: .topLeading)
                }
            }
            .padding()
        }
        .background(Color(red: 0.025, green: 0.035, blue: 0.055))
    }

    private var summaryRow: some View {
        LazyVGrid(columns: summaryColumns, alignment: .leading, spacing: 12) {
            ServiceSummaryTile(title: "Total", value: "\(summary.totalCount)", subtitle: "HTTP probes", level: .unknown, systemImage: "list.bullet.rectangle")
            ServiceSummaryTile(title: "OK", value: "\(summary.okCount)", subtitle: "Expected responses", level: .ok)
            ServiceSummaryTile(title: "Issues", value: "\(summary.issueCount)", subtitle: "WARN / CRIT / UNK", level: summary.issueCount == 0 ? .ok : summary.worstIssueLevel)
            ServiceSummaryTile(title: "Slowest", value: summary.slowestValue, subtitle: summary.slowestLabel, level: summary.slowestLevel)
        }
    }

    private var filters: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Self.accentColor)

            Text("Filter")
                .font(.headline)
                .foregroundStyle(.primary)

            ServiceFilterMenu(title: "Status", selection: statusFilter.title) {
                Button(ServiceStatusFilter.all.title) {
                    statusFilter = .all
                }

                Divider()

                ForEach(ServiceStatusFilter.allCases.filter { $0 != .all }) { filter in
                    Button(filter.title) {
                        statusFilter = filter
                    }
                }
            }

            ServiceFilterMenu(title: "Group", selection: selectedGroupName ?? "All") {
                Button("All") {
                    selectedGroupName = nil
                }

                Divider()

                ForEach(groupNames, id: \.self) { groupName in
                    Button(groupName) {
                        selectedGroupName = groupName
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
    }

    private var serviceList: some View {
        SectionCard(title: "HTTP Probes", subtitle: "All service endpoint probes", systemImage: "server.rack") {
            if allItems.isEmpty {
                Text("No HTTP service probes found")
                    .foregroundStyle(Color.white.opacity(0.68))
            } else if filteredItems.isEmpty {
                Text(emptyMessage)
                    .foregroundStyle(Color.white.opacity(0.68))
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(groupSections) { section in
                        ServiceProbeGroupView(
                            section: section,
                            selectedServiceID: selectedServiceID,
                            onSelect: { selectedServiceID = $0.id }
                        )
                    }
                }
            }
        }
    }

    private var emptyMessage: String {
        if statusFilter == .issues {
            return "No service issues"
        }

        if selectedGroupName != nil {
            return "No services in this group"
        }

        return "No services match current filters"
    }

    private var summaryColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 150), spacing: 12), count: 4)
    }

    private static var accentColor: Color {
        Color(red: 0.27, green: 0.78, blue: 0.96)
    }

    private func sortFilteredItems(_ items: [ServiceProbeItem]) -> [ServiceProbeItem] {
        if statusFilter == .issues {
            return items.sorted(by: ServiceProbeItem.issueSort)
        }

        return items.sorted(by: ServiceProbeItem.defaultSort)
    }
}

private enum ServiceStatusFilter: String, CaseIterable, Identifiable {
    case all
    case issues
    case ok
    case warning
    case critical
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .issues:
            return "Issues"
        case .ok:
            return "OK"
        case .warning:
            return "WARN"
        case .critical:
            return "CRIT"
        case .unknown:
            return "UNK"
        }
    }

    func matches(_ item: ServiceProbeItem) -> Bool {
        switch self {
        case .all:
            return true
        case .issues:
            return item.level != .ok
        case .ok:
            return item.level == .ok
        case .warning:
            return item.level == .warning
        case .critical:
            return item.level == .critical
        case .unknown:
            return item.level == .unknown
        }
    }
}

private struct ServiceProbeItem: Identifiable {
    let id: String
    let name: String
    let label: String
    let url: String?
    let group: String?
    let groupDisplayName: String
    let category: String?
    let level: MonitoringLevel
    let ok: Bool
    let httpStatusCode: Int?
    let expectedStatuses: [Int]
    let expectedText: String
    let durationMs: Double?
    let ttfbMs: Double?
    let error: String?
    let measuredAt: Date?
    let displayOrder: Int

    init(sample: HTTPSample, evaluator: SeverityEvaluator) {
        let expectedStatuses = ServiceProbeDisplay.expectedStatuses(for: sample)
        let expectedStatusMatches = sample.httpStatus.map { expectedStatuses.contains($0) } ?? false
        let computedLevel = evaluator.severityForHTTP(sample)

        id = sample.name
        name = sample.name
        label = ServiceProbeDisplay.label(for: sample)
        url = sample.url
        group = sample.group
        groupDisplayName = ServiceProbeDisplay.groupName(group: sample.group, category: sample.category)
        category = sample.category
        level = expectedStatusMatches && !sample.ok ? .ok : computedLevel
        ok = sample.ok || expectedStatusMatches
        httpStatusCode = sample.httpStatus
        self.expectedStatuses = expectedStatuses
        expectedText = ServiceProbeDisplay.expectedText(for: sample)
        durationMs = sample.totalMs
        ttfbMs = sample.ttfbMs
        error = sample.errorMessage ?? sample.error
        measuredAt = ChartDateParser.parse(sample.ts)
        displayOrder = sample.displayOrder ?? Int.max
    }

    var httpText: String {
        if let httpStatusCode {
            return String(httpStatusCode)
        }

        if let error, !error.isEmpty {
            return error
        }

        return "-"
    }

    var expectedDetailText: String {
        guard !expectedStatuses.isEmpty else {
            return "Default 2xx / 3xx status is considered expected."
        }

        if let httpStatusCode, expectedStatuses.contains(httpStatusCode) {
            return "HTTP \(httpStatusCode) is expected for this endpoint probe."
        }

        return "\(expectedText) is configured for this endpoint probe."
    }

    nonisolated static func defaultSort(_ lhs: ServiceProbeItem, _ rhs: ServiceProbeItem) -> Bool {
        (
            ServiceProbeDisplay.groupSortOrder(lhs.groupDisplayName),
            lhs.displayOrder,
            lhs.label
        ) < (
            ServiceProbeDisplay.groupSortOrder(rhs.groupDisplayName),
            rhs.displayOrder,
            rhs.label
        )
    }

    nonisolated static func issueSort(_ lhs: ServiceProbeItem, _ rhs: ServiceProbeItem) -> Bool {
        (
            lhs.level.sortPriority,
            -(lhs.durationMs ?? -1),
            lhs.label
        ) < (
            rhs.level.sortPriority,
            -(rhs.durationMs ?? -1),
            rhs.label
        )
    }
}

private struct ServicesSummary {
    let totalCount: Int
    let okCount: Int
    let issueCount: Int
    let worstIssueLevel: MonitoringLevel
    let slowestLabel: String
    let slowestValue: String
    let slowestLevel: MonitoringLevel

    init(items: [ServiceProbeItem]) {
        totalCount = items.count
        okCount = items.filter { $0.level == .ok }.count
        issueCount = items.filter { $0.level != .ok }.count
        worstIssueLevel = items
            .filter { $0.level != .ok }
            .map(\.level)
            .min { lhs, rhs in lhs.sortPriority < rhs.sortPriority } ?? .ok

        if let slowest = items.compactMap({ item -> ServiceProbeItem? in
            item.durationMs == nil ? nil : item
        }).max(by: { ($0.durationMs ?? 0) < ($1.durationMs ?? 0) }) {
            slowestLabel = slowest.label
            slowestValue = formatMilliseconds(slowest.durationMs)
            slowestLevel = slowest.level
        } else {
            slowestLabel = "No duration data"
            slowestValue = "-"
            slowestLevel = .unknown
        }
    }
}

private struct ServiceProbeGroupSection: Identifiable {
    var id: String { groupName }

    let groupName: String
    let items: [ServiceProbeItem]

    var groupOrder: Int {
        ServiceProbeDisplay.groupSortOrder(groupName)
    }

    var okCount: Int {
        items.filter { $0.level == .ok }.count
    }

    var totalCount: Int {
        items.count
    }

    var worstLevel: MonitoringLevel {
        items.map(\.level).min { lhs, rhs in
            lhs.sortPriority < rhs.sortPriority
        } ?? .unknown
    }
}

private struct ServiceProbeGroupView: View {
    let section: ServiceProbeGroupSection
    let selectedServiceID: String?
    let onSelect: (ServiceProbeItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                Text(section.groupName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(section.okCount)/\(section.totalCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .monospacedDigit()

                SeverityChip(level: section.worstLevel)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                ServiceProbeTableHeader()

                Divider()

                ForEach(section.items) { item in
                    ServiceProbeRow(
                        item: item,
                        isSelected: selectedServiceID == item.id,
                        onSelect: { onSelect(item) }
                    )
                }
            }
            .font(.system(.caption, design: .monospaced))
        }
    }
}

private struct ServiceProbeTableHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            tableHeader("Status", width: 86)
            tableHeader("Service")
            tableHeader("Group", width: 110)
            tableHeader("Category", width: 96)
            tableHeader("HTTP", width: 86)
            tableHeader("Duration", width: 104)
            tableHeader("Expected", width: 142)
            tableHeader("Last checked", width: 96)
        }
        .padding(.horizontal, 8)
    }

    private func tableHeader(_ title: String, width: CGFloat? = nil) -> some View {
        Text(title)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.white.opacity(0.74))
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

private struct ServiceProbeRow: View {
    let item: ServiceProbeItem
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                statusCell
                    .frame(width: 86, alignment: .leading)

                Text(item.label)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.groupDisplayName)
                    .foregroundStyle(tableSecondary)
                    .lineLimit(1)
                    .frame(width: 110, alignment: .leading)

                Text(item.category ?? "-")
                    .foregroundStyle(tableSecondary)
                    .lineLimit(1)
                    .frame(width: 96, alignment: .leading)

                Text(item.httpText)
                    .foregroundStyle(httpColor)
                    .lineLimit(1)
                    .frame(width: 86, alignment: .leading)

                Text(formatMilliseconds(item.durationMs))
                    .foregroundStyle(valueColor)
                    .monospacedDigit()
                    .frame(width: 104, alignment: .leading)

                Text(item.expectedText)
                    .foregroundStyle(expectedColor)
                    .lineLimit(1)
                    .frame(width: 142, alignment: .leading)

                Text(formatRelativeTime(item.measuredAt))
                    .foregroundStyle(tableSecondary)
                    .monospacedDigit()
                    .frame(width: 96, alignment: .leading)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var statusCell: some View {
        HStack(spacing: 5) {
            Image(systemName: item.level.serviceSymbolName)
                .font(.system(size: 11, weight: .semibold))
            Text(item.level.serviceCompactLabel)
                .fontWeight(.semibold)
        }
        .foregroundStyle(item.level.dashboardAccentColor)
    }

    private var valueColor: Color {
        item.level == .ok ? .primary : item.level.dashboardAccentColor
    }

    private var httpColor: Color {
        item.ok ? tableSecondary : item.level.dashboardAccentColor
    }

    private var expectedColor: Color {
        item.expectedStatuses.isEmpty ? tableSecondary : Color(red: 0.27, green: 0.78, blue: 0.96)
    }

    private var tableSecondary: Color {
        Color.white.opacity(0.68)
    }
}

private struct ServiceProbeDetailView: View {
    let item: ServiceProbeItem?

    var body: some View {
        SectionCard(title: "Service Detail", subtitle: "Selected HTTP probe", systemImage: "info.circle") {
            if let item {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        SeverityChip(level: item.level)
                        Text(item.label)
                            .font(.headline)
                            .lineLimit(2)
                    }

                    Text(item.expectedDetailText)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 9) {
                        detailRow("Name", item.name)
                        detailRow("URL", item.url ?? "-")
                        detailRow("Group", item.groupDisplayName)
                        detailRow("Raw group", item.group ?? "-")
                        detailRow("Category", item.category ?? "-")
                        detailRow("Status", item.level.dashboardLabel)
                        detailRow("HTTP", item.httpText)
                        detailRow("Expected", item.expectedText)
                        detailRow("Duration", formatMilliseconds(item.durationMs))
                        detailRow("TTFB", formatMilliseconds(item.ttfbMs))
                        detailRow("Error", item.error ?? "-")
                        detailRow("Measured", formatMeasuredAt(item.measuredAt))
                    }
                    .font(.caption)
                }
            } else {
                Text("Select a service to inspect details.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.68))
            }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.62))
            Text(value)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ServiceSummaryTile: View {
    let title: String
    let value: String
    let subtitle: String
    let level: MonitoringLevel
    let systemImage: String?

    init(title: String, value: String, subtitle: String, level: MonitoringLevel, systemImage: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.level = level
        self.systemImage = systemImage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: systemImage ?? level.serviceSymbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white.opacity(0.72))

                Spacer()
            }

            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(level == .ok || level == .unknown ? .primary : level.dashboardAccentColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.58))
                .lineLimit(1)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.055, green: 0.075, blue: 0.105).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(level.dashboardAccentColor.opacity(0.20), lineWidth: 1)
        )
    }

    private var iconColor: Color {
        systemImage == nil ? level.dashboardAccentColor : Color(red: 0.27, green: 0.78, blue: 0.96)
    }
}

private struct ServiceFilterMenu<Content: View>: View {
    let title: String
    let selection: String
    @ViewBuilder let content: Content

    var body: some View {
        Menu {
            content
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .foregroundStyle(Color.white.opacity(0.62))

                Text(selection)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.54))
            }
                .font(.caption)
                .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.055))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private func formatRelativeTime(_ date: Date?) -> String {
    guard let date else {
        return "-"
    }

    let seconds = max(Int(Date().timeIntervalSince(date)), 0)

    if seconds < 60 {
        return "\(seconds)s ago"
    }

    let minutes = seconds / 60

    if minutes < 60 {
        return "\(minutes)m ago"
    }

    let hours = minutes / 60

    if hours < 24 {
        return "\(hours)h ago"
    }

    return "\(hours / 24)d ago"
}

private func formatMeasuredAt(_ date: Date?) -> String {
    guard let date else {
        return "-"
    }

    return date.formatted(date: .abbreviated, time: .standard)
}

private extension MonitoringLevel {
    var serviceCompactLabel: String {
        switch self {
        case .ok:
            return "OK"
        case .warning:
            return "WARN"
        case .critical:
            return "CRIT"
        case .unknown:
            return "UNK"
        }
    }

    var serviceSymbolName: String {
        switch self {
        case .ok:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

#Preview {
    ServicesView(latest: LatestResponse(), thresholds: nil)
        .frame(width: 1400, height: 900)
}
