//
//  DownloadSample.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct DownloadLatestResponse: Decodable {
    let samples: [DownloadSample]

    enum CodingKeys: String, CodingKey {
        case samples
        case download
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        samples = try container.decodeIfPresent([DownloadSample].self, forKey: .samples)
            ?? container.decodeIfPresent([DownloadSample].self, forKey: .download)
            ?? []
    }
}

struct DownloadSample: Codable, Identifiable {
    var id: String { name }

    let ts: Date
    let type: String?
    let name: String
    let ok: Bool
    let url: String?
    let httpStatus: Int?
    let expectedBytes: Int?
    let downloadedBytes: Int?
    let durationMs: Double?
    let bytesPerSec: Double?
    let mbps: Double?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ts
        case type
        case name
        case ok
        case url
        case httpStatus
        case expectedBytes
        case downloadedBytes
        case durationMs
        case bytesPerSec
        case mbps
        case error
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tsString = try container.decode(String.self, forKey: .ts)

        guard let parsedTS = ChartDateParser.parse(tsString) else {
            throw DecodingError.dataCorruptedError(forKey: .ts, in: container, debugDescription: "Invalid download sample timestamp.")
        }

        ts = parsedTS
        type = try container.decodeIfPresent(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        ok = try container.decodeIfPresent(Bool.self, forKey: .ok) ?? false
        url = try container.decodeIfPresent(String.self, forKey: .url)
        httpStatus = try container.decodeIfPresent(Int.self, forKey: .httpStatus)
        expectedBytes = try container.decodeIfPresent(Int.self, forKey: .expectedBytes)
        downloadedBytes = try container.decodeIfPresent(Int.self, forKey: .downloadedBytes)
        durationMs = try container.decodeIfPresent(Double.self, forKey: .durationMs)
        bytesPerSec = try container.decodeIfPresent(Double.self, forKey: .bytesPerSec)
        mbps = try container.decodeIfPresent(Double.self, forKey: .mbps)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ts, forKey: .ts)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(ok, forKey: .ok)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(httpStatus, forKey: .httpStatus)
        try container.encodeIfPresent(expectedBytes, forKey: .expectedBytes)
        try container.encodeIfPresent(downloadedBytes, forKey: .downloadedBytes)
        try container.encodeIfPresent(durationMs, forKey: .durationMs)
        try container.encodeIfPresent(bytesPerSec, forKey: .bytesPerSec)
        try container.encodeIfPresent(mbps, forKey: .mbps)
        try container.encodeIfPresent(error, forKey: .error)
    }
}
