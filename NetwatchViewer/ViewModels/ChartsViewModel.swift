//
//  ChartsViewModel.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Combine
import Foundation

@MainActor
final class ChartsViewModel: ObservableObject {
    @Published private(set) var range: ChartRange
    @Published private(set) var bucket: ChartBucket
    @Published private(set) var maxPoints: Int
    @Published private(set) var capabilities: APICapabilities?
    @Published private(set) var catalog: ChartCatalog?
    @Published private(set) var thresholds: MonitoringThresholds?
    @Published private(set) var metadata: ChartsMetadata?
    @Published private(set) var pingSeries: [PingChartSeries] = []
    @Published private(set) var httpSeries: [HTTPChartSeries] = []
    @Published private(set) var downloadSeries: [DownloadChartSeries] = []
    @Published private(set) var serviceSeries: [ServiceChartSeries] = []
    @Published private(set) var isLoadingSupport = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    private let client: NetwatchClient
    private let refreshInterval: Duration
    private var refreshTask: Task<Void, Never>?
    private var didApplyCatalogDefaults = false

    private let legacyFallbackPingNames = ["cloudflare_dns", "google_dns"]
    private let legacyFallbackHTTPNames = ["youtube_home", "steam_store", "slack_status"]
    private let legacyFallbackServiceGroups = ["pcgame"]

    init(
        client: NetwatchClient? = nil,
        range: ChartRange = .twentyFourHours,
        bucket: ChartBucket = .fiveMinutes,
        maxPoints: Int = 500,
        refreshInterval: Duration = .seconds(60)
    ) {
        self.client = client ?? NetwatchClient()
        self.range = range
        self.bucket = bucket
        self.maxPoints = maxPoints
        self.refreshInterval = refreshInterval
    }

    var supportedRanges: [ChartRange] {
        let values = catalog?.supported?.ranges ?? capabilities?.chart?.ranges
        return chartRanges(from: values, fallback: ChartRange.allCases)
    }

    var supportedBuckets: [ChartBucket] {
        let values = catalog?.supported?.buckets ?? capabilities?.chart?.buckets
        return chartBuckets(from: values, fallback: ChartBucket.allCases)
    }

    var showsDownloadChart: Bool {
        if capabilities?.features.chartsDownload == false {
            return false
        }

        return !downloadSeries.isEmpty || !(catalog?.download.isEmpty ?? true)
    }

    func startAutoRefresh() {
        if refreshTask != nil {
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.runAutoRefresh()
        }
    }

    func setRange(_ newRange: ChartRange) {
        guard range != newRange else {
            return
        }

        range = newRange
        bucket = supportedBuckets.contains(newRange.recommendedBucket) ? newRange.recommendedBucket : supportedBuckets.first ?? bucket

        Task {
            await refresh()
        }
    }

    func setBucket(_ newBucket: ChartBucket) {
        guard bucket != newBucket else {
            return
        }

        bucket = newBucket

        Task {
            await refresh()
        }
    }

    func refresh() async {
        if isLoading {
            return
        }

        isLoading = true

        var errors = await loadSupportAPIsIfNeeded()

        let clampedMaxPoints = clampedMaxPoints(maxPoints)
        maxPoints = clampedMaxPoints

        do {
            if shouldUseOverviewAPI {
                let overview = try await client.fetchChartsOverview(range: range, bucket: bucket, maxPoints: clampedMaxPoints)
                apply(overview: overview)
                errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")
                isLoading = false
                return
            }
        } catch {
            errors.append("Charts overview: \(error.localizedDescription)")
        }

        let fallbackErrors = await refreshIndividualSeries(maxPoints: clampedMaxPoints)
        errors.append(contentsOf: fallbackErrors)

        errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")
        isLoading = false
    }

    private func loadSupportAPIsIfNeeded() async -> [String] {
        if capabilities != nil || catalog != nil || thresholds != nil {
            return []
        }

        isLoadingSupport = true
        defer {
            isLoadingSupport = false
        }

        var errors: [String] = []

        do {
            capabilities = try await client.fetchCapabilities()
        } catch {
            errors.append("Capabilities: \(error.localizedDescription)")
        }

        do {
            let catalog = try await client.fetchChartCatalog()
            self.catalog = catalog
            applyCatalogDefaultsIfNeeded(catalog)
        } catch {
            errors.append("Chart catalog: \(error.localizedDescription)")
        }

        if capabilities?.features.monitoringThresholds ?? true {
            do {
                thresholds = try await client.fetchMonitoringThresholds()
            } catch {
                errors.append("Thresholds: \(error.localizedDescription)")
            }
        }

        return errors
    }

