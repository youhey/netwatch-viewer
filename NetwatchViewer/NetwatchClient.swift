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
        let url = baseURL.appending(path: "/api/monitoring/status")
        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetwatchClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetwatchClientError.httpStatus(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(MonitoringStatus.self, from: data)
    }

    func fetchLatest() async throws -> LatestResponse {
        let url = baseURL.appending(path: "/api/latest")
        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetwatchClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetwatchClientError.httpStatus(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(LatestResponse.self, from: data)
    }
}

enum NetwatchClientError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "API のレスポンス形式が不正です。"
        case .httpStatus(let statusCode):
            "API が HTTP \(statusCode) を返しました。"
        }
    }
}
