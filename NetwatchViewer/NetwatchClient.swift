//
//  NetwatchClient.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct NetwatchClient {
    private let baseURL = URL(string: "http://netpi:8080")!
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func fetchMonitoringStatus() async throws -> MonitoringStatus {
        try await fetch(path: "/api/monitoring/status")
    }

    func fetchLatest() async throws -> LatestResponse {
        try await fetch(path: "/api/latest")
    }

    func fetchCapabilities() async throws -> APICapabilities {
        try await fetch(path: "/api/capabilities")
    }

    func fetchChartCatalog() async throws -> ChartCatalog {
        try await fetch(path: "/api/charts/catalog")
    }

    func fetchChartsOverview(range: ChartRange, bucket: ChartBucket, maxPoints: Int) async throws -> ChartsOverviewResponse {
        try await fetch(
            path: "/api/charts/overview",
            queryItems: [
                URLQueryItem(name: "range", value: range.rawValue),
                URLQueryItem(name: "bucket", value: bucket.rawValue),
                URLQueryItem(name: "max_points", value: String(maxPoints))
            ]
        )
    }

    func fetchMonitoringThresholds() async throws -> MonitoringThresholds {
        try await fetch(path: "/api/monitoring/thresholds")
    }

    func fetchMonitoringStatusHistory(range: String = "24h", bucket: String = "1h") async throws -> MonitoringStatusHistoryResponse {
        try await fetch(
            path: "/api/monitoring/status/history",
            queryItems: [
                URLQueryItem(name: "range", value: range),
                URLQueryItem(name: "bucket", value: bucket)
            ]
        )
    }

    func fetchDownloadLatest() async throws -> DownloadLatestResponse {
        try await fetch(path: "/api/download/latest")
    }

    func fetchPingSeries(name: String, range: ChartRange, bucket: ChartBucket, maxPoints: Int = 500) async throws -> PingChartSeries {
        try await fetch(
            path: "/api/ping/series",
            queryItems: [
                URLQueryItem(name: "name", value: name),
                URLQueryItem(name: "range", value: range.rawValue),
                URLQueryItem(name: "bucket", value: bucket.rawValue),
                URLQueryItem(name: "max_points", value: String(maxPoints))
            ]
        )
    }

    func fetchHTTPSeries(name: String, range: ChartRange, bucket: ChartBucket, maxPoints: Int = 500) async throws -> HTTPChartSeries {
        try await fetch(
            path: "/api/http/series",
            queryItems: [
                URLQueryItem(name: "name", value: name),
                URLQueryItem(name: "range", value: range.rawValue),
                URLQueryItem(name: "bucket", value: bucket.rawValue),
                URLQueryItem(name: "max_points", value: String(maxPoints))
            ]
        )
    }

    func fetchServiceSeries(group: String, range: ChartRange, bucket: ChartBucket, maxPoints: Int = 500) async throws -> ServiceChartSeries {
        try await fetch(
            path: "/api/services/series",
            queryItems: [
                URLQueryItem(name: "group", value: group),
                URLQueryItem(name: "range", value: range.rawValue),
                URLQueryItem(name: "bucket", value: bucket.rawValue),
                URLQueryItem(name: "max_points", value: String(maxPoints))
            ]
        )
    }

    func fetchDownloadSeries(name: String, range: ChartRange, bucket: ChartBucket, maxPoints: Int = 500) async throws -> DownloadChartSeries {
        try await fetch(
            path: "/api/download/series",
            queryItems: [
                URLQueryItem(name: "name", value: name),
                URLQueryItem(name: "range", value: range.rawValue),
                URLQueryItem(name: "bucket", value: bucket.rawValue),
                URLQueryItem(name: "max_points", value: String(maxPoints))
            ]
        )
    }

    private func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw NetwatchClientError.invalidURL
        }

        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetwatchClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let decoder = makeJSONDecoder()

            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw NetwatchClientError.apiError(statusCode: httpResponse.statusCode, detail: apiError.error)
            }

            throw NetwatchClientError.httpStatus(httpResponse.statusCode)
        }

        return try makeJSONDecoder().decode(T.self, from: data)
    }

    private func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

enum NetwatchClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case apiError(statusCode: Int, detail: APIErrorDetail)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "API URL を組み立てられませんでした。"
        case .invalidResponse:
            "API のレスポンス形式が不正です。"
        case .httpStatus(let statusCode):
            "API が HTTP \(statusCode) を返しました。"
        case .apiError(_, let detail):
            detail.message
        }
    }

    var debugDescription: String {
        switch self {
        case .apiError(let statusCode, let detail):
            var parts = ["HTTP \(statusCode)"]

            if let code = detail.code {
                parts.append("code=\(code)")
            }

            if let param = detail.param {
                parts.append("param=\(param)")
            }

            if let min = detail.min {
                parts.append("min=\(min)")
            }

            if let max = detail.max {
                parts.append("max=\(max)")
            }

            return parts.joined(separator: " ")
        default:
            return localizedDescription
        }
    }
}