    private func applyCatalogDefaultsIfNeeded(_ catalog: ChartCatalog) {
        guard !didApplyCatalogDefaults else {
            return
        }

        if let defaultRange = catalog.defaults?.range {
            let nextRange = ChartRange(rawValue: defaultRange)
            if supportedRanges.contains(nextRange) {
                range = nextRange
            }
        }

        if let defaultBucket = catalog.defaults?.bucket {
            let nextBucket = ChartBucket(rawValue: defaultBucket)
            if supportedBuckets.contains(nextBucket) {
                bucket = nextBucket
            }
        }

        if let defaultMaxPoints = catalog.defaults?.maxPoints ?? catalog.supported?.maxPoints?.defaultValue ?? capabilities?.chart?.maxPoints?.defaultValue {
            maxPoints = clampedMaxPoints(defaultMaxPoints)
        }

        didApplyCatalogDefaults = true
    }

    private var shouldUseOverviewAPI: Bool {
        capabilities?.features.chartsOverview ?? true
    }

    private func apply(overview: ChartsOverviewResponse) {
        pingSeries = overview.ping
        httpSeries = overview.http
        downloadSeries = overview.download
        serviceSeries = overview.serviceGroups
        metadata = ChartsMetadata(overview: overview)
        lastUpdated = Date()
    }

    private func refreshIndividualSeries(maxPoints: Int) async -> [String] {
        var nextPingSeries: [PingChartSeries] = []
        var nextHTTPSeries: [HTTPChartSeries] = []
        var nextDownloadSeries: [DownloadChartSeries] = []
        var nextServiceSeries: [ServiceChartSeries] = []
        var errors: [String] = []

        for name in pingNamesForFallback {
            do {
                let series = try await client.fetchPingSeries(name: name, range: range, bucket: bucket, maxPoints: maxPoints)
                nextPingSeries.append(series)
            } catch {
                errors.append("Ping \(name): \(error.localizedDescription)")
            }
        }

        for name in httpNamesForFallback {
            do {
                let series = try await client.fetchHTTPSeries(name: name, range: range, bucket: bucket, maxPoints: maxPoints)
                nextHTTPSeries.append(series)
            } catch {
                errors.append("HTTP \(name): \(error.localizedDescription)")
            }
        }

        for group in serviceGroupsForFallback {
            do {
                let series = try await client.fetchServiceSeries(group: group, range: range, bucket: bucket, maxPoints: maxPoints)
                nextServiceSeries.append(series)
            } catch {
                errors.append("Service \(group): \(error.localizedDescription)")
            }
        }

        if capabilities?.features.chartsDownload ?? true {
            for name in downloadNamesForFallback {
                do {
                    let series = try await client.fetchDownloadSeries(name: name, range: range, bucket: bucket, maxPoints: maxPoints)
                    nextDownloadSeries.append(series)
                } catch {
                    errors.append("Download \(name): \(error.localizedDescription)")
                }
            }
        }

        if !nextPingSeries.isEmpty || !nextHTTPSeries.isEmpty || !nextDownloadSeries.isEmpty || !nextServiceSeries.isEmpty {
            pingSeries = nextPingSeries
            httpSeries = nextHTTPSeries
            downloadSeries = nextDownloadSeries
            serviceSeries = nextServiceSeries
            metadata = ChartsMetadata(
                generatedAt: [nextPingSeries.first?.generatedAt, nextHTTPSeries.first?.generatedAt, nextDownloadSeries.first?.generatedAt, nextServiceSeries.first?.generatedAt].compactMap { $0 }.first,
                actualRangeStart: [nextPingSeries.first?.actualRangeStart, nextHTTPSeries.first?.actualRangeStart, nextDownloadSeries.first?.actualRangeStart, nextServiceSeries.first?.actualRangeStart].compactMap { $0 }.first,
                actualRangeEnd: [nextPingSeries.first?.actualRangeEnd, nextHTTPSeries.first?.actualRangeEnd, nextDownloadSeries.first?.actualRangeEnd, nextServiceSeries.first?.actualRangeEnd].compactMap { $0 }.first,
                timezone: nextPingSeries.first?.timezone ?? nextHTTPSeries.first?.timezone ?? nextDownloadSeries.first?.timezone ?? nextServiceSeries.first?.timezone ?? catalog?.timezone,
                range: nextPingSeries.first?.range ?? nextHTTPSeries.first?.range ?? nextDownloadSeries.first?.range ?? nextServiceSeries.first?.range ?? range.rawValue,
                bucket: nextPingSeries.first?.bucket ?? nextHTTPSeries.first?.bucket ?? nextDownloadSeries.first?.bucket ?? nextServiceSeries.first?.bucket ?? bucket.rawValue,
                bucketSeconds: nextPingSeries.first?.bucketSeconds ?? nextHTTPSeries.first?.bucketSeconds ?? nextDownloadSeries.first?.bucketSeconds ?? nextServiceSeries.first?.bucketSeconds,
                maxPoints: nextPingSeries.first?.maxPoints ?? nextHTTPSeries.first?.maxPoints ?? nextDownloadSeries.first?.maxPoints ?? nextServiceSeries.first?.maxPoints ?? maxPoints
            )
            lastUpdated = Date()
        }

        return errors
    }

