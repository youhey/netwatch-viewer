//
//  LatestResponse.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct LatestResponse: Codable {
    let ping: [PingSample]
    let dns: [DNSSample]
    let http: [HTTPSample]
    let download: [DownloadSample]

    init(ping: [PingSample] = [], dns: [DNSSample] = [], http: [HTTPSample] = [], download: [DownloadSample] = []) {
        self.ping = ping
        self.dns = dns
        self.http = http
        self.download = download
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ping = try container.decodeIfPresent([PingSample].self, forKey: .ping) ?? []
        dns = try container.decodeIfPresent([DNSSample].self, forKey: .dns) ?? []
        http = try container.decodeIfPresent([HTTPSample].self, forKey: .http) ?? []
        download = try container.decodeIfPresent([DownloadSample].self, forKey: .download) ?? []
    }
}

struct PingSample: Codable, Identifiable {
    var id: String { name }

    let ts: String
    let type: String
    let name: String
    let displayName: String?
    let displayOrder: Int?
    let ok: Bool
    let target: String?
    let sent: Int?
    let received: Int?
    let lossPercent: Double?
    let rttMinMs: Double?
    let rttAvgMs: Double?
    let rttMaxMs: Double?
}

struct DNSSample: Codable, Identifiable {
    var id: String { name }

    let ts: String
    let type: String
    let name: String
    let displayName: String?
    let displayOrder: Int?
    let ok: Bool
    let hostname: String?
    let durationMs: Double?
    let resolvedIps: [String]?
}

struct HTTPSample: Codable, Identifiable {
    var id: String { name }

    let ts: String
    let type: String
    let name: String
    let displayName: String?
    let displayOrder: Int?
    let group: String?
    let category: String?
    let ok: Bool
    let url: String?
    let method: String?
    let httpStatus: Int?
    let dnsMs: Double?
    let connectMs: Double?
    let tlsMs: Double?
    let ttfbMs: Double?
    let totalMs: Double?
    let remoteAddr: String?
    let contentLength: Int?
    let contentLengthRead: Int?
    let bodyTruncated: Bool?
    let error: String?
    let errorMessage: String?
}