    private func runAutoRefresh() async {
        await refresh()

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: refreshInterval)
            } catch {
                return
            }

            await refresh()
        }
    }

    private var pingNamesForFallback: [String] {
        let names = catalog?.ping.map(\.name) ?? []
        return names.isEmpty ? legacyFallbackPingNames : names
    }

    private var httpNamesForFallback: [String] {
        let names = catalog?.http.map(\.name) ?? []
        return names.isEmpty ? legacyFallbackHTTPNames : names
    }

    private var serviceGroupsForFallback: [String] {
        let groups = catalog?.serviceGroups.map(\.group) ?? []
        return groups.isEmpty ? legacyFallbackServiceGroups : groups
    }

    private var downloadNamesForFallback: [String] {
        catalog?.download.map(\.name) ?? []
    }

    private func clampedMaxPoints(_ value: Int) -> Int {
        let limits = catalog?.supported?.maxPoints ?? capabilities?.chart?.maxPoints
        return limits?.clamped(value) ?? value
    }

    private func chartRanges(from values: [String]?, fallback: [ChartRange]) -> [ChartRange] {
        guard let values, !values.isEmpty else {
            return fallback
        }

        return values.map(ChartRange.init(rawValue:))
    }

    private func chartBuckets(from values: [String]?, fallback: [ChartBucket]) -> [ChartBucket] {
        guard let values, !values.isEmpty else {
            return fallback
        }

        return values.map(ChartBucket.init(rawValue:))
    }
}

struct ChartsMetadata {
    let generatedAt: Date?
    let actualRangeStart: Date?
    let actualRangeEnd: Date?
    let timezone: String?
    let range: String?
    let bucket: String?
    let bucketSeconds: Int?
    let maxPoints: Int?

    init(
        generatedAt: Date?,
        actualRangeStart: Date?,
        actualRangeEnd: Date?,
        timezone: String?,
        range: String?,
        bucket: String?,
        bucketSeconds: Int?,
        maxPoints: Int?
    ) {
        self.generatedAt = generatedAt
        self.actualRangeStart = actualRangeStart
        self.actualRangeEnd = actualRangeEnd
        self.timezone = timezone
        self.range = range
        self.bucket = bucket
        self.bucketSeconds = bucketSeconds
        self.maxPoints = maxPoints
    }

    init(overview: ChartsOverviewResponse) {
        generatedAt = overview.generatedAt
        actualRangeStart = overview.actualRangeStart
        actualRangeEnd = overview.actualRangeEnd
        timezone = overview.timezone
        range = overview.range
        bucket = overview.bucket
        bucketSeconds = overview.bucketSeconds
        maxPoints = overview.maxPoints
    }
}
